#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker build -t guikali-image -f $SCRIPT_DIR/GuiKali.Dockerfile $SCRIPT_DIR/../docker_setup