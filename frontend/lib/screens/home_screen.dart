import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_screen.dart';
import 'passager_home_screen.dart';
import 'proprietaire_home_screen.dart';
import 'conducteur_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user?.role == 'admin') return const AdminScreen();
    if (user?.role == 'proprietaire') return const ProprietaireHomeScreen();
    if (user?.role == 'conducteur') return const ConducteurHomeScreen();
    return const PassagerHomeScreen();
  }
}
