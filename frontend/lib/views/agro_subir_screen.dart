import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import '../viewmodels/agro_subir_viewmodel.dart';

// ── Paleta corporativa ────────────────────────────────────────────────────────
const _verde = Color(0xFF1B5E20);
const _verdeVivo = Color(0xFF2E7D32);
const _verdeClaro = Color(0xFF66BB6A);
const _bg = Color(0xFFF4F7F4); // Fondo muy suave verdoso

// ── Estilos reutilizables ─────────────────────────────────────────────────────
final _labelStyle = GoogleFonts.outfit(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: const Color(0xFF424242),
  letterSpacing: 0.3,
);

const _inputTextStyle = TextStyle(
  color: Colors.black87,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

const _dropdownTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

InputDecoration _inputDeco({required String hint, required IconData icon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: _verdeVivo, size: 21),
      filled: true,
      fillColor: Colors.white,
      // Sin borde visible — la sombra del Container hace el trabajo
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _verdeClaro, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );

BoxDecoration _floatDecor() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.grey.shade200),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────

class AgroSubirScreen extends StatefulWidget {
  const AgroSubirScreen({super.key});
  @override
  State<AgroSubirScreen> createState() => _AgroSubirScreenState();
}

class _AgroSubirScreenState extends State<AgroSubirScreen> {
  final _tituloCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _foto;
  bool _gpsLoading = false;
  String? _coords;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AgroSubirViewModel>().cargarCategorias(),
    );
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Cámara / Galería ──────────────────────────────────────────────────────

  Future<void> _tomarFoto() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 600,
    );
    if (f != null) setState(() => _foto = f);
  }

  Future<void> _abrirGaleria() async {
    final f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 600,
    );
    if (f != null) setState(() => _foto = f);
  }

  void _sheetFoto() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            _OptionTile(
              Icons.camera_alt_rounded,
              'Tomar foto con cámara',
              _verdeVivo,
              () {
                Navigator.pop(ctx);
                _tomarFoto();
              },
            ),
            _OptionTile(
              Icons.photo_library_rounded,
              'Elegir de galería',
              _verdeVivo,
              () {
                Navigator.pop(ctx);
                _abrirGaleria();
              },
            ),
            if (_foto != null)
              _OptionTile(
                Icons.delete_rounded,
                'Eliminar foto',
                Colors.red.shade600,
                () {
                  Navigator.pop(ctx);
                  setState(() => _foto = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  // ── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _gps() async {
    setState(() => _gpsLoading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snack('Permiso de ubicación denegado.', error: true);
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Activa el GPS en ajustes del sistema.', error: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      _coords =
          'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';

      final base = _descCtrl.text
          .trim()
          .replaceAll(RegExp(r'\n📍.*'), '')
          .trimRight();
      _descCtrl.text =
          '${base.isNotEmpty ? '$base\n' : ''}📍 Ubicación: $_coords';
      _descCtrl.selection = TextSelection.collapsed(
        offset: _descCtrl.text.length,
      );

      setState(() {});
      _snack('📍 $_coords');
    } catch (_) {
      _snack('No se pudo obtener la ubicación.', error: true);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: error ? Colors.red.shade700 : _verdeVivo,
        behavior: SnackBarBehavior
            .fixed, // ✅ Previene el error de "Floating SnackBar presented off screen"
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<AgroSubirViewModel>(
                builder: (ctx, vm, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _feedback(ctx, vm);
                  });
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    child: Form(
                      key: vm.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // FOTO
                          _sectionLabel('FOTOGRAFÍA DEL PRODUCTO'),
                          const SizedBox(height: 10),
                          _buildFoto(),
                          const SizedBox(height: 14),

                          // GPS
                          _buildGps(),
                          const SizedBox(height: 28),

                          // NOMBRE
                          _sectionLabel('Nombre del Producto'),
                          const SizedBox(height: 8),
                          _buildField(
                            ctrl: _tituloCtrl,
                            hint: 'Ej: Papas nativas de Junín',
                            icon: Icons.shopping_basket_outlined,
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Mínimo 3 caracteres'
                                : null,
                            onSaved: (v) => vm.titulo = v ?? '',
                          ),
                          const SizedBox(height: 18),

                          // CATEGORÍA
                          _sectionLabel('Categoría'),
                          const SizedBox(height: 8),
                          _buildCategoria(vm),
                          const SizedBox(height: 18),

                          // PRECIO + STOCK + UNIDAD
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Precio (S/.)'),
                                    const SizedBox(height: 8),
                                    _buildField(
                                      ctrl: _precioCtrl,
                                      hint: '0.00',
                                      icon: Icons.sell_outlined,
                                      keyboard:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Requerido';
                                        final n = double.tryParse(
                                          v.replaceAll(',', '.'),
                                        );
                                        if (n == null || n <= 0)
                                          return 'Monto inválido';
                                        return null;
                                      },
                                      onSaved: (v) => vm.precioTexto = v ?? '0',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Stock'),
                                    const SizedBox(height: 8),
                                    _buildField(
                                      ctrl: _stockCtrl,
                                      hint: 'Cant.',
                                      icon: Icons.inventory_2_outlined,
                                      keyboard: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Requerido';
                                        final n = int.tryParse(v.trim());
                                        if (n == null || n < 0)
                                          return 'Inválido';
                                        return null;
                                      },
                                      onSaved: (v) => vm.stockTexto = v ?? '',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Unidad'),
                                    const SizedBox(height: 8),
                                    _buildUnidad(vm),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // DESCRIPCIÓN
                          _sectionLabel('Descripción / Origen'),
                          const SizedBox(height: 8),
                          _buildField(
                            ctrl: _descCtrl,
                            hint: 'Orgánico, sin pesticidas, cosechado en...',
                            icon: Icons.notes_rounded,
                            maxLines: 4,
                            onSaved: (v) => vm.descripcion = v ?? '',
                          ),
                          const SizedBox(height: 36),

                          // BOTÓN PUBLICAR
                          _buildPublicar(vm),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Componentes UI ────────────────────────────────────────────────────────

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    decoration: BoxDecoration(
      color: _verde,
      boxShadow: [
        BoxShadow(
          color: _verde.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subir Producto',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Publica tu cosecha al mercado justo',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sectionLabel(String t) => Text(t, style: _labelStyle);

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) => Container(
    decoration: _floatDecor(),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      onSaved: onSaved,
      style: _inputTextStyle,
      decoration: _inputDeco(hint: hint, icon: icon),
    ),
  );

  // ── Foto ──────────────────────────────────────────────────────────────────

  Widget _buildFoto() {
    if (_foto != null) return _fotoPreview();
    return GestureDetector(
      onTap: _sheetFoto,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _verdeClaro.withOpacity(0.6),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: _verdeVivo,
                size: 34,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Toca para agregar una foto',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cámara o galería • JPG / PNG',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPreview() => Container(
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          // ✅ FIX DEFINITIVO: kIsWeb compatible
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: kIsWeb
                ? Image.network(_foto!.path, fit: BoxFit.cover)
                : Image.file(File(_foto!.path), fit: BoxFit.cover),
          ),
        ),
        // Overlay oscuro degradado abajo
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
              ),
            ),
          ),
        ),
        // Botón editar
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _sheetFoto,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        // Badge
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _verdeVivo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✅ Foto lista',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── GPS ───────────────────────────────────────────────────────────────────

  Widget _buildGps() => Container(
    decoration: BoxDecoration(
      color: _coords != null ? const Color(0xFFE8F5E9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: _coords != null
            ? _verdeClaro.withOpacity(0.5)
            : Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _gpsLoading ? null : _gps,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _verdeVivo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _gpsLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _verdeVivo,
                        ),
                      )
                    : Icon(
                        _coords != null
                            ? Icons.gps_fixed_rounded
                            : Icons.location_on_outlined,
                        color: _verdeVivo,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _coords != null
                          ? 'Ubicación obtenida'
                          : 'Obtener ubicación GPS',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: _verdeVivo,
                        fontSize: 14,
                      ),
                    ),
                    if (_coords != null)
                      Text(
                        _coords!,
                        style: GoogleFonts.outfit(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                _coords != null
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: _coords != null ? _verdeVivo : Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ── Dropdown Categoría ────────────────────────────────────────────────────

  Widget _buildCategoria(AgroSubirViewModel vm) {
    if (vm.estado == AgroSubirEstado.cargandoCategorias) {
      return Container(
        height: 56,
        decoration: _floatDecor(),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _verdeVivo),
          ),
        ),
      );
    }
    return Container(
      decoration: _floatDecor(),
      child: DropdownButtonFormField<int>(
        value: vm.idCategoriaSeleccionada,
        style: _dropdownTextStyle, // ✅ negro forzado
        dropdownColor: Colors.white,
        isExpanded: true,
        hint: Text(
          'Selecciona una categoría',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.category_outlined,
            color: _verdeVivo,
            size: 21,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _verdeClaro, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 4,
          ),
        ),
        items: vm.categorias
            .map<DropdownMenuItem<int>>(
              (c) => DropdownMenuItem<int>(
                value: c.idCategoria,
                child: Text(
                  c.nombre,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => vm.idCategoriaSeleccionada = v,
        validator: (_) => vm.idCategoriaSeleccionada == null
            ? 'Selecciona una categoría'
            : null,
      ),
    );
  }

  // ── Dropdown Unidad ───────────────────────────────────────────────────────

  Widget _buildUnidad(AgroSubirViewModel vm) {
    const unidades = ['kg', 'unidad', 'litros', 'docena', 'caja', 'arroba'];
    return Container(
      decoration: _floatDecor(),
      child: DropdownButtonFormField<String>(
        value: vm.unidadMedida,
        style: _dropdownTextStyle, // ✅ negro forzado
        dropdownColor: Colors.white,
        isExpanded: true,
        hint: Text(
          'Unidad',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _verdeClaro, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          isDense: true,
        ),
        items: unidades
            .map(
              (u) => DropdownMenuItem(
                value: u,
                child: Text(
                  u,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => vm.unidadMedida = v,
        validator: (v) => v == null ? 'Requerido' : null,
      ),
    );
  }

  // ── Botón Publicar ────────────────────────────────────────────────────────

  Widget _buildPublicar(AgroSubirViewModel vm) {
    final enviando = vm.estado == AgroSubirEstado.enviando;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enviando
            ? []
            : [
                BoxShadow(
                  color: _verdeVivo.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enviando
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: enviando ? Colors.grey.shade400 : null,
        ),
        child: ElevatedButton(
          onPressed: enviando
              ? null
              : () async {
                  if (_foto == null) {
                    _snack(
                      'Selecciona una fotografía para tu producto',
                      error: true,
                    );
                    return;
                  }

                  // Convertir imagen a Base64 (compatible con Web y Mobile) para guardarla en DB
                  try {
                    final bytes = await _foto!.readAsBytes();
                    final base64String =
                        'data:image/jpeg;base64,${base64Encode(bytes)}';
                    vm.subirProducto(base64Image: base64String);
                  } catch (e) {
                    _snack('Error al procesar la imagen.', error: true);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // ✅ Gradiente toma control
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            minimumSize: const Size(double.infinity, 55),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: enviando
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Publicar Producto',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  void _feedback(BuildContext ctx, AgroSubirViewModel vm) {
    if (vm.estado == AgroSubirEstado.exito) {
      _tituloCtrl.clear();
      _precioCtrl.clear();
      _stockCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _foto = null;
        _coords = null;
      });
      _snack('¡Producto publicado con éxito! 🎉');
      vm.reiniciar();
    } else if (vm.estado == AgroSubirEstado.error &&
        vm.mensajeError.isNotEmpty) {
      _snack(vm.mensajeError, error: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      label,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontSize: 15,
      ),
    ),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
