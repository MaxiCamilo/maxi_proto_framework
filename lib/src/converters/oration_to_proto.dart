import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

class OrationToProto implements SyncFunctionality<ProtoOration> {
  final Oration oration;

  const OrationToProto({required this.oration});

  @override
  Result<ProtoOration> execute() {
    return ProtoOration(text: oration.message, tokenId: oration.tokenID, textParts: oration.textParts.map((x) => x.toString()).toList()).asResultValue();
  }
}

extension OrationToProtoExtension on Oration {
  Result<ProtoOration> toProto() {
    return OrationToProto(oration: this).execute();
  }
}
