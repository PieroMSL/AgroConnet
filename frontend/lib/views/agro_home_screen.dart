import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodels/agro_home_viewmodel.dart';
import '../models/agro_producto.dart';
import '../views/agro_producto_detalle_screen.dart';
import '../services/auth_service.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _kG = Color(0xFF2E7D32); // verde vivo
const _kGL = Color(0xFF66BB6A); // verde claro
const _kBg = Color(0xFFF0F2F5); // fondo gris suave
const _kCard = Colors.white;
const _kText = Color(0xFF1A1A1A);
const _kSub = Color(0xFF757575);
const _kOrange = Color(0xFFFF8F00);

class AgroHomeScreen extends StatefulWidget {
  const AgroHomeScreen({super.key});
  @override
  State<AgroHomeScreen> createState() => _AgroHomeScreenState();
}

class _AgroHomeScreenState extends State<AgroHomeScreen> {
  final _searchCtrl = TextEditingController();

  static const _cats = [
    _CatInfo('Verduras', Icons.grass_rounded, Color(0xFF388E3C)),
    _CatInfo('Frutas', Icons.apple_rounded, Color(0xFFE53935)),
    _CatInfo('Lácteos', Icons.opacity_rounded, Color(0xFF1E88E5)),
    _CatInfo('Panadería', Icons.bakery_dining_rounded, Color(0xFFF57C00)),
    _CatInfo('Cereales', Icons.grain_rounded, Color(0xFF8D6E63)),
    _CatInfo('Huevos', Icons.egg_rounded, Color(0xFFFFB300)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AgroHomeViewModel>().cargarDatos(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<AgroHomeViewModel>().cargarDatos(forzar: true);

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Consumer<AgroHomeViewModel>(
          builder: (context, vm, _) {
            final loading = vm.estado == AgroHomeEstado.cargando;
            return RefreshIndicator(
              color: _kG,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _topBar()),
                  SliverToBoxAdapter(child: _searchBar(vm)),
                  SliverToBoxAdapter(
                    child: _sectionTitle('Categorías', top: 22),
                  ),
                  SliverToBoxAdapter(child: _categorias(vm)),
                  SliverToBoxAdapter(child: _sectionTitle('📍 De tu zona')),
                  SliverToBoxAdapter(
                    child: loading ? _shimmerRow() : _localRow(vm),
                  ),
                  SliverToBoxAdapter(child: _sectionTitle('🌾 Nueva Cosecha')),
                  if (loading)
                    _shimmerGrid()
                  else if (vm.productos.isEmpty)
                    _emptyState(vm)
                  else
                    _cosechaGrid(vm),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _topBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
    decoration: const BoxDecoration(
      // ✅ Gradiente moderno Clean UI
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
      ),
      // Bordes curvados solo en la parte inferior
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Buen día! 👋',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
            ),
            Text(
              'AgroConnect',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Menú con cerrar sesión
        PopupMenuButton<String>(
          tooltip: 'Opciones',
          icon: Container(
            width: 44,
            height: 44,
            // ✅ Círculo perfecto semi-transparente
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
          ),
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (v) async {
            if (v == 'logout') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: const Text('Cerrar Sesión'),
                  content: const Text(
                    '¿Seguro que quieres salir de AgroConnect?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kG,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) await AuthService().signOut();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.outfit(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _searchBar(AgroHomeViewModel vm) => Padding(
    // Flota debajo del header con gradiente
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        // ✅ Sombra limpia y pronunciada — sin borde sucio
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: vm.buscar,
        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar productos frescos...',
          hintStyle: GoogleFonts.outfit(color: _kSub),
          prefixIcon: const Icon(Icons.search_rounded, color: _kG),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _kSub),
                  onPressed: () {
                    _searchCtrl.clear();
                    vm.buscar('');
                  },
                )
              : null,
          // ✅ Sin borde ni filled — el Container hace el trabajo
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    ),
  );

  // ── Sección título ────────────────────────────────────────────────────────

  Widget _sectionTitle(String t, {double top = 14}) => Padding(
    padding: EdgeInsets.fromLTRB(20, top, 20, 12),
    child: Text(
      t,
      style: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _kText,
      ),
    ),
  );

  // ── Categorías ────────────────────────────────────────────────────────────

  Widget _categorias(AgroHomeViewModel vm) => SizedBox(
    height: 96,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _cats.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, i) {
        final cat = _cats[i];
        // firstOrNull evita excepción si no hay coincidencia
        // Comparación segura, omitiendo mayúsculas y acentos
        final idx = vm.categorias.indexWhere((c) {
          String dbName = c.nombre
              .toLowerCase()
              .replaceAll('á', 'a')
              .replaceAll('é', 'e')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u')
              .trim();
          String uiName = cat.label
              .toLowerCase()
              .replaceAll('á', 'a')
              .replaceAll('é', 'e')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u')
              .trim();
          return dbName.contains(uiName) || uiName.contains(dbName);
        });

        final be = idx >= 0 ? vm.categorias[idx] : null;
        final sel = be != null && vm.categoriaSeleccionada == be.idCategoria;

        return GestureDetector(
          onTap: () {
            if (be != null) {
              vm.filtrarPorCategoria(sel ? null : be.idCategoria);
            }
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? cat.color : cat.color.withOpacity(0.1),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: cat.color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  cat.icon,
                  color: sel ? Colors.white : cat.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _kG : _kSub,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  // ── Fila LOCAL ────────────────────────────────────────────────────────────

  Widget _localRow(AgroHomeViewModel vm) {
    if (vm.estado == AgroHomeEstado.error) return const SizedBox.shrink();
    final list = vm.productos.take(6).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _LocalCard(p: list[i]),
      ),
    );
  }

  // ── Grid Nueva Cosecha ────────────────────────────────────────────────────

  Widget _cosechaGrid(AgroHomeViewModel vm) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _CosechaCard(p: vm.productos[i]),
        childCount: vm.productos.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
    ),
  );

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _shimmerRow() => SizedBox(
    height: 136,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          width: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),
  );

  Widget _shimmerGrid() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        childCount: 6,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
    ),
  );

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState(AgroHomeViewModel vm) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kG.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.agriculture_rounded, size: 50, color: _kGL),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin productos por aquí 🌱',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No encontramos productos para tu búsqueda.\nDesliza hacia abajo para recargar.',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: _kG),
            label: Text(
              'Recargar',
              style: GoogleFonts.outfit(
                color: _kG,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kG),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card LOCAL (fila horizontal)
// ─────────────────────────────────────────────────────────────────────────────

class _LocalCard extends StatelessWidget {
  final AgroProducto p;
  const _LocalCard({required this.p});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgroProductoDetalleScreen(p: p),
        ),
      );
    },
    child: Container(
      width: 210,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Imagen
            SizedBox(
              width: 86,
              height: double.infinity,
              child: p.urlImagen != null
                  ? Image.network(p.urlImagen!, fit: BoxFit.cover)
                  : _Placeholder(titulo: p.titulo, catId: p.idCategoria),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📍 Local',
                        style: GoogleFonts.outfit(
                          color: _kOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      p.titulo,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'S/. ${p.precio.toStringAsFixed(2)}'
                      '${p.unidadMedida != null ? " / ${p.unidadMedida}" : ""}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kG,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card NUEVA COSECHA (grid 2 columnas) — DISEÑO PREMIUM
// ─────────────────────────────────────────────────────────────────────────────

class _CosechaCard extends StatelessWidget {
  final AgroProducto p;
  const _CosechaCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final esOrg = p.descripcion?.toLowerCase().contains('orgánico') ?? false;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgroProductoDetalleScreen(p: p),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen (mitad superior) ──────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: p.urlImagen != null
                          ? Image.network(p.urlImagen!, fit: BoxFit.cover)
                          : _Placeholder(
                              titulo: p.titulo,
                              catId: p.idCategoria,
                            ),
                    ),
                    // Gradiente inferior sobre la imagen
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge orgánico
                    if (esOrg)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kG,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🌱 Orgánico',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Botón añadir
                    Positioned(
                      bottom: 9,
                      right: 9,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kG,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Info (mitad inferior) ────────────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.titulo,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'S/. ${p.precio.toStringAsFixed(2)}'
                        '${p.unidadMedida != null ? " / ${p.unidadMedida}" : ""}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _kG,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder emoji cuando no hay foto
// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final String titulo;
  final int catId;
  const _Placeholder({required this.titulo, required this.catId});

  static const _bgs = [
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
  ];

  static String _emoji(String t) {
    final s = t.toLowerCase();
    if (s.contains('papa') || s.contains('patata')) return '🥔';
    if (s.contains('tomate')) return '🍅';
    if (s.contains('cebolla')) return '🧅';
    if (s.contains('lechuga') || s.contains('espinaca')) return '🥬';
    if (s.contains('zanahoria')) return '🥕';
    if (s.contains('manzana')) return '🍎';
    if (s.contains('naranja') || s.contains('mandarina')) return '🍊';
    if (s.contains('palta') || s.contains('aguacate')) return '🥑';
    if (s.contains('leche')) return '🥛';
    if (s.contains('queso')) return '🧀';
    if (s.contains('maíz') || s.contains('maiz')) return '🌽';
    if (s.contains('pan')) return '🍞';
    if (s.contains('fresa')) return '🍓';
    if (s.contains('mango')) return '🥭';
    return '🥦';
  }

  @override
  Widget build(BuildContext context) => Container(
    color: _bgs[catId % _bgs.length],
    child: Center(
      child: Text(_emoji(titulo), style: const TextStyle(fontSize: 46)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Datos de categorías
// ─────────────────────────────────────────────────────────────────────────────

class _CatInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _CatInfo(this.label, this.icon, this.color);
}
