import 'repositories/appointment_repository.dart';
import 'repositories/engagement_repository.dart';
import 'repositories/finance_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/user_repository.dart';
import 'store_base.dart';

export 'models/models.dart';
export 'store_base.dart' show BusinessException, PermissionDenied;

/// Fachada única de dados do app. Cada domínio fica em um repositório
/// (mixin) separado; todos compartilham a mesma base e o mesmo
/// mecanismo de notificação em tempo real.
class AppData extends StoreBase
    with
        UserRepository,
        PetRepository,
        ServiceRepository,
        AppointmentRepository,
        FinanceRepository,
        EngagementRepository {
  AppData({
    required super.dataSource,
    super.paymentGateway,
    super.pushGateway,
    super.emailGateway,
  });
}
