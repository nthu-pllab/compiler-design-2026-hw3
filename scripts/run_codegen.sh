#!/bin/bash
set -e

docker compose run --rm -T hw3 run_codegen "$@"
