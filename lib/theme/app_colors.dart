import 'package:flutter/material.dart';

/// Paleta de colores basada en el logo de VCM Arquitectura Inteligente.
/// 
/// Colores principales extraídos del logo:
/// - Azul oscuro/slate (las letras V y los elementos de construcción)
/// - Dorado/bronce (las letras CM)
/// - Gris claro/plata (elementos secundarios)
class AppColors {
  AppColors._();

  // ── Colores Primarios del Logo ──────────────────────────────────
  
  /// Azul oscuro/slate - Color principal (V del logo, elementos de construcción)
  static const Color primary = Color(0xFF3D5266);
  
  /// Azul oscuro profundo - Para AppBar y headers
  static const Color primaryDark = Color(0xFF2D3E4F);
  
  /// Azul slate claro - Para hover y estados activos
  static const Color primaryLight = Color(0xFF5A7A96);

  /// Dorado/bronce - Color de acento (CM del logo)
  static const Color accent = Color(0xFFB8943E);
  
  /// Dorado oscuro - Para bordes y detalles
  static const Color accentDark = Color(0xFF9A7A2E);
  
  /// Dorado claro - Para fondos suaves
  static const Color accentLight = Color(0xFFD4B868);

  // ── Colores Neutros ─────────────────────────────────────────────
  
  /// Gris claro/plata - Para elementos terciarios
  static const Color silver = Color(0xFFA8B8C8);
  
  /// Fondo principal - Blanco hueso/crema del logo
  static const Color background = Color(0xFFF5F3EF);
  
  /// Fondo de tarjetas
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Texto principal
  static const Color textPrimary = Color(0xFF2D3E4F);
  
  /// Texto secundario
  static const Color textSecondary = Color(0xFF6B7C8D);

  // ── Colores Semánticos ──────────────────────────────────────────
  
  /// Éxito/Entrada
  static const Color success = Color(0xFF4A8B6E);
  
  /// Error/Salida
  static const Color error = Color(0xFFCF6679);
  
  /// Advertencia
  static const Color warning = Color(0xFFE8A838);
  
  /// Información
  static const Color info = Color(0xFF5A7A96);

  // ── Colores para Dashboard Cards ────────────────────────────────
  
  static const Color cardEmpleados = Color(0xFF3D5266);
  static const Color cardLocaciones = Color(0xFFB8943E);
  static const Color cardHerramientas = Color(0xFF8B6F47);
  static const Color cardInventario = Color(0xFF5A7A96);
  static const Color cardVehiculos = Color(0xFF6B5B73);
  static const Color cardReportes = Color(0xFF4A8B6E);
  static const Color cardUsuarios = Color(0xFF9A7A2E);

  // ── Gradientes ──────────────────────────────────────────────────
  
  /// Gradiente principal para headers y splash
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  /// Gradiente dorado para acentos
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDark, accent, accentLight],
  );

  /// Gradiente para el splash screen
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2D3E4F),
      Color(0xFF3D5266),
      Color(0xFF4A6278),
    ],
  );
}
