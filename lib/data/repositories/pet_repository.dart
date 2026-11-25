import '../models/models.dart';
import '../store_base.dart';

mixin PetRepository on StoreBase {
  List<Pet> petsOf(String tutorId) =>
      pets.where((p) => p.tutorId == tutorId && p.ativo).toList()..sort((a, b) => a.nome.compareTo(b.nome));

  List<Pet> get activePets => pets.where((p) => p.ativo).toList()..sort((a, b) => a.nome.compareTo(b.nome));

  /// Cria ou atualiza um animal. Tutor edita os próprios; equipe e gerência
  /// podem atualizar dados (ex.: peso, saúde) durante o atendimento.
  void savePet(UserModel actor, Pet pet) {
    ensureActive(actor);
    final existing = petById(pet.id);
    if (existing == null) {
      ensure(actor.isGerente || actor.id == pet.tutorId, 'Você só pode cadastrar os seus próprios pets.');
      final tutor = userById(pet.tutorId);
      if (tutor == null || !tutor.isCliente) throw BusinessException('Tutor inválido.');
      pets.add(pet);
    } else {
      ensure(actor.isStaff || actor.id == existing.tutorId);
      final idx = pets.indexWhere((p) => p.id == pet.id);
      pets[idx] = pet;
      if (actor.isStaff && actor.id != existing.tutorId) {
        pushNotification(existing.tutorId, 'Cadastro de ${pet.nome} atualizado',
            '${actor.nome} atualizou as informações de ${pet.nome}.');
      }
    }
    commit();
  }

  void archivePet(UserModel actor, String petId) {
    final p = petById(petId);
    if (p == null) throw BusinessException('Pet não encontrado.');
    ensure(actor.isGerente || actor.id == p.tutorId);
    final hasOpen = appointments.any((a) => a.petId == petId && a.status.isOpen);
    if (hasOpen) {
      throw BusinessException('Cancele ou conclua os agendamentos abertos de ${p.nome} antes de removê-lo.');
    }
    p.ativo = false;
    commit();
  }
}
