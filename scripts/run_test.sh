#!/bin/bash
set -e

docker compose run --rm hw3 run_test "$@"
