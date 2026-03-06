// proto_options_dynamic.dart
//
// Lee TODAS las custom options de cualquier mensaje protobuf
// de forma dinámica — sin conocer previamente los nombres ni
// los tagNumbers de las options.
//
// Resultado: Map<fieldName, Map<tagNumber, dynamic>>
//
// Uso:
//   final opts = DynamicOptionsReader.parse(protoOrationDescriptor);
//   opts['token_id']?[50001]  // → "Nombre de app"
//   opts['token_id']?[50002]  // → true
//   opts['message']?[50003]   // → "Prueba"

import 'dart:typed_data';
import 'package:protobuf/protobuf.dart';

// ═══════════════════════════════════════════════════════════════
//  Tipos
// ═══════════════════════════════════════════════════════════════

/// Options de un campo: Map&lt;tagNumber, valor&gt;
/// El valor puede ser String, bool, int o List&lt;int&gt; (bytes)
typedef FieldOptions = Map<int, dynamic>;

/// Resultado del parsing: Map&lt;fieldName, FieldOptions&gt;
typedef MessageOptions = Map<String, FieldOptions>;

// ═══════════════════════════════════════════════════════════════
//  DynamicOptionsReader
// ═══════════════════════════════════════════════════════════════

class DynamicOptionsReader {
  DynamicOptionsReader(Uint8List descriptor) : _data = _parse(descriptor);

  final MessageOptions _data;

  // ── Acceso ───────────────────────────────────────────────────

  /// Options de un campo por nombre (snake_case)
  FieldOptions? operator [](String fieldName) => _data[fieldName];

  /// Options de un campo por tagNumber del campo
  FieldOptions? byTag(int fieldTag) => _data.values.firstWhere((opts) => opts.containsKey(fieldTag), orElse: () => {});

  /// Todos los campos con sus options
  MessageOptions get all => Map.unmodifiable(_data);

  /// Solo los campos que tienen al menos una option
  MessageOptions get withOptions => Map.fromEntries(_data.entries.where((e) => e.value.isNotEmpty));

  /// Valor de una option concreta de un campo
  T? get<T>(String fieldName, int optionTag) => _data[fieldName]?[optionTag] as T?;

  // ── Parser estático ──────────────────────────────────────────

  static MessageOptions _parse(Uint8List bytes) {
    final result = <String, FieldOptions>{};
    final reader = CodedBufferReader(bytes);

    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      final fieldNum = tag >> 3;
      final wireType = tag & 0x7;

      if (fieldNum == 2 && wireType == 2) {
        // field 2 = FieldDescriptorProto
        final fieldBytes = reader.readBytes();
        final (name, opts) = _parseFieldDescriptor(CodedBufferReader(fieldBytes));
        if (name != null) result[name] = opts;
      } else {
        _skip(reader, wireType);
      }
    }
    return result;
  }

  static (String?, FieldOptions) _parseFieldDescriptor(CodedBufferReader reader) {
    String? name;
    FieldOptions opts = {};

    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      final fieldNum = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNum) {
        case 1: // name (string)
          name = reader.readString();
        case 8: // options (FieldOptions — length-delimited)
          final optBytes = reader.readBytes();
          opts = _parseOptions(CodedBufferReader(optBytes));
        default:
          _skip(reader, wireType);
      }
    }
    return (name, opts);
  }

  /// Lee TODAS las options sin saber sus nombres.
  /// Detecta el tipo por wireType:
  ///   wireType 0 → varint  (int / bool)
  ///   wireType 2 → string  (asume UTF-8; si falla guarda como bytes)
  ///   wireType 1 → int64
  ///   wireType 5 → int32
  static FieldOptions _parseOptions(CodedBufferReader reader) {
    final opts = <int, dynamic>{};

    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      final fieldNum = tag >> 3;
      final wireType = tag & 0x7;

      // Ignoramos las options estándar de protobuf (campo < 1000)
      // que no son nuestras custom options
      if (fieldNum < 1000) {
        _skip(reader, wireType);
        continue;
      }

      switch (wireType) {
        case 0: // varint → puede ser bool o int
          final value = reader.readInt64().toInt();
          // Heurística: si es 0 o 1 lo guardamos como bool
          opts[fieldNum] = (value == 0 || value == 1) ? value == 1 : value;

        case 2: // length-delimited → intentamos UTF-8, si no bytes
          final bytes = reader.readBytes();
          try {
            opts[fieldNum] = String.fromCharCodes(bytes);
          } catch (_) {
            opts[fieldNum] = bytes; // guardamos raw si no es texto
          }

        case 1: // 64-bit
          opts[fieldNum] = reader.readFixed64().toInt();

        case 5: // 32-bit
          opts[fieldNum] = reader.readFixed32();
      }
    }
    return opts;
  }

  static void _skip(CodedBufferReader reader, int wireType) {
    switch (wireType) {
      case 0:
        reader.readInt64();
      case 1:
        reader.readFixed64();
      case 2:
        reader.readBytes();
      case 5:
        reader.readFixed32();
    }
  }
}
