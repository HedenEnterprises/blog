#!/bin/bash

# useful for creating an empty file with appropriate template variable lines
filename=$1


if [ "x$filename" = "x" ]; then
    filename="empty"
    current_number=0
fi


while [ -f "${filename}-${current_number}.md" ]; do
    current_number=$(( $current_number + 1 ))
done


if [ "x$filename" = "xempty" ]; then
    filename="${filename}-${current_number}.md"
elif ! echo $filename | grep -q "\.md"; then
    filename="${filename}.md"
fi

echo $filename
