import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1565C0); // Azul Institucional
  static const Color secondaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFC62828);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ValidadoresSistema {
  /// RF-AUT-002: Validación de formato de correo electrónico
  static bool validarCorreo(String correo) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(correo.trim());
  }

  /// RF-AUT-003: Validación de cédula de identidad de la República del Ecuador (Algoritmo Módulo 10)
  static bool validarCedulaEcuatoriana(String cedula) {
    final clean = cedula.trim();
    if (clean.length != 10) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(clean)) return false;

    final provincia = int.parse(clean.substring(0, 2));
    if (!((provincia >= 1 && provincia <= 24) || provincia == 30)) {
      return false;
    }

    final tercerDigito = int.parse(clean[2]);
    if (tercerDigito >= 6) return false;

    final coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;

    for (int i = 0; i < 9; i++) {
      int valor = int.parse(clean[i]) * coeficientes[i];
      if (valor >= 10) valor -= 9;
      suma += valor;
    }

    final digitoVerificador = int.parse(clean[9]);
    final decenaSuperior = ((suma + 9) ~/ 10) * 10;
    int resultado = decenaSuperior - suma;
    if (resultado == 10) resultado = 0;

    return resultado == digitoVerificador;
  }

  /// RF-AUT-004: Política de seguridad de contraseña (mínimo 8 caracteres, letras y números)
  static bool validarPoliticaContrasena(String password) {
    if (password.length < 8) return false;
    final tieneLetra = RegExp(r'[A-Za-z]').hasMatch(password);
    final tieneNumero = RegExp(r'[0-9]').hasMatch(password);
    return tieneLetra && tieneNumero;
  }
}