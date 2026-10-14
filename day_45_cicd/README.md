# Flutter CI/CD: git tag to store (GitHub Actions + Fastlane)

> From the carousel on Instagram: [Day 45, @_letsbuildapps](https://www.instagram.com/p/Dd5RDzmjLzo/)

Push a tag like `v1.4.0` and the workflow runs five steps:

1. **Quality gate** on a cheap Linux runner: `dart format`, `flutter analyze --fatal-warnings`, `flutter test --coverage`. Fail here before spending macOS minutes.
2. **Android** (Ubuntu) and **iOS** (macOS) build in parallel after the gate passes.
3. **Signing** uses secrets, never files in git.
4. **Fastlane** `beta` lane uploads the iOS build to TestFlight.
5. The Android `.aab` is uploaded as a build artifact (see below for Play Console).

## Files

| File | Purpose |
|---|---|
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | The pipeline |
| [`ios/fastlane/Fastfile`](ios/fastlane/Fastfile) | `beta` lane: match, build, TestFlight |
| [`ios/Gemfile`](ios/Gemfile) | Fastlane dependency |

Copy them into your Flutter project, keeping the same paths.

## Secrets to create (Settings > Secrets and variables > Actions)

| Secret | What it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` output |
| `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | Keystore details |
| `MATCH_PASSWORD`, `MATCH_GIT_URL` | Fastlane match encryption password and the private certificates repo |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` | App Store Connect API key |

**Never commit keystores, `key.properties`, `.p8` keys or certificates.**

## Before you rely on it

- This is a **template I have not run against a real store account**. The YAML is checked for syntax, but signing, match and TestFlight steps need your own credentials and project setup. Expect to adjust it.
- Android `key.properties` signing needs a matching `signingConfigs` block in `android/app/build.gradle`.
- Uploading the Android bundle to Google Play's internal track needs an extra step (for example the `r0adkll/upload-google-play` action with a service-account secret). It is not included here.
- Pin action versions and Flutter version for repeatable builds if you need that.
