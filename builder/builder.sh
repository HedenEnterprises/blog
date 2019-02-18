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


# this build was spawned by travis committing after processing
# we can ignore it
if [[ "$TRAVIS_COMMIT_MESSAGE" =~ ^published:.* ]]; then
    echo "Ignoring messages that start with \"published:\""
    echo " > Message: $TRAVIS_COMMIT_MESSAGE"
    exit 1
fi


# check if we have a current md5 of our posts file
# if we don't it forces a complete rebuild (e.g.: new template files)
if [ -f "/posts.md5" ]; then

    md5old=$(cat ./posts.md5)
    md5new=$(bash ./builder/md5-dir.sh)

    # check if the md5 of the posts/ directory is the same as it has been
    # if it is, then we have nothing to do
    if [ "$md5old" = "$md5new" ]; then
        echo "Ignoring commit because old md5 matches new md5 of posts directory"
        echo " > Old: ${md5old}"
        echo " > New: ${md5new}"
        exit 1
    fi

# if we don't, we need one
else
    bash ./builder/md5-dir.sh
fi


# create appropriate directories in published/ directory
dirs=$(find posts -type d | sed 's/^posts/published/')
for dir in $dirs; do
    mkdir -p "${dir}"
done


# see what variables our header/footer requires and store them somewhere
varfile="template.variables"
if [ -f "${varfile}" ]; then
    rm "${varfile}"
fi


# grab any template variables from header/footer (e.g.: %%%{TITLE})
cat "${header}" | grep "%%%{" | sed 's/.*%%%{//;s/}.*//' >> "${varfile}"
cat "${footer}" | grep "%%%{" | sed 's/.*%%%{//;s/}.*//' >> "${varfile}"


# get rid of duplicates
cat "${varfile}" | sort | uniq > "${varfile}.tmp"
mv "${varfile}.tmp" "${varfile}"


# process files
files=$(find posts -type f)
for source in $files; do

    target=$(echo "${source}" | sed 's/^posts/published/' | sed 's/md$/html/')

    # if the file is a markdown file, we process it
    if echo $source | grep -q "\.md$"; then


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
        cp "${source}" "${target}"
    fi


done


# clean up the template variable file
rm "${varfile}"


# who is travis, really?
git config --global user.email "travis@travis-ci.org"
git config --global user.name  "Travis CI"


# now add all the stuff we care about
git add posts.md5
git add published/


# now do some fancy stuff and reset our origin to use our gh access token
git remote rm origin
git remote add origin https://hedenface:${token}@github.com/HedenEnterprises/blog.git >/dev/null 2>&1

git status


# commit with our special message
git commit -m "published: ${TRAVIS_COMMIT}: ${TRAVIS_COMMIT_MESSAGE}" --verbose
git push origin master --verbose
