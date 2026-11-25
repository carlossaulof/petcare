import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../state/auth_controller.dart';
import '../client/client_appointment_screen.dart';
import '../staff/staff_appointment_screen.dart';

/// Abre o detalhe do atendimento adequado ao perfil logado.
void openAppointment(BuildContext context, String appointmentId) {
  final user = context.read<AuthController>().currentUser;
  final data = context.read<AppData>();
  if (user == null || data.appointmentById(appointmentId) == null) return;
  final Widget screen = user.isCliente
      ? ClientAppointmentScreen(appointmentId: appointmentId)
      : StaffAppointmentScreen(appointmentId: appointmentId);
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
