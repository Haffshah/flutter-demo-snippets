# Copy-paste prompt: migrate a Flutter iOS app to the UIScene lifecycle

Paste this into your coding agent from the root of your Flutter project.

```text
Migrate this Flutter project's iOS runner to the UIScene lifecycle.

Do exactly this, and show me a diff before finishing:

1. In ios/Runner/Info.plist add a UIApplicationSceneManifest with
   UIApplicationSupportsMultipleScenes = false and one UIWindowSceneSessionRoleApplication
   entry: UISceneClassName = UIWindowScene, UISceneDelegateClassName = FlutterSceneDelegate,
   UISceneConfigurationName = flutter, UISceneStoryboardFile = Main.
   Do not remove or reorder any existing keys.

2. In ios/Runner/AppDelegate.swift make AppDelegate conform to FlutterImplicitEngineDelegate
   and move GeneratedPluginRegistrant.register(with:) into
   didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge),
   registering with engineBridge.pluginRegistry. Keep import Flutter first.

3. Search ios/ for FirebaseApp.configure(). If Firebase is also initialised from Dart,
   tell me and remove the native call only after I confirm.

4. Search ios/ for any code that uses AppDelegate.window and list it. Do not change it.

5. Run `flutter build ios --no-codesign` and report the result. Do not claim success
   if the build was not run.

Do not touch Android, pubspec.yaml, or any file not listed above.
```

Always check the result against the Flutter docs for your SDK version.
