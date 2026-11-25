import '../data/models/models.dart';

/// ---------------------------------------------------------------------------
/// Pontos de integração externa.
///
/// Nenhuma integração externa é simulada como real. As implementações abaixo
/// declaram explicitamente `isConfigured == false` e a interface mostra isso
/// ao usuário. Para ativar, implemente as classes conforme o README
/// (seção "Integrações") e troque a injeção em `main.dart`.
/// ---------------------------------------------------------------------------

class IntegrationNotConfigured implements Exception {
  final String message;
  IntegrationNotConfigured(this.message);
  @override
  String toString() => message;
}

// ---------------------------- Pagamentos ------------------------------------

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  const PaymentResult({required this.success, this.transactionId, this.message});
}

abstract class PaymentGateway {
  String get providerName;
  bool get isConfigured;

  /// Cobra o valor de [payment] pelo provedor (Pix, cartão).
  /// Deve retornar o id da transação para conciliação.
  Future<PaymentResult> charge({required Payment payment, required PaymentMethod method});
}

/// Gateway não configurado: pagamentos online ficam indisponíveis e o app
/// trabalha com pagamento presencial confirmado pela equipe.
class UnconfiguredPaymentGateway implements PaymentGateway {
  const UnconfiguredPaymentGateway();

  @override
  String get providerName => 'Nenhum provedor configurado';

  @override
  bool get isConfigured => false;

  @override
  Future<PaymentResult> charge({required Payment payment, required PaymentMethod method}) {
    throw IntegrationNotConfigured(
      'Pagamento online indisponível: nenhum provedor (ex.: Mercado Pago, Stripe, '
      'PagSeguro) foi configurado. Use o pagamento presencial no balcão.',
    );
  }
}

// ----------------------- Notificações push ----------------------------------

abstract class PushGateway {
  String get providerName;
  bool get isConfigured;

  /// Envia a notificação para os dispositivos do usuário destinatário.
  Future<void> send(AppNotification notification);
}

/// Sem push configurado: as notificações ficam apenas dentro do app
/// (aba Avisos), atualizadas em tempo real.
class InAppOnlyPushGateway implements PushGateway {
  const InAppOnlyPushGateway();

  @override
  String get providerName => 'Somente no app';

  @override
  bool get isConfigured => false;

  @override
  Future<void> send(AppNotification notification) async {}
}

// --------------------------- E-mail -----------------------------------------

abstract class EmailGateway {
  bool get isConfigured;
  Future<void> sendPasswordReset({required String email, required String code});
}

/// Sem servidor de e-mail: o código de recuperação é exibido na tela,
/// com aviso explícito de que isso só acontece no modo local.
class UnconfiguredEmailGateway implements EmailGateway {
  const UnconfiguredEmailGateway();

  @override
  bool get isConfigured => false;

  @override
  Future<void> sendPasswordReset({required String email, required String code}) {
    throw IntegrationNotConfigured('Servidor de e-mail não configurado.');
  }
}
