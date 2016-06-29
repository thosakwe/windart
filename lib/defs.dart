library windart.defs;
import 'dart:math';

class WinApi {
  final String name;
  final String returnAs;
  const WinApi([String this.name, String this.returnAs]);
}

class WinMain {
  const WinMain();
}

class Include {
  final String src;
  const Include(String this.src);
}

class IncludeLib {
  final String src;
  const IncludeLib(String this.src);
}