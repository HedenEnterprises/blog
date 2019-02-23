#!/bin/bash

# return an md5sum of the contents of the specified directory
dir=$1


# second argument MUST be "false" to avoid writing to a file
write_file=true
if [ "x$2" != "x" ]; then
    write_file="$2"
fi


# if no directory is given, default to the posts/ dir
if [ "x$dir" = "x" ]; then
    dir="posts/"
fi


# replace '/' with '-', and then remove trailing '-'
md5file=$(echo "${dir}" | tr / - | sed 's/-$//')
md5file="${md5file}.md5"


find "${dir}" -type f -exec md5sum '{}' \; > "${md5file}"


md5=$(md5sum "${md5file}" | awk '{print $1}')


echo "${md5}"


if [ "x$write_file" != "xfalse" ]; then
    echo "${md5}" > "${md5file}"
fi
