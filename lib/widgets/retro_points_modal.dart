import 'dart:async';
import 'package:flutter/material.dart';

class RetroPointsModal extends StatefulWidget {
  final int points;
  const RetroPointsModal({super.key, this.points = 500});

  @override
  State<RetroPointsModal> createState() => _RetroPointsModalState();
}

class _RetroPointsModalState extends State<RetroPointsModal> {
  String _displayedText = "";
  final String _fullText = "¡INCREÍBLE!\n\nHas recibido 500 XP como bono de bienvenida.\n\n¡Tu aventura apenas comienza!";
  Timer? _timer;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
  }

  void _startTypewriter() {
    int index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < _fullText.length) {
        if (mounted) {
          setState(() {
            _displayedText += _fullText[index];
            index++;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Retro Sprite Placeholder
          const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 100),
          const SizedBox(height: 20),
          // Gameboy Text Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayedText + (_showCursor ? "█" : ""),
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "A OK",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
