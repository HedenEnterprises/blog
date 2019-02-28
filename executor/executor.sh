#!/bin/bash


basedir=$(dirname $(readlink -f $0))
pluginsdir="${basedir}/../plugins"


# execute a plugin by specifying either app "builder" or "publisher"
# specify the type (where in the code is the plugin executed)
#
# the executor then looks for plugins adhering to that naming convention
# and will execute them in order
#
# the specific data points that are passed to the executor are in the readme

app=$1
type=$2


# make $3 into $1
shift
shift


# validate app
if [ "x$app" != "xbuilder" ] && [ "x$app" != "xpublisher" ]; then
    echo "Must specify one of either builder or publisher for executor"
    exit 1
fi


# validate type
if [ "x$type" = "x" ]; then
    echo "Must specify a type for executor"
    exit 1
fi


# builder types
if [ "$app" = "builder" ]; then

    case $type in
        pre-files)      ;;
        post-files)     ;;
        pre-markdown)   ;;
        post-markdown)  ;;
        pre-tidy)       ;;
        post-tidy)      ;;
        pre-git-commit) ;;
        pre-git-push)   ;;
        *)
            echo "Unknown builder type"
            exit 1
            ;;
    esac


# # publisher types
# else
#     case $type in

#     esac
fi


if [ ! -d "${pluginsdir}" ]; then
    echo "No plugins directory found"
    exit 1
fi


# we'll also look for files matching patterns in pluginsdir
plugindir_1="${pluginsdir}/${app}-${type}"
plugindir_2="${pluginsdir}/${app}/${type}"


function get_plugindir_files {
    dir=$1
    regex=$2

    if ls ${dir}/${regex} &>/dev/null; then

        files=$(ls ${dir}/${regex})
        if [ $? -eq 0 ]; then
            for file in $files; do
                echo $file
            done
        fi
    fi
}


# get all possible plugins
files=$(get_plugindir_files         ${plugindir_1}  *.plugin)
files="$files $(get_plugindir_files ${plugindir_2}  *.plugin)"
files="$files $(get_plugindir_files ${pluginsdir}   ${app}-${type}*.plugin)"


# loop over and pass appropriate data
for file in $files; do

    echo ""
    echo " * Executing plugin (${file})"


    if [ "x$@" != "x" ]; then
        echo " * * Arguments: $@"
    fi


    output=$(/bin/bash "${file}" $@)
    rc=$?


    if [ "x${output}" != "x" ]; then
        echo " * * Output:"
        echo "${output}" | sed 's|^|      ] |'
    fi


    if [ $rc -eq 0 ]; then
        echo " * * Success!"
    else
        echo " * * Failure: Return code: $rc"
        if [ $rc -eq 9 ]; then
            echo " * * CATASTROPHIC FAILURE, exiting nicely"
            exit 1
        fi
    fi
done