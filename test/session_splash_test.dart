import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bengkel_kendaraan/core/widgets/session_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(configFile.readAsStringSync()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = configFile.absolute.uri.resolve(flutter['rootUri'] as String);
    final fonts = Uri.parse(
      '${root.toString().replaceFirst(RegExp(r'/$'), '')}/',
    ).resolve('../../bin/cache/artifacts/material_fonts/');
    final loader = FontLoader('Roboto');
    for (final name in ['regular', 'medium', 'bold']) {
      loader.addFont(
        File.fromUri(
          fonts.resolve('roboto-$name.ttf'),
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  });

  testWidgets(
    'splash remains full bleed and announces loading across viewports',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in const [
        Size(320, 568),
        Size(360, 800),
        Size(390, 844),
        Size(430, 932),
        Size(800, 600),
      ]) {
        tester.view.physicalSize = size;
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: const EdgeInsets.only(top: 44, bottom: 24),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const SessionSplash(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$size at $scale');
          expect(tester.getSize(find.byType(SplashArtwork)), size);
          expect(find.byType(Scrollable), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(
            find.bySemanticsLabel(
              'BengkelKu. Aplikasi Manajemen Bengkel. Memuat akun.',
            ),
            findsOneWidget,
          );
          final brand = tester.getRect(find.text('BengkelKu'));
          final subtitle = tester.getRect(
            find.text('Aplikasi Manajemen Bengkel'),
          );
          final vehicles = tester.getRect(
            find.byWidgetPredicate((widget) {
              if (widget is! Image) return false;
              final provider = widget.image is ResizeImage
                  ? (widget.image as ResizeImage).imageProvider
                  : widget.image;
              return provider is AssetImage &&
                  provider.assetName.endsWith('splash-vehicles.png');
            }),
          );
          expect(subtitle.top, greaterThan(brand.bottom));
          expect(
            subtitle.bottom,
            lessThan(vehicles.top),
            reason: '$size at $scale',
          );
        }
      }
      semantics.dispose();
    },
  );

  testWidgets('capture splash at poster aspect and export native artwork', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 3;
    final dir = Directory('build/splash-evidence')..createSync(recursive: true);
    for (final entry in {
      'reference': const Size(331, 699),
      'native': const Size(390, 824),
    }.entries) {
      tester.view.physicalSize = entry.value * 3;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(key: key, child: const SessionSplash()),
        ),
      );
      await tester.runAsync(() async {
        for (final img in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(img.image, key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final raster = await boundary.toImage(pixelRatio: 3);
        final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${dir.path}/splash-${entry.key}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        raster.dispose();
      });
    }
  });
}
