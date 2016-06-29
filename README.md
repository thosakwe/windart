# windart
[EXPERIMENTAL] Compiles Dart to MASM Assembly.

This implementation is **ABSOLUTELY IN NO WAY** standards-compliant. In fact, it can't really do anything just yet.

# Why?
Boredom, plus I have a pretty rad [Dart parser](https://github.com/thosakwe/dart_parser) at my disposal.

Technically, it is now possible to compile *native* Windows binaries from Dart. 

# Installation

```yaml
dependencies:
  windart: ^1.0.0-dev
transformers:
- windart
```

This is designed to be used with the [MASM transformer](https://github.com/thosakwe/dart_masm). This transformer will
override dart2js.

# Usage
Self-explanatory, for the most part. The scripts need to be in the `web` directory, haha.

```dart
@Include("Some optional library.inc")
@IncludeLib("library.lib")
library my_native_app;

import "package:windart/defs.dart";

@WinApi()
external int MessageBox(int hWnd, String lpText, String lpCaption, int uType);

@WinApi() external void ExitProcess(int uExitCode);

@WinMain()
main(List<String> args) {
  MessageBox(null, "Hello, world!", "via WinDart", 0);
  ExitProcess(0);
}
```
