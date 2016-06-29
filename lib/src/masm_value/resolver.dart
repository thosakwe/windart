part of windart.src.transpiler;

class MasmResolver extends DartlangBaseVisitor<MasmValue> {
  Transpiler transpiler;
  MasmValue value;
  ExpressionContext expr;
  bool _hasMinus = false;

  MasmResolver(Transpiler this.transpiler, ExpressionContext this.expr);


  @override
  visitIdentifier(IdentifierContext context) {
    value = new MasmValue(source: expr, value: context.text);
  }

  @override
  visitNumericLiteral(NumericLiteralContext context) {
    String numText = context.text;

    if (_hasMinus)
      numText = "-$numText";

    value = new MasmValue(source: expr, value: num.parse(numText));
  }

  @override
  visitPostfixExpression(PostfixExpressionContext context) {
    var primary = context.getPrimary();

    if (primary != null) {
      // If primary is ID
      String name = primary.text;

      var selectors = context.getSelectors();

      if (selectors.length == 1) {
        var firstSelector = selectors[0];
        if (firstSelector.getArguments() != null) {
          // This is a function call
          value = new MasmValue(source: expr)
            ..value = "eax";
          WinApi importedApi = transpiler.importedApis[name];

          if (importedApi != null) {
            name = importedApi.name;
            value.value = importedApi.returnAs;
          }

          value.before += "invoke $name, ";

          var argumentList = firstSelector.getArguments().getArgumentList();
          if (argumentList != null) {
            var expressionList = argumentList.getExpressionList();
            if (expressionList != null) {
              int i = 0;
              for (var expression in expressionList.getExpressions()) {
                if (i > 0)
                  value.before += ", ";

                var resolver = new MasmResolver(transpiler, expression)
                  ..visitExpression(expression);
                if (resolver.value != null) {
                  value.before += resolver.value.before;
                  value.before += resolver.value.value.toString();
                }
                else value.before += "NULL";
                i++;
              }
            }

            // TODO: Named parameters
          }
          return null;
        } else {
          // This is an ID
          value = new MasmValue(source: expr, value: primary
              .getIdentifier()
              .text);
        }
      }
    }

    return super.visitPostfixExpression(context);
  }

  @override
  MasmValue visitPrefixOperator(PrefixOperatorContext context) {
    if (context.getMinusOperator() != null)
      _hasMinus = true;
    return super.visitPrefixOperator(context);
  }


  @override
  visitNullLiteral(NullLiteralContext context) {
    value = new MasmValue(source: expr, value: "NULL");
  }

  @override
  visitStringLiteral(StringLiteralContext context) {
    String text = context.text.replaceAll(new RegExp("^('''|\"|')"), "")
        .replaceAll(new RegExp("('''|\"|')\$"), "");
    value = new MasmString(text, source: expr);
    String id = "str_${_randomString()}";
    transpiler.constants.add("$id db \"$text\", 0");
    value..value = "addr $id";
  }

  @override
  MasmValue visitUnaryExpression(UnaryExpressionContext context) {
    if (!_hasMinus)
      _hasMinus = context.text.startsWith("-");

    return super.visitUnaryExpression(context);
  }


}