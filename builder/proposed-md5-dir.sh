#!/bin/bash


basedir=$(dirname $(readlink -f $0))


# return an md5sum of the contents of the specified directory (or posts if none
# specified)
dir=posts
if [ "x$1" != "x" ]; then
    dir=$1
fi
basedir="${basedir}/../"
fulldir="${basedir}/${dir}"

echo $dir $basedir $fulldir

# replace '/' with '-', and then remove trailing '-'
md5file=$(echo "${dir}" | tr / - | sed 's/-$//')
md5file="${basedir}/${md5file}.md5"


find "${fulldir}" -type f -exec md5sum '{}' \; > "${md5file}"


md5=$(md5sum "${md5file}" | awk '{print $1}')


echo "${md5}"
echo "${md5}" > "${md5file}"
