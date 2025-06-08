#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SCRIPT_DIR/tmp/"
cp -r ~/.DockerSources/* "$SCRIPT_DIR/tmp/"
docker build -t engage-kali:latest -f $SCRIPT_DIR/GuiKaliCustom.Dockerfile $SCRIPT_DIR/../../