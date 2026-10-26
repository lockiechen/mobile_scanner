# iOS orientation and Harmony compatibility patches

Based on upstream mobile_scanner 7.4.2 (MIT):
https://github.com/juliansteenbakker/mobile_scanner/tree/v7.4.2

The application uses a legacy AppDelegate without a UIScene manifest. Upstream
7.4.2 assumes connectedScenes is populated on iOS 13+, otherwise the video
output stays portrait and the orientation stream sends no events.

InterfaceOrientation.swift resolves the key window scene first, then an active
scene, and falls back to statusBarOrientation for legacy hosts. Both the video
output and orientation event stream use the same interface orientation, so
rotation lock is respected. Both observers also listen for completed legacy
interface rotation and defer device callbacks to the main queue. Android, macOS and Web native sources retain upstream behavior.

These patches are maintained on the codex/ios-orientation-harmony-7.4.2
branch. Consumers should pin a full commit SHA in their Git dependency.
Remove the iOS patch once upstream supports legacy hosts in both places.

## Harmony compatibility

Ported the ohos implementation and Dart surface orientation integration from
https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
commit f5a4ff52f003e1645db1d4de743a2db0313665a8 (7.1.4, MIT).
The local package retains upstream 7.4.2 Android/iOS fixes while registering
the Harmony plugin and preserving its preview rotation rules.
