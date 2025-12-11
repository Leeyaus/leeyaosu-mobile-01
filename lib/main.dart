import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

const kBrandPrimaryGreen = Color(0xFF004D40);
const kBrandAccentGold = Color(0xFFFFC107);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  runApp(const YaosuLeeApp());
}

class YaosuLeeApp extends StatelessWidget {
  const YaosuLeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '李藥師線上整復教學',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandPrimaryGreen),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBrandPrimaryGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kBrandAccentGold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: kBrandAccentGold,
        ),
      ),
      // 先進入啟動影片畫面
      home: const SplashScreen(),
    );
  }
}

/// 啟動影片畫面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // TODO: 這裡的路徑請依你實際放 mp4 的路徑調整
    // 例如：assets/splash/intro.mp4
    _videoController =
        VideoPlayerController.asset('assets/splash/intro.mp4')
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {});
            _videoController.play();
          });

    // 監聽影片播放結束
    _videoController.addListener(() {
      if (!_videoController.value.isInitialized) return;
      final finished =
          _videoController.value.position >= _videoController.value.duration;
      if (finished && !_navigated && mounted) {
        _goNext();
      }
    });

    // 保險機制：超過 10 秒就強制進入主畫面（避免影片讀取失敗卡死）
    Future.delayed(const Duration(seconds: 10), () {
      if (!_navigated && mounted) {
        _goNext();
      }
    });
  }

  void _goNext() {
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goNext, // 點一下也可以略過影片
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _videoController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// 主要 WebView 殼
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 網址常數
  static const String kLoginUrl = 'https://yaosulee.com/login-2/';
  static const String kCoursesUrl = 'https://yaosulee.com/lpcourses/';

  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentTitle = '會員登入';

  /// 清爽畫面：隱藏頁首 / 頁尾等
  Future<void> _applyCleanUI() async {
    const js = r"""
      (function() {
        const hide = (sel) => document.querySelectorAll(sel).forEach(el => {
          el.style.display = 'none';
        });

        hide('#wpadminbar, header, .site-header, .elementor-location-header, .ast-header-break-point, .ast-primary-header-bar, .ast-mobile-header-wrap, .o-header, .oceanwp-mobile-menu-icon');
        hide('footer, .site-footer, .elementor-location-footer');
        hide('.breadcrumbs, .breadcrumb, .page-header, .top-bar, .site-breadcrumbs, .notice, .announcement');

        document.documentElement.style.setProperty('--wp-admin--admin-bar--height','0px');
        document.body.style.marginTop = '0';
        document.body.style.paddingTop = '0';

        const relax = (sel) => document.querySelectorAll(sel).forEach(el => {
          el.style.marginTop = '0';
          el.style.paddingTop = '0';
        });
        relax('main, .site-main, .content-area, .elementor-section');

        if (!window.__yaosuLeeObserverAdded) {
          window.__yaosuLeeObserverAdded = true;
          try {
            const observer = new MutationObserver(() => {
              hide('#wpadminbar, header, .site-header, .elementor-location-header, .ast-header-break-point, .ast-primary-header-bar, .ast-mobile-header-wrap, .o-header, .oceanwp-mobile-menu-icon');
              hide('footer, .site-footer, .elementor-location-footer');
              hide('.breadcrumbs, .breadcrumb, .page-header, .top-bar, .site-breadcrumbs, .notice, .announcement');
              relax('main, .site-main, .content-area, .elementor-section');
            });
            observer.observe(document.body, { childList: true, subtree: true });
          } catch(e) {}
        }
      })();
    """;

    try {
      await _controller.runJavaScriptReturningResult(js);
    } catch (_) {}
  }

  /// 導向外部 APP / 瀏覽器（官方網站、IG、Line、WhatsApp、電話）
  Future<void> _launchExternalUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  /// 顯示「聯繫我們」底部彈窗
  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    '聯繫我們',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kBrandPrimaryGreen,
                    ),
                  ),
                  subtitle: Text('骨寶有限公司'),
                ),
                const Divider(),

                // 官方網站
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('官方網站'),
                  subtitle: const Text('yaosulee.com'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchExternalUrl('https://yaosulee.com/');
                  },
                ),

                // Instagram
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Instagram'),
                  subtitle: const Text('@yaosu.lee'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchExternalUrl(
                      'https://www.instagram.com/yaosu.lee/?hl=zh-tw',
                    );
                  },
                ),

                // Line 官方帳號
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Line 官方帳號'),
                  subtitle: const Text('@901pqtpo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchExternalUrl(
                      'https://line.me/R/ti/p/@901pqtpo',
                    );
                  },
                ),

                // WhatsApp
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('WhatsApp 聯絡'),
                  subtitle: const Text('+886 921 821 212'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchExternalUrl('https://wa.me/886921821212');
                  },
                ),

                // 一鍵撥號
                ListTile(
                  leading: const Icon(Icons.call),
                  title: const Text('一鍵撥號'),
                  subtitle: const Text('+886 921 821 212'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchExternalUrl('tel:+886921821212');
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 加上時間戳，避免快取
  Uri _freshUri(String base) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(base);
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['ts'] = '$now';
    return uri.replace(queryParameters: qp);
  }

  Future<void> _goTo(String url, {String? title}) async {
    setState(() {
      _isLoading = true;
      if (title != null) _currentTitle = title;
    });
    await _controller.loadRequest(_freshUri(url));
  }

  Future<void> _handleWebError(WebResourceError error) async {
    try {
      final cur = await _controller.currentUrl();
      debugPrint('Web error on $cur: ${error.errorCode} ${error.description}');
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    final params = Platform.isAndroid
        ? const PlatformWebViewControllerCreationParams()
        : const PlatformWebViewControllerCreationParams();

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            await _applyCleanUI();
          },
          onWebResourceError: _handleWebError,
          onNavigationRequest: (req) => NavigationDecision.navigate,
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidCtrl = controller.platform as AndroidWebViewController;
      androidCtrl.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _goTo(kLoginUrl, title: '會員登入');
  }

  Future<bool> _onWillPop() async => false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitle),
          centerTitle: false,
          actions: [
            // 前往線上課程
            TextButton.icon(
              onPressed: () => _goTo(kCoursesUrl, title: '線上課程'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('前往線上課程'),
            ),

            // 聯繫我們（官方網站 / IG / Line / WhatsApp / 電話）
            TextButton.icon(
              onPressed: _showContactSheet,
              icon: const Icon(Icons.contact_phone_outlined),
              label: const Text('聯繫我們'),
            ),

            // 首頁：回登入頁
            IconButton(
              tooltip: '回會員登入',
              onPressed: () => _goTo(kLoginUrl, title: '會員登入'),
              icon: const Icon(Icons.home_outlined),
            ),
          ],
          bottom: _isLoading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
