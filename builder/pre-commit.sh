#!/bin/bash


basedir=$(dirname $(readlink -f $0))


script="${basedir}/builder/template-vars.sh"


# get all of our existing template vars
template_vars=$($script "${basedir}/template/header.html" && $script "${basedir}/template/footer.html")


# get all markdown files
files=$(find ${basedir}/posts -type f | grep "\.md$")


# loop over template variables
for var in $template_vars; do

    # and files
    for file in $files; do

        if ! grep -q "${var}" "${file}"; then
            echo "Unable to find template variable \"${var}\" in file ${file}"
            fail="yes"
        fi

    done
done


# batch everything together so we know everywhere we need to fix
if [ "$fail" = "yes" ]; then
    exit 1
fi
