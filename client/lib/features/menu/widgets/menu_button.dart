import 'package:flutter/material.dart';

/// Botón grande del menú principal. [badge] muestra una etiqueta (p. ej.
/// "Próximamente") junto al texto.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? Colors.green[700]
              : const Color(0xFF142E21),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: primary
                ? BorderSide.none
                : const BorderSide(color: Colors.white24),
          ),
        ),
        onPressed: onPressed,
        // FittedBox: en pantallas angostas el contenido se achica en vez de desbordar.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
