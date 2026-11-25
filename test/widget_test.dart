import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/formatters.dart';
import 'package:petcare/core/validators.dart';
import 'package:petcare/data/app_data.dart';
import 'package:petcare/data/data_source.dart';

void main() {
  group('Formatação PT-BR', () {
    test('moeda', () {
      expect(formatMoney(89), 'R\$ 89,00');
      expect(formatMoney(1234.5), 'R\$ 1.234,50');
      expect(parseMoney('1.234,50'), 1234.5);
    });

    test('data e hora', () {
      final d = DateTime(2026, 3, 7, 9, 5);
      expect(formatDate(d), '07/03/2026');
      expect(formatTime(d), '09:05');
      expect(parseDate('31/02/2026'), isNull);
    });

    test('validadores', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('invalido'), isNotNull);
      expect(Validators.phone('(86) 99999-0000'), isNull);
      expect(Validators.password('123'), isNotNull);
    });
  });

  group('Fluxo entre perfis', () {
    late AppData data;

    setUp(() async {
      data = AppData(dataSource: MemoryDataSource());
      await data.load();
    });

    tearDown(() => data.dispose());

    test('cliente agenda, equipe executa, cliente avalia', () {
      final cliente = data.findByEmail('cliente@petcare.app')!;
      final pet = data.petsOf(cliente.id).firstWhere((p) => p.nome == 'Bob');
      final banho = data.activeServices.firstWhere((s) => s.nome == 'Banho completo');

      DateTime? slot;
      final today = dateOnly(DateTime.now());
      for (var i = 1; i <= 14 && slot == null; i++) {
        final slots = data.availableSlots(today.add(Duration(days: i)), banho, petId: pet.id);
        if (slots.isNotEmpty) slot = slots.first;
      }
      expect(slot, isNotNull);

      final a = data.book(cliente, petId: pet.id, servicoId: banho.id, inicio: slot!);
      final func = data.userById(a.funcionarioId)!;
      expect(func.especialidade, StaffSpecialty.banhoTosa);

      // Cliente não opera procedimentos.
      expect(() => data.startStep(cliente, a.id, 0), throwsA(isA<PermissionDenied>()));
      // Cliente não cria funcionários.
      expect(
        () => data.createUserByManager(cliente,
            nome: 'X Y', email: 'x@y.com', telefone: '86999990000', senha: '123456', role: UserRole.funcionario),
        throwsA(isA<PermissionDenied>()),
      );

      data.startStep(func, a.id, 0);
      expect(a.status, AppointmentStatus.emAndamento);

      final hidrat = data.activeServices.firstWhere((s) => s.nome.startsWith('Hidratação'));
      data.requestAdditional(func, a.id, hidrat.id, 'Pelos ressecados');
      expect(() => data.finishAppointment(func, a.id), throwsA(isA<BusinessException>()));
      data.respondAdditional(cliente, a.id, a.adicionais.first.id, true);
      expect(a.valorTotal, banho.preco + hidrat.preco);

      data.finishAppointment(func, a.id);
      expect(a.status, AppointmentStatus.concluido);
      final pay = data.paymentFor(a.id)!;
      expect(pay.status, PaymentStatus.pendente);
      expect(pay.valor, a.valorTotal);

      data.declareCounterPayment(cliente, pay.id, PaymentMethod.pix);
      data.confirmPayment(func, pay.id, PaymentMethod.pix);
      expect(pay.status, PaymentStatus.pago);

      data.addReview(cliente, a.id, 5, 'Ótimo');
      expect(data.reviewFor(a.id)!.nota, 5);
      expect(data.notificationsOf(cliente.id), isNotEmpty);
    });

    test('dados persistem e são recarregados', () async {
      final source = MemoryDataSource();
      final d1 = AppData(dataSource: source);
      await d1.load();
      final gerente = d1.findByEmail('gerente@petcare.app')!;
      d1.createUserByManager(gerente,
          nome: 'Nova Pessoa', email: 'nova@petcare.app', telefone: '86999990000', senha: 'abc123',
          role: UserRole.funcionario, especialidade: StaffSpecialty.banhoTosa);
      await d1.persist();
      d1.dispose();

      final d2 = AppData(dataSource: source);
      await d2.load();
      final u = d2.findByEmail('nova@petcare.app');
      expect(u, isNotNull);
      expect(d2.verifyPassword(u!, 'abc123'), isTrue);
      d2.dispose();
    });
  });
}
