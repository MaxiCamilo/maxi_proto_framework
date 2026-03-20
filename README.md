# maxi_proto_framework

`maxi_proto_framework` is the protobuf and gRPC bridge for the Maxi ecosystem.

It packages the generated protocol types used by the framework, exposes the `MaxiApp` gRPC service contract, and provides adapters that convert between protobuf messages and the domain types defined in `maxi_framework`.

## What this package provides

- Generated protobuf models such as `ProtoOration`, `ProtoNegativeResult`, `ProtoResult`, `ProtoVoidResult`, and `ProtoAppStatus`
- Generated gRPC client and server base types for the `MaxiApp` service
- Re-exports for `google.protobuf.Any` and `google.protobuf.Empty`
- Conversion helpers between protobuf messages and Maxi framework domain objects
- The source `.proto` schema and a generation script for regenerating Dart files

## Documentation

- `README.md`: package overview and quick start
- `ARCHITECTURE.md`: internal structure, message flow, and generation pipeline
- `API_REFERENCE.md`: exported messages, services, and conversion helpers

## Public API

Import the package with:

```dart
import 'package:maxi_proto_framework/maxi_proto_framework.dart';
```

This exports:

- Generated files:
	- `maxi_proto.pb.dart`
	- `maxi_proto.pbenum.dart`
	- `maxi_proto.pbgrpc.dart`
	- `maxi_proto.pbjson.dart`
- Well-known protobuf types:
	- `Any`
	- `Empty`
- Converter and adapter extensions:
	- `Oration.toProto()`
	- `Result.toProtoError()`
	- `ProtoOration.toOration()`
	- `ProtoNegativeResult.toNegativeResult()`

## Core protocol model

The schema in `lib/src/protos/maxi_proto.proto` defines a compact transport contract for app initialization and status reporting.

Main messages:

- `ProtoOration`: text payload with `tokenId`, `text`, and `textParts`
- `ProtoNegativeResult`: framework error code plus message
- `ProtoResult`: success flag and either `Any` content or `ProtoNegativeResult` error
- `ProtoVoidResult`: success flag and either `Empty` content or `ProtoNegativeResult` error
- `ProtoAppStatus`: app identity, version, state, and last initialization error

Main service:

- `MaxiApp.Initialize(Empty) -> ProtoResult`
- `MaxiApp.GetStatus(Empty) -> ProtoAppStatus`

## Installation

This package is currently configured as a local workspace package (`publish_to: none`).

Add it to `pubspec.yaml`:

```yaml
dependencies:
	maxi_proto_framework:
		path: ../maxi_proto_framework
```

If your project uses the domain conversions, include `maxi_framework` as well.

Then run:

```bash
dart pub get
```

## Usage

### Convert a framework `Oration` to protobuf

```dart
import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

final message = const FixedOration(
	tokenID: 'app.version',
	message: 'Version ready',
);

final protoResult = message.toProto();

if (protoResult.itsCorrect) {
	final proto = protoResult.content;
	print(proto.tokenId);
	print(proto.text);
}
```

### Convert a protobuf message back to a framework `Oration`

```dart
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

final proto = ProtoOration(
	tokenId: 'printer.status',
	text: 'Ready',
	textParts: ['A1'],
);

final result = proto.toOration();

if (result.itsCorrect) {
	final oration = result.content;
	print(oration.message);
}
```

### Serialize framework failures for transport

```dart
import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_proto_framework/maxi_proto_framework.dart';

final failure = NegativeResult.controller(
	code: ErrorCode.invalidValue,
	message: const FixedOration(message: 'Invalid configuration'),
);

final protoFailure = failure.toProtoError();

if (protoFailure.itsCorrect) {
	print(protoFailure.content.errorCode);
}
```

## Regenerating protobuf and gRPC files

The repository includes `scripts/generate.sh` to rebuild generated sources.

The script:

- activates `protoc_plugin`
- clears `lib/src/generated`
- runs `protoc` with gRPC Dart output enabled

Run it from the package directory:

```bash
./scripts/generate.sh
```

Before running it, make sure `protoc` is installed and available on your system.

## Project structure

```text
lib/
	maxi_proto_framework.dart
	src/
		adapters/
		converters/
		generated/
		protos/
scripts/
	generate.sh
test/
	logic/
	maxi_proto_framework_test.dart
```

## Notes

- Generated files are part of the public API of this package.
- Conversion helpers return `Result<T>` values to stay aligned with `maxi_framework` error handling.
- The schema also defines protobuf custom options for Dart-related metadata, which can be extended in future tooling.

