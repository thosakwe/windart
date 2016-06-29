part of windart.src.transpiler;

class MasmValue {
  ExpressionContext source;
  String before = "";
  var value;

  MasmValue({ExpressionContext this.source, this.value: "NULL"});
}

class MasmString extends MasmValue {
  String text;

  MasmString(String this.text, {ExpressionContext source}):super(source: source);
}