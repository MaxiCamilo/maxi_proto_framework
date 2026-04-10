// ignore: implementation_imports
import 'package:grpc/src/server/handler.dart';
import 'dart:async';

import 'package:grpc/service_api.dart';

import 'package:maxi_framework/maxi_framework.dart';

class CheckCancelServiceCall with DisposableMixin {
  final ServiceCall call;

  final _cancellationCompleter = Completer<bool>();

  CheckCancelServiceCall(this.call, Disposable? parent) {
    if (call is ServerHandler) {
      (call as ServerHandler).onCanceled.whenComplete(() {
        if (!_cancellationCompleter.isCompleted) {
          _cancellationCompleter.complete(true);
        }

        if (parent != null) {
          parent.dispose();
        }
        dispose();
      });
    }

    if (parent != null) {
      parent.onDispose.whenComplete(dispose);
    }
  }

  Future<bool> get onCancelOrDispose {
    return _cancellationCompleter.future;
  }

  @override
  void performObjectDiscard() {
    if (!_cancellationCompleter.isCompleted) {
      _cancellationCompleter.complete(false);
    }
  }
}
