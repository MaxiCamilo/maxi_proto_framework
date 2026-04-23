import 'dart:io';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';
import 'package:http2/http2.dart' as http2;
import 'package:maxi_framework/maxi_framework.dart';

class GrpcUnixSocketServer with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub {
  final String address;

  final List<Service> services;
  final ServerKeepAliveOptions keepAliveOptions;

  late Server _serverInstance;

  GrpcUnixSocketServer({required this.address, required this.services, this.keepAliveOptions = const ServerKeepAliveOptions(minIntervalBetweenPingsWithoutData: Duration(seconds: 15), maxBadPings: 3)});

  @override
  Future<Result<void>> performInitialize() async {
    final address = appManager.isWindows && this.address.startsWith('/tmp/') ? '%TEMP%/${this.address.extractFrom(since: 5)}' : this.address;

    final previousSocketFile = File(address);
    final existsResult = await previousSocketFile.exists().toFutureResult();
    if (existsResult.itsFailure) {
      return existsResult.cast();
    }
    if (existsResult.content) {
      //⨻⟴
      print('⟁ Warning: Socket file $address already exists. It will be deleted to create the grpc server.');
      final deleteResult = await previousSocketFile.delete().toFutureResult();
      if (deleteResult.itsFailure) {
        return NegativeResult.controller(
          code: ErrorCode.externalFault,
          message: FlexibleOration(message: 'Failed to delete existing socket file in %1: %2', textParts: [address, deleteResult.error.message]),
        );
      }
    }

    _serverInstance = Server.create(services: services, keepAliveOptions: keepAliveOptions);
    onDispose.whenComplete(() => _serverInstance.shutdown());

    if (appManager.isWindows) {
      final winSocketResult = WinUnixSocketServer.buildServer(address);
      if (winSocketResult.itsFailure) {
        return winSocketResult.cast();
      }
      final winSocket = winSocketResult.content;
      lifecycleScope.joinDisposableObject(winSocket);
      final initResult = await winSocket.initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }

      winSocket.newClient.listen(_onNewClient);
    } else {
      final initResult = await _serverInstance.serve(address: InternetAddress(address, type: InternetAddressType.unix), port: 0).toFutureResult();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    }

    return voidResult;
  }

  Future<void> _onNewClient(Channel<Uint8List, Uint8List> channel) async {
    final transport = http2.ServerTransportConnection.viaStreams(channel.getReceiver().content, channel.toSink());
    final connectionResult = await _serverInstance.serveConnection(connection: transport).toFutureResult().logIfFails(errorName: 'Error serving grpc connection');
    if (connectionResult.itsCorrect) {
      lifecycleScope.joinManualDisposableObject(transport, onDisponse: (_) => transport.finish());
    }
  }
}
