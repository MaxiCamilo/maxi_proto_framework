#!/bin/bash

export PATH="$PATH:$HOME/.local/bin"
dart pub global activate protoc_plugin
cd ~/Proyectos/NuevoRumbo/maxi_proto_framework
rm -r lib/src/generated
mkdir -p lib/src/generated
protoc   --dart_out=grpc:lib/src/generated   --proto_path=lib/src/protos google/protobuf/descriptor.proto   lib/src/protos/*