import 'package:maxi_framework/maxi_framework.dart';

class AppStatus {
  String name = '';
  double version = 0;
  bool isEnable = false;
  bool isInitialized = false;
  NegativeResult lastInitError = NegativeResult.controller(
    code: ErrorCode.implementationFailure,
    message: const FixedOration(message: 'App is not initialized'),
  );
}
