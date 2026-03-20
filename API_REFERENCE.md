# maxi_proto_framework API Reference

Complete API reference for the public surface of `maxi_proto_framework`.

## Table of Contents

- [Library Entry Point](#library-entry-point)
- [Generated Message Types](#generated-message-types)
- [gRPC Service Types](#grpc-service-types)
- [Conversion Helpers](#conversion-helpers)
- [Custom Option Types](#custom-option-types)
- [Well-Known Type Re-exports](#well-known-type-re-exports)
- [Generation Script](#generation-script)

## Library Entry Point

Import the package with:

```dart
import 'package:maxi_proto_framework/maxi_proto_framework.dart';
```

The entry point exports:

- generated protobuf classes
- generated gRPC client/server base classes
- `Any` and `Empty` well-known types
- handwritten converter and adapter extensions

## Generated Message Types

### ProtoOration

Wire representation of a Maxi `Oration`.

```dart
ProtoOration({
  String? tokenId,
  String? text,
  Iterable<String>? textParts,
})
```

Fields:

- `tokenId`: logical message or token identifier
- `text`: resolved or base text
- `textParts`: positional message fragments or interpolation values

Common usage:

```dart
final message = ProtoOration(
  tokenId: 'printer.ready',
  text: 'Ready',
  textParts: ['A1'],
);
```

### ProtoNegativeResult

Transport representation of a framework failure.

```dart
ProtoNegativeResult({
  int? errorCode,
  ProtoOration? message,
})
```

Fields:

- `errorCode`: numeric index of the framework error code
- `message`: structured transport message for the failure

### ProtoResult

Generic RPC result container for non-void content.

```dart
ProtoResult({
  bool? itsCorrect,
  Any? content,
  ProtoNegativeResult? error,
})
```

Fields:

- `itsCorrect`: success flag
- `content`: success payload wrapped in `google.protobuf.Any`
- `error`: failure payload when the request was not successful

Oneof helpers:

- `whichValue()`
- `clearValue()`

Behavior notes:

- only one of `content` or `error` should be set
- use `Any.pack(...)` and `Any.unpackInto(...)` patterns when transporting typed payloads

### ProtoVoidResult

RPC result container for operations whose success path has no payload.

```dart
ProtoVoidResult({
  bool? itsCorrect,
  Empty? content,
  ProtoNegativeResult? error,
})
```

Fields:

- `itsCorrect`: success flag
- `content`: typically an `Empty` message for success
- `error`: failure payload

Oneof helpers:

- `whichValue()`
- `clearValue()`

### ProtoAppStatus

Transport view of application lifecycle state.

```dart
ProtoAppStatus({
  String? name,
  double? version,
  bool? isEnable,
  bool? isInitialized_4,
  ProtoNegativeResult? lastInitError,
})
```

Fields:

- `name`: application name
- `version`: application version number
- `isEnable`: whether the app is enabled
- `isInitialized_4`: whether initialization already ran successfully
- `lastInitError`: last initialization failure, if present

Note:

- the generated field name `isInitialized_4` comes from code generation conflict handling around the original proto field name `is_initialized`

## gRPC Service Types

### MaxiAppClient

Generated gRPC client for the `MaxiApp` service.

```dart
MaxiAppClient(
  ClientChannel channel, {
  CallOptions? options,
  List<ClientInterceptor>? interceptors,
})
```

Methods:

#### initialize()

```dart
ResponseFuture<ProtoResult> initialize(
  Empty request, {
  CallOptions? options,
})
```

Calls the `Initialize` RPC.

#### getStatus()

```dart
ResponseFuture<ProtoAppStatus> getStatus(
  Empty request, {
  CallOptions? options,
})
```

Calls the `GetStatus` RPC.

### MaxiAppServiceBase

Abstract gRPC server base class for the `MaxiApp` service.

```dart
abstract class MaxiAppServiceBase extends Service {
  Future<ProtoResult> initialize(ServiceCall call, Empty request);
  Future<ProtoAppStatus> getStatus(ServiceCall call, Empty request);
}
```

Override these methods in your server implementation.

Example:

```dart
class AppService extends MaxiAppServiceBase {
  @override
  Future<ProtoResult> initialize(ServiceCall call, Empty request) async {
    return ProtoResult(itsCorrect: true, content: Any());
  }

  @override
  Future<ProtoAppStatus> getStatus(ServiceCall call, Empty request) async {
    return ProtoAppStatus(
      name: 'printer',
      version: 1.0,
      isEnable: true,
      isInitialized_4: true,
    );
  }
}
```

## Conversion Helpers

The package provides a small handwritten adapter layer on top of the generated code.

### OrationToProto

```dart
class OrationToProto implements SyncFunctionality<ProtoOration> {
  const OrationToProto({required Oration oration});
  Result<ProtoOration> execute();
}
```

Purpose:

- converts a `maxi_framework` `Oration` into `ProtoOration`

Extension:

```dart
extension OrationToProtoExtension on Oration {
  Result<ProtoOration> toProto();
}
```

### NegativeResultToProto

```dart
class NegativeResultToProto implements SyncFunctionality<ProtoNegativeResult> {
  const NegativeResultToProto({required Result negativeResult});
  Result<ProtoNegativeResult> execute();
}
```

Purpose:

- converts a failing framework `Result` into `ProtoNegativeResult`

Extension:

```dart
extension NegativeResultToProtoExtension on Result {
  Result<ProtoNegativeResult> toProtoError();
}
```

Important note:

- this API expects a failure-oriented `Result`; it reads `negativeResult.error`

### AdapterProtoToOration

```dart
class AdapterProtoToOration implements SyncFunctionality<Oration> {
  const AdapterProtoToOration({required ProtoOration protoOration});
  Result<Oration> execute();
}
```

Purpose:

- converts `ProtoOration` into either `FixedOration` or `FlexibleOration`

Behavior:

- when `textParts` is empty, it returns `FixedOration`
- when `textParts` is present, it returns `FlexibleOration`

Extension:

```dart
extension AdapterProtoToOrationExtension on ProtoOration {
  Result<Oration> toOration();
}
```

### AdapterProtoToNegativeResult

```dart
class AdapterProtoToNegativeResult
    implements SyncFunctionality<NegativeResult> {
  const AdapterProtoToNegativeResult({
    required ProtoNegativeResult protoNegativeResult,
  });

  Result<NegativeResult> execute();
}
```

Purpose:

- converts a transport failure back into a framework `NegativeResult`

Behavior:

- converts `message` with `ProtoOration.toOration()`
- validates the incoming numeric error code
- returns `ErrorCode.invalidValue` when the payload contains an out-of-range code

Extension:

```dart
extension AdapterProtoToNegativeResultExtension on ProtoNegativeResult {
  Result<NegativeResult> toNegativeResult();
}
```

## Custom Option Types

The proto schema includes message types and extension declarations used to annotate descriptors with Dart metadata.

### ProtoDartDecorator

```dart
ProtoDartDecorator({
  Iterable<String>? dartDecorators,
})
```

Represents a list of Dart decorators.

### ProtoDartClass

```dart
ProtoDartClass({
  String? name,
  String? dartType,
  Iterable<ProtoDartDecorator>? decorators,
})
```

Represents message-level metadata for a Dart class.

### ProtoDartField

```dart
ProtoDartField({
  String? name,
  String? dartType,
  Iterable<ProtoDartDecorator>? decorators,
})
```

Represents field-level metadata for a Dart field.

### ProtoDartEnum

```dart
ProtoDartEnum({
  String? name,
  String? prefix,
  String? dartType,
  Iterable<ProtoDartDecorator>? decorators,
})
```

Represents enum-level metadata.

### ProtoDartEnumValue

```dart
ProtoDartEnumValue({
  String? name,
  int? number,
  Iterable<ProtoDartDecorator>? decorators,
})
```

Represents enum value metadata.

### Maxi_proto.registerAllExtensions()

```dart
static void registerAllExtensions(ExtensionRegistry registry)
```

Registers all protobuf custom options declared by this package:

- `dartDecorator`
- `dartField`
- `dartClass`
- `dartEnum`
- `dartEnumValue`

Use this when parsing descriptors or messages that rely on the custom extension registry.

## Well-Known Type Re-exports

The package re-exports:

- `google.protobuf.Any`
- `google.protobuf.Empty`

This keeps client code simpler because consumers do not need separate imports for the most common protobuf utility types used by the service contract.

## Generation Script

The package includes a helper script:

```bash
./scripts/generate.sh
```

Responsibilities:

- activate `protoc_plugin`
- recreate `lib/src/generated`
- regenerate protobuf and gRPC Dart sources from `lib/src/protos/maxi_proto.proto`

Operational notes:

- `protoc` must be installed on the machine
- generated files should not be edited manually
- schema changes belong in the `.proto` file, then the generator should be rerun