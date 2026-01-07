import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackSurveyModal extends StatefulWidget {
  const FeedbackSurveyModal({super.key});

  @override
  State<FeedbackSurveyModal> createState() => _FeedbackSurveyModalState();
}

class _FeedbackSurveyModalState extends State<FeedbackSurveyModal> {
  final _formKey = GlobalKey<FormState>();
  final _guestController = TextEditingController();
  final _improvementsController = TextEditingController();
  final _generalController = TextEditingController();
  
  int _currentStep = 0; // 0: Invitation, 1: Form, 2: Success
  bool _isSubmitting = false;

  @override
  void dispose() {
    _guestController.dispose();
    _improvementsController.dispose();
    _generalController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await Supabase.instance.client.rpc(
        'submit_initial_feedback',
        params: {
          'p_guest_suggestions': _guestController.text,
          'p_improvements': _improvementsController.text,
          'p_feedback_text': _generalController.text,
        },
      );

      if (response['success'] == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await prefs.setBool('survey_completed_$userId', true);
        }
        setState(() => _currentStep = 2);
      } else {
        throw response['message'] ?? 'Error desconocido desde el servidor';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'Reintentar', textColor: Colors.white, onPressed: _submitFeedback),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_currentStep == 0) {
      return _buildInvitation(theme, colorScheme);
    } else if (_currentStep == 1) {
      return _buildForm(theme, colorScheme);
    } else {
      return _buildSuccess(theme, colorScheme);
    }
  }

  Widget _buildInvitation(ThemeData theme, ColorScheme colorScheme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 64, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              '¿Quieres ganar 1500 XP adicionales?',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ayúdanos a mejorar el próximo Comic Fest respondiendo una breve encuesta sobre los invitados que te gustaría ver.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ahora no'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: const Text('¡Sí, vamos!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, ColorScheme colorScheme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Encuesta de Invitados',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('¿Qué famosos o actores te gustaría ver en el Meet & Greet?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestController,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Henry Cavill, Tom Hiddleston...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Por favor responde esto' : null,
                ),
                const SizedBox(height: 20),
                const Text('¿Qué mejoras te gustaría ver en el próximo evento?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _improvementsController,
                  decoration: const InputDecoration(
                    hintText: 'Más comida, mejor aire acondicionado...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Este campo es importante' : null,
                ),
                const SizedBox(height: 20),
                const Text('¿Dudas o quejas adicionales?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _generalController,
                  decoration: const InputDecoration(
                    hintText: 'Cualquier otro comentario...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _submitFeedback,
                        child: const Text('ENVIAR Y GANAR 1500 XP'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, ColorScheme colorScheme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              '¡Gracias por tu opinión!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tus comentarios son invaluables. Hemos añadido 1500 XP a tu cuenta.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¡LISTO!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
