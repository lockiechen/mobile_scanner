import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/method_channel/rotated_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);
  final supportsHarmony = TargetPlatform.values.any(
    (platform) => platform.name == 'ohos',
  );

  testWidgets(
    'Harmony scanner keeps native registration and rotation delegate',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.values.firstWhere(
        (platform) => platform.name == 'ohos',
      );
      final platform = MethodChannelMobileScanner();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(platform.methodChannel, (call) async {
        calls.add(call);
        if (call.method == 'state') return 1;
        if (call.method == 'start') {
          // Same response shape as the pinned Harmony native plugin.
          return {
            'textureId': 42,
            'size': {'width': 720.0, 'height': 1280.0},
            'numberOfCameras': 1,
            'currentTorchState': 0,
          };
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(platform.methodChannel, null),
      );
      final attributes = await platform.start(
        const StartOptions(
          cameraDirection: CameraFacing.back,
          cameraLensType: CameraLensType.any,
          cameraResolution: Size(1280, 720),
          detectionSpeed: DetectionSpeed.noDuplicates,
          detectionTimeoutMs: 250,
          formats: [BarcodeFormat.qrCode],
          returnImage: false,
          torchEnabled: false,
          invertImage: false,
          autoZoom: false,
          initialZoom: null,
        ),
      );
      expect(attributes.size, const Size(720, 1280));
      expect(attributes.initialDeviceOrientation, DeviceOrientation.portraitUp);
      expect(platform.buildCameraView(), isA<RotatedPreview>());
      await platform.setFocusPoint(const Offset(.25, .5));
      expect(calls.last.method, 'setFocus');
      await platform.stop();
      expect(calls.last.method, 'stop');
      debugDefaultTargetPlatformOverride = null;
    },
    skip: !supportsHarmony,
  );

  testWidgets(
    'Harmony preview follows every orientation after stream replacement',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.values.firstWhere(
        (platform) => platform.name == 'ohos',
      );
      final first = StreamController<DeviceOrientation>.broadcast(sync: true);
      final second = StreamController<DeviceOrientation>.broadcast(sync: true);
      addTearDown(first.close);
      addTearDown(second.close);
      Future<void> show(Stream<DeviceOrientation> stream) => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RotatedPreview(
            deviceOrientationStream: stream,
            facingSign: -1,
            initialDeviceOrientation: DeviceOrientation.portraitUp,
            sensorOrientationDegrees: 90,
            child: const SizedBox(),
          ),
        ),
      );
      await show(first.stream);
      for (final (orientation, turns) in [
        (DeviceOrientation.portraitUp, 0),
        (DeviceOrientation.landscapeRight, 1),
        (DeviceOrientation.portraitDown, 2),
        (DeviceOrientation.landscapeLeft, 3),
      ]) {
        first.add(orientation);
        await tester.pump();
        expect(
          tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
          turns,
        );
      }
      await show(second.stream);
      second.add(DeviceOrientation.landscapeRight);
      await tester.pump();
      expect(
        tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
        1,
      );
      expect(first.hasListener, isFalse);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
    skip: !supportsHarmony,
  );
}
