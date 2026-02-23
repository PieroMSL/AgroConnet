import 'package:flutter/material.dart';
import 'agro_home_screen.dart';
import 'agro_subir_screen.dart';
import 'chat_screen.dart';

/// Pantalla principal de navegación de AgroConnect.
///
/// Contiene un BottomNavigationBar con 3 tabs:
///   0 → Inicio (mercado de productos)
///   1 → Publicar (formulario del productor)
///   2 → Chat IA (asistente agrícola existente)
class AgroMainScreen extends StatefulWidget {
  const AgroMainScreen({super.key});

  @override
  State<AgroMainScreen> createState() => _AgroMainScreenState();
}

class _AgroMainScreenState extends State<AgroMainScreen> {
  int _tabActual = 0;

  // IndexedStack mantiene el estado de cada tab al cambiar de pantalla
  final List<Widget> _pantallas = const [
    AgroHomeScreen(),
    AgroSubirScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserva el scroll y el estado de cada tab
      body: IndexedStack(index: _tabActual, children: _pantallas),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (index) {
          setState(() => _tabActual = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF2E7D32),
            ),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box_outlined),
            selectedIcon: const Icon(
              Icons.add_box_rounded,
              color: Color(0xFF2E7D32),
            ),
            label: 'Publicar',
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF2E7D32),
            ),
            label: 'Chat IA',
          ),
        ],
      ),
    );
  }
}
