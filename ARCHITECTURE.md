# maxi_proto_framework Architecture Guide

## Overview

`maxi_proto_framework` is the transport layer package for the Maxi ecosystem.

Its job is narrow and explicit:

- define the protobuf contract in a single `.proto` file
- generate Dart protobuf and gRPC code from that contract
- expose generated transport types as package API
- adapt `maxi_framework` domain objects to transport messages and back

The package does not implement application business logic. It defines how that logic crosses a process or network boundary.

## Design Goals

1. Keep transport contracts explicit and versionable through protobuf
2. Reuse the `Result<T>` and `Oration` model from `maxi_framework`
3. Minimize handwritten transport code to a small adapter layer
4. Make generated files first-class API, not hidden implementation details
5. Support both unary gRPC operations and plain protobuf serialization use cases

## Architecture Layers

```text
┌───────────────────────────────────────────────┐
│ Application / Service Code                    │
│ Uses maxi_framework domain types              │
│ - Oration                                     │
│ - Result<T> / NegativeResult                  │
└───────────────────────┬───────────────────────┘
                        │
┌───────────────────────▼───────────────────────┐
│ Adapter Layer                                 │
│ Handwritten mapping between domain and proto  │
│ - OrationToProto                              │
│ - NegativeResultToProto                       │
│ - AdapterProtoToOration                       │
│ - AdapterProtoToNegativeResult                │
└───────────────────────┬───────────────────────┘
                        │
┌───────────────────────▼───────────────────────┐
│ Generated Transport Layer                     │
│ Protobuf messages and gRPC stubs              │
│ - ProtoOration                                │
│ - ProtoNegativeResult                         │
│ - ProtoResult / ProtoVoidResult               │
│ - ProtoAppStatus                              │
│ - MaxiAppClient / MaxiAppServiceBase          │
└───────────────────────┬───────────────────────┘
                        │
┌───────────────────────▼───────────────────────┐
│ Schema Layer                                  │
│ lib/src/protos/maxi_proto.proto               │
│ - messages                                    │
│ - service                                     │
│ - custom protobuf options                     │
└───────────────────────────────────────────────┘
```

## Main Modules

### 1. Schema module

Source: `lib/src/protos/maxi_proto.proto`

This file is the source of truth for:

- transport messages
- `MaxiApp` RPC methods
- protobuf custom options for Dart metadata

This package keeps the schema centralized so the generated artifacts and handwritten adapters evolve from a single contract.

### 2. Generated module

Source directory: `lib/src/generated/`

Generated files include:

- `maxi_proto.pb.dart`: protobuf message classes and extension registration
- `maxi_proto.pbgrpc.dart`: gRPC client and service base classes
- `maxi_proto.pbenum.dart`: generated enums
- `maxi_proto.pbjson.dart`: JSON descriptors

These files are exported directly from the package entrypoint. That means consumers can work with the generated protobuf types without importing internal paths.

### 3. Adapter and converter module

Sources:

- `lib/src/converters/oration_to_proto.dart`
- `lib/src/converters/negative_result_to_proto.dart`
- `lib/src/adapters/adapter_proto_to_oration.dart`
- `lib/src/adapters/adapter_proto_to_negative_result.dart`

This layer exists because the domain model from `maxi_framework` is not the same thing as the transport model. The conversion layer provides a stable boundary:

- domain `Oration` -> `ProtoOration`
- domain failure `Result` -> `ProtoNegativeResult`
- `ProtoOration` -> domain `Oration`
- `ProtoNegativeResult` -> domain `NegativeResult`

Every conversion returns `Result<T>`, which keeps error handling aligned with the rest of the Maxi stack.

## Transport Model

### Oration flow

```text
maxi_framework.Oration
    └─ OrationToProto.execute()
       └─ ProtoOration

ProtoOration
    └─ AdapterProtoToOration.execute()
       └─ maxi_framework.Oration
```

`ProtoOration` is the wire representation of a user-facing or tokenized message:

- `tokenId`: logical message key
- `text`: base text or resolved message
- `textParts`: variable parts used in flexible messages

### Error flow

```text
Result / NegativeResult
    └─ NegativeResultToProto.execute()
       └─ ProtoNegativeResult

ProtoNegativeResult
    └─ AdapterProtoToNegativeResult.execute()
       └─ NegativeResult
```

This preserves:

- framework error code index
- human-readable message payload

The reverse adapter validates the incoming error code and falls back to `ErrorCode.invalidValue` when the transport payload is outside the valid enum range.

### RPC result flow

The schema separates general successful payloads and failures:

- `ProtoResult`: success flag plus `Any` or `ProtoNegativeResult`
- `ProtoVoidResult`: success flag plus `Empty` or `ProtoNegativeResult`

This design allows service methods to return either data or structured failure information without relying on thrown exceptions as the main transport mechanism.

## gRPC Service Structure

The generated service surface is based on the `MaxiApp` service declared in the proto schema.

Unary methods:

- `Initialize(Empty) -> ProtoResult`
- `GetStatus(Empty) -> ProtoAppStatus`

Generated roles:

- `MaxiAppClient`: client-side stub used to call the service
- `MaxiAppServiceBase`: abstract server-side base class to implement

This keeps network transport separate from the application runtime. Service implementations can stay in another package while this package owns the contract.

## Custom Protobuf Options

The schema also defines protobuf extensions for Dart-oriented metadata:

- field options: `dart_decorator`, `dart_field`
- message options: `dart_class`
- enum options: `dart_enum`
- enum value options: `dart_enum_value`

These options are useful for code generation or descriptor-driven tooling. They are part of the generated API through the `Maxi_proto.registerAllExtensions(...)` entrypoint.

## Generation Pipeline

Source script: `scripts/generate.sh`

Generation steps:

1. add the local pub global binary path to `PATH`
2. activate `protoc_plugin`
3. remove the previous `lib/src/generated` directory
4. recreate the target directory
5. run `protoc --dart_out=grpc:lib/src/generated ...`

This pipeline treats generated files as build artifacts derived from the schema, not hand-maintained source files.

## Dependency Direction

```text
maxi_framework
    ▲
    │
maxi_proto_framework
    │
    ├─ depends on protobuf
    └─ depends on grpc
```

Important constraint:

- `maxi_proto_framework` depends on `maxi_framework` for domain conversions
- `maxi_framework` does not depend on this package

That keeps the core domain package transport-agnostic.

## Testing Strategy

Current tests exercise descriptor and option behavior and validate generated message metadata usage.

The most important package-level tests should continue to cover:

- domain-to-proto conversions
- proto-to-domain conversions
- invalid transport payload handling
- descriptor option parsing for custom protobuf options

## Extension Points

The package can grow in three controlled ways:

1. Extend `maxi_proto.proto` with new messages or RPC methods
2. Add new handwritten adapters for additional `maxi_framework` domain types
3. Use custom protobuf options to drive reflection or code generation tooling

The design should stay centered on a single rule: schema first, adapters second, business logic elsewhere.