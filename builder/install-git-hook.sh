#!/bin/bash


basedir=$(dirname $(readlink -f $0))


if [ ! -f "${basedir}/git-pre-commit-hook" ]; then
    echo "Can't find ${basedir}/git-pre-commit-hook..."
    exit 1
fi


cp "${basedir}/git-pre-commit-hook" "${basedir}/../.git/hooks/pre-commit"
chmod +x "${basedir}/../.git/hooks/pre-commit"
