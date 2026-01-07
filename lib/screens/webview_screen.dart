import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions on init
    _initWebView();
  }

  Future<void> _requestPermissions() async {
    // Proactively request camera and storage permissions
    await [
      Permission.camera,
      Permission.storage, // For older Androids
      Permission.photos, // For newer Androids
    ].request();
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              // Inject CSS to disable elastic scroll (bouncing)
              _controller.runJavaScript('''
                var style = document.createElement('style');
                style.type = 'text/css';
                style.innerHTML = "body { overscroll-behavior-y: none; }";
                document.head.appendChild(style);
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Evento recibido desde Web: ${message.message}')),
          );
          // Handle specific events like PDF download here if the web sends specific strings
          debugPrint('FlutterBridge Message: ${message.message}');
        },
      )
      ..loadRequest(Uri.parse('https://infinite-heroes-eight.vercel.app/'));

    // Android-specific configuration
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
          
      // Handle permission requests from the WebView (e.g. for camera usage)
      (controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
      
      // Handle file selection manually for Android using image_picker
      (controller.platform as AndroidWebViewController).setOnShowFileSelector(
        (FileSelectorParams params) async {
          debugPrint('WebView: setOnShowFileSelector called');
          final ImagePicker picker = ImagePicker();
          
          try {
            final XFile? image = await showModalBottomSheet<XFile?>(
              context: context,
              backgroundColor: Colors.white,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Tomar Foto'),
                        onTap: () async {
                           debugPrint('WebView: User chose Camera');
                           try {
                             final picked = await picker.pickImage(source: ImageSource.camera);
                             debugPrint('WebView: Camera picked: ${picked?.path}');
                             if (context.mounted) {
                               Navigator.pop(context, picked);
                             }
                           } catch (e) {
                             debugPrint('WebView: Camera Error: $e');
                             if (context.mounted) Navigator.pop(context, null);
                           }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Elegir de Galería'),
                        onTap: () async {
                           debugPrint('WebView: User chose Gallery');
                           try {
                             final picked = await picker.pickImage(source: ImageSource.gallery);
                             debugPrint('WebView: Gallery picked: ${picked?.path}');
                             if (context.mounted) {
                               Navigator.pop(context, picked);
                             }
                           } catch (e) {
                             debugPrint('WebView: Gallery Error: $e');
                             if (context.mounted) Navigator.pop(context, null);
                           }
                        },
                      ),
                    ],
                  ),
                );
              },
            );

            debugPrint('WebView: Modal Result: ${image?.path}');
            if (image != null) {
              final uri = Uri.file(image.path).toString();
              debugPrint('WebView: Returning URI: $uri');
              return [uri];
            }
          } catch (e) {
            debugPrint('WebView: setOnShowFileSelector Critical Error: $e');
          }
          return [];
        },
      );
    }
    
    // iOS-specific configuration
     if (controller.platform is WebKitWebViewController) {
       // Disable elastic scroll on iOS for native feel
       // Note: webview_flutter 4.x doesn't expose scrollView.bounces directly effectively 
       // without some hacks or using the inner scroll view if accessible.
       // However, often strictly setting javascript mode and layout is enough.
       // We'll leave it as standard behavior or try to inject CSS to prevent body scroll behavior if needed.
       // For now, simply ensuring it's in SafeArea is key.
     }

    _controller = controller;
  }

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
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: {
                Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
                ),
                Factory<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                ),
                Factory<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                ),
                Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer(),
                ),
              },
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
