import 'dart:async';

import 'package:grpc/service_api.dart';
import 'package:maxi_framework/maxi_framework.dart';

extension FutureProtoResultExtensions<T> on FutureResult<T> {
  FutureResult<T> checkClientCancelation({required ServiceCall call, Duration ticks = const Duration(milliseconds: 100)}) async {
    if (!LifeCoordinator.hasZoneHeart) {
      return LifeCoordinator.runWithSeparateZone(() => checkClientCancelation(call: call, ticks: ticks));
    }

    if (call.isCanceled) return CancelationResult<T>();

    final executor = AsyncExecutor(function: () async => await this, connectToZone: true);

    final timer = Timer.periodic(ticks, (timer) {
      if (call.isCanceled) {
        timer.cancel();
        executor.dispose();
      }
    });

    final result = await executor.waitResult();
    timer.cancel();
    return result;
  }
}
