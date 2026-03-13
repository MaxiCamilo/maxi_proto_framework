import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

class AdapterProtoToNegativeResult implements SyncFunctionality<NegativeResult> {
  final ProtoNegativeResult protoNegativeResult;

  const AdapterProtoToNegativeResult({required this.protoNegativeResult});

  @override
  Result<NegativeResult> execute() {
    final message = protoNegativeResult.message.toOration();
    if (message.itsFailure) {
      return message.cast();
    }

    if (protoNegativeResult.errorCode < 0 || protoNegativeResult.errorCode >= ErrorCode.values.length) {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: const FixedOration(message: 'Invalid error code in ProtoNegativeResult'),
      ).asResultValue();
    }

    return NegativeResult.controller(code: ErrorCode.values[protoNegativeResult.errorCode], message: message.content).asResultValue();
  }
}

extension AdapterProtoToNegativeResultExtension on ProtoNegativeResult {
  Result<NegativeResult> toNegativeResult() {
    return AdapterProtoToNegativeResult(protoNegativeResult: this).execute();
  }
}
