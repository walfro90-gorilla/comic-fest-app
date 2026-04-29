import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  static const _externalUrl = 'https://infinite-heroes-eight.vercel.app/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Comic'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'Esta sección se abre en una nueva pestaña del navegador.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Crear Comic'),
                onPressed: () => launchUrl(
                  Uri.parse(_externalUrl),
                  webOnlyWindowName: '_blank',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
