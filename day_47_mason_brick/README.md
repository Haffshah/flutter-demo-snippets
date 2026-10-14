# Mason brick: clean-architecture feature folder

One command creates a feature with a domain contract, a data implementation, a BLoC (events, states, bloc) and a test, all named consistently.

## Use it

```bash
dart pub global activate mason_cli
cd your_flutter_app
mason init
# in mason.yaml:
#   bricks:
#     feature_brick:
#       path: ../flutter-demo-snippets/day_47_mason_brick/feature_brick
mason get
mason make feature_brick --name checkout_flow
```

You get:

```
lib/features/checkout_flow/
  domain/repositories/checkout_flow_repository.dart        (abstract contract)
  data/repositories/checkout_flow_repository_impl.dart     (replace with your data source)
  presentation/bloc/checkout_flow_{bloc,event,state}.dart
test/features/checkout_flow/presentation/bloc/checkout_flow_bloc_test.dart
```

## Needs in your app

`bloc` in `dependencies`, `flutter_test` in `dev_dependencies`. In the generated test, change `your_app` to your package name.

## How this was checked

I generated a feature from this brick into a scratch Flutter app (`bloc` + `flutter_test`) using the `mason` package, then ran `flutter analyze` (clean) and `flutter test` (2 tests pass).
I did not run it through the `mason_cli` command line.

## With an AI coding agent

Tell the agent to run `mason make` first, then fill in the repository and bloc logic, then run `flutter analyze` and `flutter test`. The structure stays the same on every feature, so reviews get easier.
