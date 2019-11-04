#!/bin/bash

tput reset
cd -- "$(dirname "$BASH_SOURCE")"
cd ../..

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install python3
pip3 install virtualenv
mkdir venv
virtualenv venv
source venv/bin/activate
pip install -r scripts/python/requirements.txt