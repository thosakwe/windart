import 'dart:convert';
import 'dart:io';
import 'package:antlr4dart/antlr4dart.dart';
import 'package:dart_parser/dart_parser.dart';
import 'package:windart/src/transpiler.dart';
import 'package:test/test.dart';

const String src = '''
import 'package:windart/defs.dart';

@WinApi() external int GetStdHandle(int nStdHandle);
@WinApi() external bool WriteConsole(int hConsoleOutput, String lpBuffer);

@WinMain()
main() {
  int hConsole = GetStdHandle(-11);
  WriteConsole(hConsole, "Hello, world!");
}
''';

main() {
  test("sample compilation", () async {
    var transpiler = parse(src);

    stderr.write(transpiler.output);
  });
}