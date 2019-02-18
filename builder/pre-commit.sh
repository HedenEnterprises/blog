#!/bin/bash


# normalize our path
if [ -f ./template-vars.sh ]; then
    script="./template-vars"
    t_path="./../"
elif [ -f ./builder/template-vars.sh ]; then
    script="./builder/template-vars.sh"
    t_path="./"
elif [ -f ./../builder/template-vars.sh ]; then
    script="./../builder/template-vars.sh"
    t_path="./../"
elif [ -f ./../../builder/template-vars.sh ]; then
    script="./../../builder/template-vars.sh"
    t_path="./../../"
else
    echo "Can't find template-vars.sh script! Check your path? o.o"
    exit 0
fi


# get all of our existing template vars
template_vars=$($script "${t_path}template/header.html" && $script "${t_path}template/footer.html")


# get all markdown files
files=$(find ${t_path}posts -type f | grep "\.md$")


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
