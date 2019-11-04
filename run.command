#!/bin/bash

cd -- "$(dirname "$BASH_SOURCE")"
tput reset

source venv/bin/activate
python scripts/python/run.py