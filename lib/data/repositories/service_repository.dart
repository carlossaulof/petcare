import '../models/models.dart';
import '../store_base.dart';

mixin ServiceRepository on StoreBase {
  List<ServiceModel> get activeServices =>
      services.where((s) => s.ativo).toList()..sort((a, b) => a.categoria.index.compareTo(b.categoria.index));

  void saveService(UserModel actor, ServiceModel service) {
    ensure(actor.isGerente, 'Somente gerentes podem alterar serviços e preços.');
    if (service.etapas.isEmpty) throw BusinessException('Informe ao menos uma etapa do procedimento.');
    final idx = services.indexWhere((s) => s.id == service.id);
    if (idx == -1) {
      services.add(service);
    } else {
      services[idx] = service;
    }
    commit();
  }

  void setServiceActive(UserModel actor, String id, bool ativo) {
    ensure(actor.isGerente);
    final s = serviceById(id);
    if (s == null) throw BusinessException('Serviço não encontrado.');
    s.ativo = ativo;
    commit();
  }

  void updateBusinessHours(UserModel actor, BusinessHours newHours) {
    ensure(actor.isGerente, 'Somente gerentes podem alterar os horários.');
    if (newHours.fechamentoMin <= newHours.aberturaMin) {
      throw BusinessException('O horário de fechamento deve ser depois da abertura.');
    }
    if (newHours.diasFuncionamento.isEmpty) {
      throw BusinessException('Selecione ao menos um dia de funcionamento.');
    }
    hours = newHours;
    commit();
  }
}
