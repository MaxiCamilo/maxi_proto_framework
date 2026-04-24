import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';
import 'package:test/test.dart';

void main() {
  group('AppStatus adapters', () {
    test('converts ProtoAppStatus to AppStatus', () {
      final proto = ProtoAppStatus(
        name: 'Scale API',
        version: 1.5,
        isEnable: true,
        isInitialized_4: false,
        lastInitError: ProtoNegativeResult(
          errorCode: ErrorCode.invalidValue.index,
          message: ProtoOration(text: 'Init failed'),
        ),
      );

      final result = proto.toNative();

      expect(result.itsCorrect, isTrue);
      expect(result.content.name, 'Scale API');
      expect(result.content.version, 1.5);
      expect(result.content.isEnable, isTrue);
      expect(result.content.isInitialized, isFalse);
      expect(result.content.lastInitError.error.errorCode, ErrorCode.invalidValue);
      expect(result.content.lastInitError.error.message.message, 'Init failed');
    });

    test('converts AppStatus to ProtoAppStatus', () {
      final appStatus = AppStatus()
        ..name = 'Receiver'
        ..version = 2.0
        ..isEnable = false
        ..isInitialized = true
        ..lastInitError = NegativeResult.controller(
          code: ErrorCode.uninitializedFunctionality,
          message: const FixedOration(message: 'Pending setup'),
        );

      final result = appStatus.toProto();

      expect(result.itsCorrect, isTrue);
      expect(result.content.name, 'Receiver');
      expect(result.content.version, 2.0);
      expect(result.content.isEnable, isFalse);
      expect(result.content.isInitialized_4, isTrue);
      expect(result.content.lastInitError.errorCode, ErrorCode.uninitializedFunctionality.index);
      expect(result.content.lastInitError.message.text, 'Pending setup');
    });
  });
}
