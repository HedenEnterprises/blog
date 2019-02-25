#!/bin/bash


# processing tool options
opts_markdown=""
opts_tidy="-indent --indent-spaces 4 -wrap -1 --doctype omit"


# template files
header="template/header.html"
footer="template/footer.html"


# make sure the template files exist
if [ ! -f "${header}" ] || [ ! -f "${footer}" ]; then
    echo "No template files found, that's odd"
    exit 1
fi


# no commit message (or empty message) found
if [ "x$TRAVIS_COMMIT_MESSAGE" = "x" ]; then
    echo "No commit message found, that's odd"
    exit 1
fi


# check if we have a current md5 of our posts file
# if we don't it forces a complete rebuild (e.g.: new template files)
if [ -f "posts.md5" ]; then

    md5old=$(cat "posts.md5")
    md5new=$(bash "builder/md5-dir.sh")

    # check if the md5 of the posts/ directory is the same as it has been
    # if it is, then we have nothing to do
    if [ "$md5old" = "$md5new" ]; then
        echo "Ignoring commit because old md5 matches new md5 of posts directory"
        echo " > Old: ${md5old}"
        echo " > New: ${md5new}"
        exit 0
    fi

# if we don't, we need one
else
    bash "builder/md5-dir.sh"
fi


# wipe out the published/ dir
rm -rf "published/*"


# create appropriate directories in published/ directory
dirs=$(find "posts/" -type d | sed 's/^posts/published/')
for dir in $dirs; do
    mkdir -p "${dir}"
done


# see what variables our header/footer requires and store them somewhere
varfile="template.variables"
if [ -f "${varfile}" ]; then
    rm "${varfile}"
fi


# grab any template variables from header/footer (e.g.: %%%{TITLE})
bash "builder/template-vars.sh" "${header}" >> "${varfile}"
bash "builder/template-vars.sh" "${footer}" >> "${varfile}"


# process files
files=$(find "posts/" -type f)
echo ""
echo "Files: " $files
echo ""
for source in $files; do

    echo ""
    echo "Working with file: ${source}"

    target=$(echo "${source}" | sed 's/^posts/published/' | sed 's/md$/html/')

    echo " > Target file: ${target}"
    echo ""

    # if the file is a markdown file, we process it
    if echo $source | grep -q "\.md$"; then

        echo " > Markdown file..."


        # we'll be using tmp header/footer so we can do search+replace
        cp "${header}" "${header}.tmp"
        cp "${footer}" "${footer}.tmp"


        # now look through the current file to find any variables it declares
        # the format for this is:
        #
        # <!-- [VARIABLE]: [value] -->
        #
        while read var; do

            match_string="<!-- ${var}:"


            # if we don't have a variable defined we can't build the html
            if ! grep -q "${match_string}" "${source}"; then  
                echo "No luck locating ${var} definition in file: ${source}"
                exit 1
            fi


            # grab a line with the variable definition
            line_with_var=$(cat "${source}" | grep "${match_string}" | head -1)


            # get rid of the stuff around the value
            value=$(echo "${line_with_var}" | sed "s/.*${match_string}//;s/-->.*//")


            # trim whitespace from front and rear
            value=$(echo "${value}" | sed 's/^\s*//;s/\s*$//')


            # search and replace on the template tmp file
            sed -i "s/%%%{$var}/$value/g" "${header}.tmp"
            sed -i "s/%%%{$var}/$value/g" "${footer}.tmp"


            # now make a "stripped" file that does not contain these hidden
            # variable definitions
            cat "${source}" | grep -v "${match_string}" > "${source}.stripped"


        done < "${varfile}"

        echo ""
        echo "****"
        echo "wtf"
        git status
        echo ""
        echo "****"
        echo ""
        echo ""


        # transfer markdown to html (while pre/app-ending our template data)
        cat "${header}.tmp" > "${source}.tmp"
        markdown $opts_markdown "${source}.stripped" >> "${source}.tmp"
        cat "${footer}.tmp" >> "${source}.tmp"


        # now apply tidy html to it (with our options declared up top)
        cat "${source}.tmp" | tidy $opts_tidy > "${target}.tmp"


        # we have to do this because the version of tidy we use doesn't have
        # the `html5` option :(
        echo "<!DOCTYPE html>" > "${target}"
        cat "${target}.tmp" >> "${target}"


        # now clean up all the tmp files
        rm "${source}.tmp" "${source}.stripped"
        rm "${target}.tmp"
        rm "${header}.tmp" "${footer}.tmp"


    # otherwise we just copy it...
    else
        echo " > Non-markdown, copying directly..."
        cp "${source}" "${target}"
    fi


done


# clean up the template variable file
rm "${varfile}"


# who is travis, really?
git config --global user.email "travis@travis-ci.org"
git config --global user.name  "Travis CI"


# now do some fancy stuff and reset our origin to use our gh access token
git remote rm origin
git remote add origin https://${token}@github.com/HedenEnterprises/blog.git >/dev/null 2>&1


# now add all the stuff we care about
git checkout master
git add -f posts.md5 published/
git status


# commit with our special message
git commit -m "[skip ci] ${TRAVIS_COMMIT}: ${TRAVIS_COMMIT_MESSAGE}"

if git push origin master --quiet >/dev/null 2>&1; then
    echo "git push successful!"
fi
