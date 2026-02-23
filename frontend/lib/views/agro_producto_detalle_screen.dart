import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agro_producto.dart';

// ── Paleta (idéntica a Home) ──────────────────────────────────────────────────
const _kG = Color(0xFF2E7D32); // Verde vivo
const _kGL = Color(0xFF66BB6A); // Verde claro / Badge
const _kBg = Color(0xFFF9FAFB); // Fondo ultraclaro
const _kText = Color(0xFF1A1A1A);
const _kSub = Color(0xFF757575);

class AgroProductoDetalleScreen extends StatelessWidget {
  final AgroProducto p;

  const AgroProductoDetalleScreen({super.key, required this.p});

  void _abrirWhatsApp(BuildContext context) async {
    // Si tuviéramos el teléfono real del productor lo usaríamos.
    // Por mockup, se enviará a un contacto genérico o de prueba
    final numero = "51999999999";
    final mensaje =
        "Hola, vi tu producto '${p.titulo}' en AgroConnect y me gustaría comprarlo. ¿Sigue disponible?";
    final url = Uri.parse(
      "whatsapp://send?phone=$numero&text=${Uri.encodeComponent(mensaje)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir WhatsApp. ¿La app está instalada?'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final esOrg = p.descripcion?.toLowerCase().contains('orgánico') ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── 1. Imagen cabecera de fondo ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: p.urlImagen != null
                ? Image.network(p.urlImagen!, fit: BoxFit.cover)
                : Container(color: _kGL.withOpacity(0.3)), // Placeholder visual
          ),

          // Gradiente oscuro arriba para proteger el botón Back
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── 2. Contenido scrolleable (Hoja blanca solapada) ─────────────────
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: size.height * 0.38)),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título y Precio
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.titulo,
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _kText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'S/ ${p.precio.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _kG,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subinfo y Unidad
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: _kSub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.unidadMedida != null
                                  ? 'Unidad: ${p.unidadMedida}'
                                  : 'Stock: ${p.stock ?? "Consultar"}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: _kSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Badges: Orgánico, Local
                        Row(
                          children: [
                            if (esOrg) ...[
                              _Badge(texto: '🌱 Orgánico', color: _kG),
                              const SizedBox(width: 8),
                            ],
                            _Badge(
                              texto: '📍 Local',
                              color: Colors.orange.shade800,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Descripción
                        Text(
                          'Descripción',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.descripcion ??
                              'Este productor no ha incluido una descripción todavía.',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Botón de WhatsApp
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF25D366,
                              ), // Color WhatsApp
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.chat_rounded, size: 24),
                            onPressed: () => _abrirWhatsApp(context),
                            label: Text(
                              'Contactar al Vendedor',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        // Extra padding inferior para scroll
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 50,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Botones Flotantes Superiores (Back, Fav) ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: _CircButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 15,
            child: _CircButton(
              icon: Icons.favorite_border_rounded,
              onTap: () {
                // Funcionalidad de Favoritos (Mockup)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('¡Añadido a favoritos! 💚'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CircButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
