import 'package:barback/barback.dart';
import 'src/transpiler.dart';

class WindartTransformer extends Transformer {
  @override
  String get allowedExtensions => ".dart";

  WindartTransformer.asPlugin();

  @override
  apply(Transform transform) async {
    transform.consumePrimary();
    Asset asset = transform.primaryInput;
    Transpiler transpiler = parse(await asset.readAsString());
    transform.addOutput(new Asset.fromString(asset.id, "// :)"));
    transform.addOutput(new Asset.fromString(
        asset.id.changeExtension(".asm"), transpiler.output));
  }
}