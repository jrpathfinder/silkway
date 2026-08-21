import 'package:flutter/material.dart';

/// Брендовая заставка при запуске (Чайхана Шёлковый Путь).
///
/// Сюжет: шёлковая шторка с логотипом плавно растворяется, открывая интерьер
/// чайханы. Обе сцены — статичные картинки, поэтому никаких кодеков в старте
/// нет: видеоролик отсюда убран намеренно (декодер раскручивался ~2 секунды
/// до первого кадра, сам ролик занимал ещё 6, а его пропорции не совпадали с
/// экраном и по краям оставались тёмные поля).
///
/// ВАЖНО: это ВТОРАЯ заставка. Первой ОС показывает нативную (пакет
/// `flutter_native_splash`, настройки в pubspec.yaml). Она показывает тот же
/// [silkAsset] и в том же режиме масштабирования, а анимация здесь стартует
/// с масштаба 1.0 и нулевой прозрачности чайханы — то есть ровно с того
/// кадра, который уже на экране. Поэтому передача управления незаметна.
///
/// Экран ВСЕГДА завершается вызовом [onFinished]: по окончании анимации или
/// по тапу. Заставка не имеет права заблокировать вход в приложение.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  /// Первая сцена. Должна совпадать с картинкой в `flutter_native_splash`
  /// (pubspec.yaml), иначе при передаче управления кадр дёрнется.
  static const silkAsset = 'assets/branding/splash_full.png';

  /// Вторая сцена, в которую уходит переход.
  static const teahouseAsset = 'assets/branding/teahouse_full.png';

  /// Совпадает с `flutter_native_splash.color` — виден, только если картинки
  /// почему-то не загрузились.
  static const backgroundColor = Color(0xff2a211a);

  /// Общая длительность заставки. Компромисс: короче — и вторая сцена не
  /// успевает считаться, длиннее — пользователь ждёт перед меню на каждом
  /// холодном запуске.
  static const duration = Duration(milliseconds: 2200);

  /// Окно перехода внутри [duration]: до него видна только шторка, после —
  /// только чайхана.
  ///
  /// Растворение намеренно короткое (~400 мс). Медленный кроссфейд между
  /// двумя одинаково яркими кадрами читается не как смена сцены, а как
  /// расфокус — смена должна быть заметной. Основное время отдано чайхане:
  /// именно её нужно успеть разглядеть.
  ///
  /// Пауза в начале (~400 мс) нужна, чтобы стык с нативной заставкой
  /// прочитался как одна картинка, а не как мгновенный перескок.
  static const fadeBegin = 0.18;
  static const fadeEnd = 0.36;

  /// Насколько наезжает камера за всю заставку. Едва заметно — движение
  /// должно читаться как «живой кадр», а не как зум.
  static const zoomTo = 1.06;

  /// Ключи анимируемых слоёв: во внутреннем дереве Flutter есть и свои
  /// Transform, и свои FadeTransition (их создаёт Image при загрузке),
  /// поэтому тесту нужно попадать именно в наши.
  static const zoomKey = ValueKey('splash-zoom');
  static const fadeKey = ValueKey('splash-fade');

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _zoom;
  late final Animation<double> _teahouseOpacity;
  bool _finished = false;
  bool _preloaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: SplashScreen.duration);
    _zoom = Tween<double>(begin: 1, end: SplashScreen.zoomTo)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _teahouseOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(SplashScreen.fadeBegin, SplashScreen.fadeEnd, curve: Curves.easeInOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    // Стартуем сразу, не дожидаясь декодирования второй сцены: заставка
    // должна начаться мгновенно. Переход стартует только на fadeBegin
    // (~450 мс), к этому моменту картинка уже прогрета — см.
    // didChangeDependencies.
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preloaded) return;
    _preloaded = true;
    // Греем вторую сцену параллельно с началом заставки, чтобы к моменту
    // fadeBegin она была уже декодирована и растворение не дёрнулось.
    // Ошибку глотаем намеренно: заставка обязана доиграть и пустить дальше
    // даже если картинка не загрузилась.
    precacheImage(const AssetImage(SplashScreen.teahouseAsset), context).catchError((Object _) {});
  }

  void _finish() {
    // Проверка `mounted` важна: колбэк анимации может прийти уже после того,
    // как экран убран с навигации, а onFinished выполняет переход через
    // context.
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: GestureDetector(
        onTap: _finish,
        behavior: HitTestBehavior.opaque,
        // ClipRect не даёт увеличенной картинке вылезти за пределы экрана.
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              key: SplashScreen.zoomKey,
              scale: _zoom.value,
              child: child,
            ),
            // Дерево строится один раз и переиспользуется на каждом кадре:
            // меняются только матрица масштаба и прозрачность, декодировать
            // картинки заново не нужно.
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(SplashScreen.silkAsset, fit: BoxFit.cover),
                FadeTransition(
                  key: SplashScreen.fadeKey,
                  opacity: _teahouseOpacity,
                  child: Image.asset(SplashScreen.teahouseAsset, fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
