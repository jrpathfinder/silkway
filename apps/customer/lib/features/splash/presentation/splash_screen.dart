import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Брендовое видео-заставка (Чайхана Шёлковый Путь), проигрывается один раз
/// при запуске приложения.
///
/// ВАЖНО: это ВТОРАЯ заставка. Первой показывается нативная (пакет
/// `flutter_native_splash`, настройки в pubspec.yaml) — она закрывает паузу,
/// пока грузится движок Flutter, и по определению может быть только
/// картинкой, видео там невозможно. Поэтому она показывает
/// `assets/branding/splash.png` — кадр из этого же видео. У обеих заставок
/// одинаковый цвет фона, чтобы переход «неподвижный кадр → видео» выглядел
/// как один непрерывный экран, без мигания.
///
/// Экран ВСЕГДА завершается вызовом [onFinished]: по окончании ролика, по
/// тапу (пропуск), или сразу же, если видео не удалось загрузить. Заставка
/// не имеет права заблокировать пользователю вход в приложение.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  /// Совпадает с `flutter_native_splash.color` в pubspec.yaml и с полями
  /// (letterbox) вокруг самого видео.
  static const backgroundColor = Color(0xff2a211a);

  /// Предел ожидания ЗАГРУЗКИ видео. Как только воспроизведение началось,
  /// таймер перезапускается на реальную длительность ролика плюс
  /// [playbackGrace] — иначе на медленном старте он сработал бы прямо
  /// посреди видео и обрезал концовку.
  static const maxDuration = Duration(seconds: 8);

  /// Запас поверх длительности ролика перед срабатыванием страховочного
  /// таймера: гасит рывки декодирования, но не даёт зависшему видео
  /// подвесить приложение.
  static const playbackGrace = Duration(seconds: 3);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  Timer? _failsafe;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _failsafe = Timer(SplashScreen.maxDuration, _finish);
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset('assets/branding/launch.mp4');
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // Без звука: заставка не должна перебивать музыку, которую пользователь
      // уже слушает. Со звуком пришлось бы отдельно настраивать iOS
      // audio-session, иначе система остановит чужое воспроизведение.
      await controller.setVolume(0);
      controller.addListener(_onTick);
      // Перезапускаем страховочный таймер на реальную длительность ролика —
      // теперь она известна. Бюджет ожидания загрузки выше не был рассчитан
      // ещё и на проигрывание, и на холодном старте обрывал видео на середине.
      _failsafe?.cancel();
      _failsafe = Timer(controller.value.duration + SplashScreen.playbackGrace, _finish);
      setState(() => _controller = controller);
      await controller.play();
    } catch (_) {
      // Видео не открылось (нет кодека, битый файл, нет плагина) — не
      // показываем ошибку, просто пропускаем заставку и пускаем в приложение.
      await controller.dispose();
      _finish();
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.hasError) {
      _finish();
      return;
    }
    if (controller.value.position >= controller.value.duration) _finish();
  }

  void _finish() {
    // Проверка `mounted` здесь принципиальна: и страховочный таймер, и
    // асинхронная инициализация видео могут сработать уже после того, как
    // экран убран с навигации, а onFinished выполняет переход через context.
    if (_finished || !mounted) return;
    _finished = true;
    _failsafe?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: GestureDetector(
        // Тап в любом месте пропускает заставку — ролик идёт 6 секунд, это
        // долго, если открываешь приложение второй раз подряд.
        onTap: _finish,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: controller == null || !controller.value.isInitialized
              // Пока не декодирован первый кадр, держим ту же картинку, что
              // показывала нативная заставка — чтобы между ними не мелькал
              // чёрный экран.
              //
              // SizedBox.expand + contain обязательны: без них исходник
              // 464x656 рисуется в своём натуральном размере, картинка
              // заметно «схлопывается» в маленький прямоугольник при передаче
              // от нативной заставки и потом рывком возвращается, когда
              // появляется видео. Здесь она растягивается на ту же ширину,
              // которую займёт видео.
              ? SizedBox.expand(
                  child: Image.asset('assets/branding/splash.png', fit: BoxFit.contain),
                )
              : AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
        ),
      ),
    );
  }
}
