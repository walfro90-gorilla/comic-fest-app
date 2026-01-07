import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class WelcomeModal extends StatefulWidget {
  const WelcomeModal({super.key});

  @override
  State<WelcomeModal> createState() => _WelcomeModalState();
}

class _WelcomeModalState extends State<WelcomeModal> {
  late ConfettiController _confettiController;
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': '¡Bienvenido(a) a Comic Fest!',
      'description': 'Estamos emocionados de tenerte aquí. Tu aventura comienza ahora.',
      'icon': '🎉',
    },
    {
      'title': 'Explora la Agenda',
      'description': 'No te pierdas ningún panel, firma de autógrafos o torneo.',
      'icon': '📅',
    },
    {
      'title': 'Gana Puntos',
      'description': 'Realiza actividades para subir de nivel y desbloquear recompensas.',
      'icon': '⭐',
    },
    {
      'title': 'Mapa Interactivo',
      'description': 'Ubica rápidamente tus stands y expositores favoritos.',
      'icon': '🗺️',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final step = _steps[_currentStep];

    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step['icon']!,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 24),
                Text(
                  step['title']!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  step['description']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentStep < _steps.length - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentStep < _steps.length - 1 ? 'Siguiente' : '¡Empezar!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ],
        ),
      ],
    );
  }
}
