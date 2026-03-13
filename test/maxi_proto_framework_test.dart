@Timeout(Duration(minutes: 30))
library;

import 'package:maxi_proto_framework/maxi_proto_framework.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import 'logic/extract_description.dart';

final labelExt = Extension<String>('app_hub', 'label', 50001, PbFieldType.OS);
final requiredExt = Extension<bool>('app_hub', 'required', 50002, PbFieldType.OB);
final regexExt = Extension<String>('app_hub', 'regex', 50003, PbFieldType.OS);

class FieldMeta {
  final String fieldName;
  final int fieldNumber;
  final String? label;
  final bool? required;
  final String? regex;

  const FieldMeta({required this.fieldName, required this.fieldNumber, this.label, this.required, this.regex});

  bool get hasOptions => label != null || required != null || regex != null;

  @override
  String toString() {
    final parts = [if (label != null) 'label="$label"', if (required != null) 'required=$required', if (regex != null) 'regex="$regex"'];
    return '$fieldName(#$fieldNumber): '
        '${parts.isEmpty ? "(sin options)" : parts.join(", ")}';
  }
}

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('View Attributes', () async {
      final oration = ProtoOration(tokenId: '', text: 'Hi!', textParts: const []);
      final info = oration.info_;
      for (final entry in info.fieldInfo.entries) {
        final tag = entry.key;
        final field = entry.value;

        print(
          '  tag=$tag'
          '  name=${field.name}'
          '  type=${field.type}'
          '  protoName=${field.protoName}',
        );
      }

      final opts = DynamicOptionsReader(protoOrationDescriptor);
      // ── 1. Descubrir todo sin saber nada de antemano ────────────
      print('── Descubrimiento completo ──────────────────────');
      for (final field in opts.withOptions.entries) {
        print('${field.key}:');
        for (final opt in field.value.entries) {
          print('  tag ${opt.key} = ${opt.value} (${opt.value.runtimeType})');
        }
      }
      // token_id:
      //   tag 50001 = Nombre de app (String)
      //   tag 50002 = true (bool)
      // message:
      //   tag 50001 = Versión (String)
      //   tag 50003 = Prueba (String)

      // ── 2. Acceso directo cuando ya sabes el tag ────────────────
      print('\n── Acceso directo ───────────────────────────────');
      print(opts.get<String>('token_id', 50001)); // "Nombre de app"
      print(opts.get<bool>('token_id', 50002)); // true
      print(opts.get<String>('message', 50003)); // "Prueba"

      // ── 3. Ver qué tags existen en un campo ────────────────────
      print('\n── Tags presentes por campo ─────────────────────');
      for (final entry in opts.all.entries) {
        final tags = entry.value.keys.toList();
        print('${entry.key}: tags=$tags');
      }
      // token_id:   tags=[50001, 50002]
      // message:    tags=[50001, 50003]
      // text_parts: tags=[]
    });
  });
}
