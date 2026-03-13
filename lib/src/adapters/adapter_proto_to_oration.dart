import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

class AdapterProtoToOration implements SyncFunctionality<Oration> {
  final ProtoOration protoOration;

  const AdapterProtoToOration({required this.protoOration});

  @override
  Result<Oration> execute() {
    final textParts = protoOration.textParts.toList(growable: false);
    if (textParts.isEmpty) {
      return FixedOration(message: protoOration.text, tokenID: protoOration.tokenId).asResultValue();
    } else {
      return FlexibleOration(message: protoOration.text, textParts: textParts, tokenID: protoOration.tokenId).asResultValue();
    }
  }
}

extension AdapterProtoToOrationExtension on ProtoOration {
  Result<Oration> toOration() {
    return AdapterProtoToOration(protoOration: this).execute();
  }
}
