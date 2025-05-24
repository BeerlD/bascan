#!/bin/bash

HOST="$1"
OUTPUT="$2"
shift 2

expect ./expect/nmap.exp "$HOST" "$OUTPUT" "$@"
