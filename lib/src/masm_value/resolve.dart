part of windart.src.transpiler;

MasmValue _resolveValue(ExpressionContext ctx, Transpiler transpiler) {
  // VERY DIRTY, only works for strings, ints
  String text = ctx.text
      .replaceAll(new RegExp("^('''|\"|')"), "")
      .replaceAll(new RegExp("('''|\"|')\$"), "");

  try {
    var n = num.parse(text);
    return new MasmValue(source: ctx, value: n);
  } catch(e) {}

  return new MasmString(text, source: ctx);
}
