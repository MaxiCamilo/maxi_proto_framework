import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/src/converters/oration_to_proto.dart';
import 'package:maxi_proto_framework/src/generated/maxi_proto.pbgrpc.dart';

class NegativeResultToProto implements SyncFunctionality<ProtoNegativeResult> {
  final Result negativeResult;

  const NegativeResultToProto({required this.negativeResult});

  @override
  Result<ProtoNegativeResult> execute() {
    final oration = OrationToProto(oration: negativeResult.error.message).execute();
    if (oration.itsFailure) {
      return oration.cast();
    }

    return ProtoNegativeResult(errorCode: negativeResult.error.errorCode.index, message: oration.content).asResultValue();
  }
}

extension NegativeResultToProtoExtension on Result {
  Result<ProtoNegativeResult> toProto() {
    return NegativeResultToProto(negativeResult: this).execute();
  }
}
