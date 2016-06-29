library windart.src.transpiler;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:antlr4dart/antlr4dart.dart';
import 'package:dart_parser/dart_parser.dart';
import '../defs.dart';

part 'masm_value/masm_value.dart';

part 'masm_value/resolve.dart';

part 'masm_value/resolver.dart';

String _randomString({int length: 32,
String validChars:
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"}) {
  String result = "";
  var rnd = new Random();

  do {
    result += validChars[rnd.nextInt(validChars.length)];
  } while (result.length < length);

  return result;
}

class Transpiler extends DartlangBaseVisitor {
  String _output = "";

  String get output {
    var result = '''
; Compiled from Dart via windart
.386
.model flat, stdcall
option casemap:none

include \\masm32\\include\\windows.inc 
include \\masm32\\include\\kernel32.inc 
includelib \\masm32\\lib\\kernel32.lib 
include \\masm32\\include\\user32.inc 
includelib \\masm32\\lib\\user32.lib

''';

    if (uninitializedSymbols.isNotEmpty || constants.isNotEmpty) {
      result += ".data\n";
      result += constants.join("\n") + "\n";
      uninitializedSymbols.forEach((str) {
        result += "$str dd ?\n";
      });
      result += "\n";
    }

    result += ".code\n";

    return result + _output;
  }

  int indents = 0;
  FunctionSignatureContext winMain;

  Map<String, FunctionSignatureContext> functions = {};
  Map<String, WinApi> importedApis = {};
  Map<String, MasmValue> symbols = {};

  List<String> constants = [];
  List<String> uninitializedSymbols = [];

  String namespace = "";

  void _print(String str) {
    if (str.isEmpty)
      return;

    for (int i = 0; i < indents; i++)
      _output += "    ";
    _output += "$str\n";
  }


  @override
  visitExpressionStatement(ExpressionStatementContext context) {
    var resolver = new MasmResolver(this, context.getExpression());
    resolver.visitExpressionStatement(context);

    if (resolver.value != null)
      _print(resolver.value.before);
    else _print("; NULL RESOLVED EXPRESSION STMT: ${context.text}");
    return super.visitExpressionStatement(context);
  }

  @override
  visitImportSpecification(ImportSpecificationContext context) {
    // Check to see if we were imported 'as' another namespace,
    // so we can still check for 'WinMain'
    String uri = context
        .getUri()
        .getStringLiteral()
        .text;

    if (uri.contains("package:windart/defs.dart")) {
      if (context.getAS() != null) {
        namespace = context
            .getIdentifier()
            .text;
      }
    }

    return super.visitImportSpecification(context);
  }


  @override
  visitInitializedVariableDeclaration(
      InitializedVariableDeclarationContext context) {
    String name = context
        .getDeclaredIdentifier()
        .getIdentifier()
        .text;
    uninitializedSymbols.add(name);

    var resolver = new MasmResolver(this, context.getExpression());
    resolver.visitExpression(context.getExpression());
    if (resolver.value != null) {
      _print(resolver.value.before);
      _print("mov [$name], ${resolver.value.value}");
      symbols[name] = resolver.value;
    } else _print("mov [$name], NULL");

    for (var initializedIdentifier in context.getInitializedIdentifiers()) {
      String varName = initializedIdentifier
          .getIdentifier()
          .text;
      uninitializedSymbols.add(varName);
    }
  }

  @override
  visitTopLevelExternalFunctionDefinition(
      TopLevelExternalFunctionDefinitionContext ctx) {
    var func = ctx.getFunctionSignature();
    var metadata = ctx.getMetadata().getMetadatums();
    for (var metadatum in metadata) {
      String type = metadatum
          .getOfType()
          .text
          .replaceAll(namespace, "");
      if (type == "WinApi") {
        String name = func
            .getIdentifier()
            .text;
        String returnAs = "eax";

        var argumentList = metadatum.getArguments().getArgumentList();
        if (argumentList != null) {
          List<ExpressionContext> args =
          argumentList.getExpressionList().getExpressions();

          if (args.isNotEmpty) {
            MasmString _name = _resolveValue(args[0], this);
            name = _name.text;
          }

          if (args.length > 1) {
            MasmString _returnAs = _resolveValue(args[1], this);
            returnAs = _returnAs.text;
          }
        }

        importedApis[func
            .getIdentifier()
            .text] = new WinApi(name, returnAs);
      }
    }

    return super.visitTopLevelExternalFunctionDefinition(ctx);
  }

  @override
  visitTopLevelFunctionDefinition(TopLevelFunctionDefinitionContext ctx) {
    var context = ctx.getFunctionSignature();
    var metadata = context.getMetadata().getMetadatums();
    for (var metadatum in metadata) {
      String type = metadatum
          .getOfType()
          .text
          .replaceAll(namespace, "");
      if (type == "WinMain" && winMain == null) {
        winMain = context;
        break;
      }
    }

    if (context != winMain) {
      _print("${context
          .getIdentifier()
          .text} proc");
    } else {
      _print("${context
          .getIdentifier()
          .text}:");
    }

    indents++;
    var result = super.visitTopLevelFunctionDefinition(ctx);
    indents--;
    if (context != winMain) {
      _print("${context
          .getIdentifier()
          .text} endp");
    } else {
      _print("end ${context
          .getIdentifier()
          .text}");
    }

    return result;
  }
}

DartlangParser makeParser(String input) {
  var source = new StringSource(input);
  var lexer = new DartlangLexer(source);
  return new DartlangParser(new CommonTokenSource(lexer));
}

Transpiler parse(String input) {
  var parser = makeParser(input);
  var transpiler = new Transpiler();
  transpiler.visitCompilationUnit(parser.compilationUnit());
  return transpiler;
}
