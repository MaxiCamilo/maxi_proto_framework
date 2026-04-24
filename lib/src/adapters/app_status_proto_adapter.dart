import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';
import 'package:maxi_proto_framework/src/models/app_status.dart';

class ProtoAppStatusAdapter implements SyncFunctionality<AppStatus> {
  final ProtoAppStatus protoAppStatus;

  const ProtoAppStatusAdapter({required this.protoAppStatus});

  @override
  Result<AppStatus> execute() {
    final appStatus = AppStatus()
      ..name = protoAppStatus.name
      ..version = protoAppStatus.version
      ..isEnable = protoAppStatus.isEnable
      ..isInitialized = protoAppStatus.isInitialized_4;

    if (protoAppStatus.hasLastInitError()) {
      final lastInitError = protoAppStatus.lastInitError.toNegativeResult();
      if (lastInitError.itsFailure) {
        return lastInitError.cast();
      }

      appStatus.lastInitError = lastInitError.content;
    }

    return appStatus.asResultValue();
  }
}

extension ProtoAppStatusAdapterExtension on ProtoAppStatus {
  Result<AppStatus> toNative() {
    return ProtoAppStatusAdapter(protoAppStatus: this).execute();
  }
}

class AppStatusProtoAdapter implements SyncFunctionality<ProtoAppStatus> {
  final AppStatus appStatus;

  const AppStatusProtoAdapter({required this.appStatus});

  @override
  Result<ProtoAppStatus> execute() {
    final lastInitError = appStatus.lastInitError.toProtoError();
    if (lastInitError.itsFailure) {
      return lastInitError.cast();
    }

    return ProtoAppStatus(name: appStatus.name, version: appStatus.version, isEnable: appStatus.isEnable, isInitialized_4: appStatus.isInitialized, lastInitError: lastInitError.content).asResultValue();
  }
}

extension AppStatusProtoAdapterExtension on AppStatus {
  Result<ProtoAppStatus> toProto() {
    return AppStatusProtoAdapter(appStatus: this).execute();
  }
}
