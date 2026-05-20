#!/bin/bash
set -e

docker compose run --rm -T hw3 golden_codegen "$@"
