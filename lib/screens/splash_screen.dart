import 'package:flutter/material.dart';
import 'veschi_screen.dart';
import '../services/wp_api.dart';

class SplashScreen extends StatelessWidget {
  final WPApi api;
  const SplashScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A2A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A2A),
              Color(0xFF1A0A2A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // КАРТИНКА ЛОГОТИПА
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17), // Немного меньше чем контейнер
                  child: Image.asset(
                    'assets/images/logo.png', // ПУТЬ К ВАШЕЙ КАРТИНКЕ
                    fit: BoxFit.cover, // Заполняет весь контейнер
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      // Если картинка не загрузится, покажем иконку
                      return const Icon(
                        Icons.flag,
                        size: 100,
                        color: Colors.orange,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Текст ПРИВЕТ!!!
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.orange, Colors.yellow],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'ПРИВЕТ!!!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Подзаголовок
              Text(
                'Добро пожаловать в БАЗАР-ВОКЗАЛ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 60),
              
              // Кнопка ЖМИ СЮДА
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VeschiScreen(api: api),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'ЖМИ СЮДА',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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