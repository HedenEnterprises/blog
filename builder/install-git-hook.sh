#!/bin/bash

if [ ! -f ./builder/git-pre-commit-hook ]; then
    echo "Sorry for the inconvienence, please run this from project root"
    exit 1
fi

cp ./builder/git-pre-commit-hook .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
