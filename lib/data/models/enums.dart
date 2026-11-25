import 'package:flutter/material.dart';

import '../../core/theme.dart';

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

DateTime? parseDt(Object? v) => v == null ? null : DateTime.tryParse(v as String);

enum UserRole { cliente, funcionario, gerente }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.cliente => 'Cliente',
        UserRole.funcionario => 'Funcionário',
        UserRole.gerente => 'Gerente',
      };
}

enum StaffSpecialty { banhoTosa, veterinario, recepcao }

extension StaffSpecialtyX on StaffSpecialty {
  String get label => switch (this) {
        StaffSpecialty.banhoTosa => 'Banho e tosa',
        StaffSpecialty.veterinario => 'Veterinário(a)',
        StaffSpecialty.recepcao => 'Recepção',
      };
}

enum Species { cachorro, gato, outro }

extension SpeciesX on Species {
  String get label => switch (this) {
        Species.cachorro => 'Cachorro',
        Species.gato => 'Gato',
        Species.outro => 'Outro',
      };
}

enum PetSex { macho, femea }

extension PetSexX on PetSex {
  String get label => this == PetSex.macho ? 'Macho' : 'Fêmea';
}

enum PetSize { pequeno, medio, grande }

extension PetSizeX on PetSize {
  String get label => switch (this) {
        PetSize.pequeno => 'Pequeno',
        PetSize.medio => 'Médio',
        PetSize.grande => 'Grande',
      };
}

enum ServiceCategory { banho, tosa, veterinario, outro }

extension ServiceCategoryX on ServiceCategory {
  String get label => switch (this) {
        ServiceCategory.banho => 'Banho',
        ServiceCategory.tosa => 'Tosa',
        ServiceCategory.veterinario => 'Veterinário',
        ServiceCategory.outro => 'Outros',
      };

  IconData get icon => switch (this) {
        ServiceCategory.banho => Icons.bathtub_outlined,
        ServiceCategory.tosa => Icons.content_cut,
        ServiceCategory.veterinario => Icons.medical_services_outlined,
        ServiceCategory.outro => Icons.spa_outlined,
      };

  Color get color => switch (this) {
        ServiceCategory.banho => AppColors.sageLight,
        ServiceCategory.tosa => AppColors.beige,
        ServiceCategory.veterinario => AppColors.lilac,
        ServiceCategory.outro => const Color(0xFFE3ECF0),
      };

  /// Qual especialidade de funcionário atende esta categoria.
  StaffSpecialty get specialty =>
      this == ServiceCategory.veterinario ? StaffSpecialty.veterinario : StaffSpecialty.banhoTosa;
}

enum AppointmentStatus { agendado, emAndamento, concluido, cancelado }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.agendado => 'Agendado',
        AppointmentStatus.emAndamento => 'Em andamento',
        AppointmentStatus.concluido => 'Concluído',
        AppointmentStatus.cancelado => 'Cancelado',
      };

  Color get color => switch (this) {
        AppointmentStatus.agendado => AppColors.info,
        AppointmentStatus.emAndamento => AppColors.sage,
        AppointmentStatus.concluido => AppColors.sageDark,
        AppointmentStatus.cancelado => AppColors.danger,
      };

  bool get isOpen => this == AppointmentStatus.agendado || this == AppointmentStatus.emAndamento;
}

enum StepStatus { pendente, emAndamento, concluido }

enum NoteType { observacao, ocorrencia }

extension NoteTypeX on NoteType {
  String get label => this == NoteType.observacao ? 'Observação' : 'Ocorrência';
}

enum AdditionalStatus { pendente, aprovado, recusado }

extension AdditionalStatusX on AdditionalStatus {
  String get label => switch (this) {
        AdditionalStatus.pendente => 'Aguardando cliente',
        AdditionalStatus.aprovado => 'Aprovado',
        AdditionalStatus.recusado => 'Recusado',
      };
}

enum PaymentMethod { pix, cartaoCredito, cartaoDebito, dinheiro }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.pix => 'Pix',
        PaymentMethod.cartaoCredito => 'Cartão de crédito',
        PaymentMethod.cartaoDebito => 'Cartão de débito',
        PaymentMethod.dinheiro => 'Dinheiro',
      };

  IconData get icon => switch (this) {
        PaymentMethod.pix => Icons.qr_code_2,
        PaymentMethod.cartaoCredito => Icons.credit_card,
        PaymentMethod.cartaoDebito => Icons.credit_card_outlined,
        PaymentMethod.dinheiro => Icons.payments_outlined,
      };
}

enum PaymentStatus { pendente, aguardandoConfirmacao, pago, estornado }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pendente => 'Pendente',
        PaymentStatus.aguardandoConfirmacao => 'Aguardando confirmação',
        PaymentStatus.pago => 'Pago',
        PaymentStatus.estornado => 'Estornado',
      };

  Color get color => switch (this) {
        PaymentStatus.pendente => AppColors.warning,
        PaymentStatus.aguardandoConfirmacao => AppColors.info,
        PaymentStatus.pago => AppColors.sage,
        PaymentStatus.estornado => AppColors.danger,
      };
}

enum PaymentChannel { presencial, online }
