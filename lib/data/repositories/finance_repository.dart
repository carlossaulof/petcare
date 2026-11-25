import '../../core/formatters.dart';
import '../../services/integrations.dart';
import '../models/models.dart';
import '../store_base.dart';

mixin FinanceRepository on StoreBase {
  Payment? paymentFor(String agendamentoId) {
    Payment? found;
    for (final p in payments) {
      if (p.agendamentoId == agendamentoId) {
        if (found == null || p.status != PaymentStatus.estornado) found = p;
      }
    }
    return found;
  }

  List<Payment> paymentsOfClient(String clienteId) =>
      payments.where((p) => p.clienteId == clienteId).toList()..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

  List<Payment> get allPaymentsSorted => payments.toList()..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

  Payment _requirePayment(String id) {
    for (final p in payments) {
      if (p.id == id) return p;
    }
    throw BusinessException('Pagamento não encontrado.');
  }

  /// Pagamento online pelo gateway configurado (Pix/cartão).
  Future<void> payOnline(UserModel actor, String paymentId, PaymentMethod method) async {
    final p = _requirePayment(paymentId);
    ensure(actor.id == p.clienteId);
    if (p.status == PaymentStatus.pago) throw BusinessException('Este pagamento já foi realizado.');
    if (!paymentGateway.isConfigured) {
      throw IntegrationNotConfigured('Pagamento online ainda não está disponível neste petshop. '
          'Escolha "Pagar no balcão".');
    }
    final result = await paymentGateway.charge(payment: p, method: method);
    if (!result.success) throw BusinessException(result.message ?? 'Pagamento recusado.');
    p.metodo = method;
    p.canal = PaymentChannel.online;
    p.status = PaymentStatus.pago;
    p.pagoEm = DateTime.now();
    p.referenciaExterna = result.transactionId;
    pushNotification(p.clienteId, 'Pagamento aprovado', '${formatMoney(p.valor)} via ${method.label}.',
        agendamentoId: p.agendamentoId);
    notifyManagers('Pagamento recebido', '${formatMoney(p.valor)} via ${method.label} (online).',
        agendamentoId: p.agendamentoId);
    commit();
  }

  /// Cliente informa que vai pagar (ou pagou) no balcão com o método escolhido.
  /// A equipe confirma o recebimento.
  void declareCounterPayment(UserModel actor, String paymentId, PaymentMethod method) {
    final p = _requirePayment(paymentId);
    ensure(actor.id == p.clienteId || actor.isStaff);
    if (p.status == PaymentStatus.pago) throw BusinessException('Este pagamento já foi confirmado.');
    p.metodo = method;
    p.canal = PaymentChannel.presencial;
    p.status = PaymentStatus.aguardandoConfirmacao;
    final cliente = userById(p.clienteId)?.nome ?? 'Cliente';
    notifyManagers('Pagamento a confirmar', '$cliente vai pagar ${formatMoney(p.valor)} via ${method.label} no balcão.',
        agendamentoId: p.agendamentoId);
    final a = appointmentById(p.agendamentoId);
    if (a?.funcionarioId != null) {
      pushNotification(a!.funcionarioId!, 'Pagamento a confirmar',
          '$cliente vai pagar ${formatMoney(p.valor)} via ${method.label}.', agendamentoId: p.agendamentoId);
    }
    commit();
  }

  void confirmPayment(UserModel actor, String paymentId, PaymentMethod method) {
    ensure(actor.isStaff, 'Somente a equipe confirma recebimentos.');
    final p = _requirePayment(paymentId);
    if (p.status == PaymentStatus.pago) throw BusinessException('Pagamento já confirmado.');
    if (p.status == PaymentStatus.estornado) throw BusinessException('Pagamento estornado.');
    p.metodo = method;
    p.status = PaymentStatus.pago;
    p.pagoEm = DateTime.now();
    p.confirmadoPorId = actor.id;
    pushNotification(p.clienteId, 'Pagamento confirmado',
        'Recebemos ${formatMoney(p.valor)} via ${method.label}. Obrigado!', agendamentoId: p.agendamentoId);
    commit();
  }

  void refundPayment(UserModel actor, String paymentId) {
    ensure(actor.isGerente, 'Somente o gerente pode estornar.');
    final p = _requirePayment(paymentId);
    if (p.status != PaymentStatus.pago) throw BusinessException('Só pagamentos confirmados podem ser estornados.');
    if (p.canal == PaymentChannel.online && paymentGateway.isConfigured) {
      throw BusinessException('Estorno online deve ser feito pelo painel do provedor de pagamento.');
    }
    p.status = PaymentStatus.estornado;
    pushNotification(p.clienteId, 'Pagamento estornado', 'O valor de ${formatMoney(p.valor)} foi estornado.',
        agendamentoId: p.agendamentoId);
    commit();
  }

  // ----------------------------------------------------------- indicadores

  double revenueBetween(DateTime start, DateTime end) => payments
      .where((p) => p.status == PaymentStatus.pago && p.pagoEm != null &&
          !p.pagoEm!.isBefore(start) && p.pagoEm!.isBefore(end))
      .fold<double>(0, (s, p) => s + p.valor);

  double get pendingAmount => payments
      .where((p) => p.status == PaymentStatus.pendente || p.status == PaymentStatus.aguardandoConfirmacao)
      .fold<double>(0, (s, p) => s + p.valor);

  /// Faturamento por dia dos últimos [days] dias (inclui hoje).
  List<MapEntry<DateTime, double>> revenueByDay(int days) {
    final today = dateOnly(DateTime.now());
    return List.generate(days, (i) {
      final d = today.subtract(Duration(days: days - 1 - i));
      return MapEntry(d, revenueBetween(d, d.add(const Duration(days: 1))));
    });
  }

  Map<PaymentMethod, double> revenueByMethod(DateTime start, DateTime end) {
    final map = <PaymentMethod, double>{};
    for (final p in payments) {
      if (p.status != PaymentStatus.pago || p.pagoEm == null || p.metodo == null) continue;
      if (p.pagoEm!.isBefore(start) || !p.pagoEm!.isBefore(end)) continue;
      map[p.metodo!] = (map[p.metodo!] ?? 0) + p.valor;
    }
    return map;
  }
}
