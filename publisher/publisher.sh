#!/bin/bash


basedir=$(dirname $(readlink -f $0))


config_file="${basedir}/config"
last_check_file="${basedir}/last.check"
bad_fetch_file="${basedir}/bad.fetch"

if [ "x$1" != "x" ]; then config_file=$1; fi
if [ "x$2" != "x" ]; then last_check_file=$2; fi
if [ "x$3" != "x" ]; then bad_fetch_file=$3; fi


# check dependencies
if ! which git >/dev/null 2>&1; then
    echo "No git binary found (in \$PATH, anyway)"
    exit 1
fi


# we need a configuration file
if [ ! -f "${config_file}" ]; then
    echo "No configuration file found at ${config_file}"
    exit 1
fi


# load the variables defined
. "${config_file}"


# timestamp it, yo
current_timestamp=$(date +%s)


repo=$(echo "${repo_url}" | sed 's|.git$||' | sed 's|.*/||')
target=$(echo "${target}" | sed 's|/$||')


frequency=$(echo $frequency | sed 's|[^0-9]*||g')
frequency=$(( $frequency ))


# sane values plz
if [ $frequency -lt 1 ];             then frequency=1               ; fi
if [ $frequency -gt $(( 24 * 60 )) ]; then frequency=$(( 24 * 60))   ; fi


if [ -f "${last_check_file}" ]; then


    last_check=$(cat "${last_check_file}" | sed 's|[^0-9]*||g')
    last_check=$(( $last_check ))


    time_diff=$(( ( $current_timestamp - $last_check ) / 60 ))

    # no log - fill up cron - nah tho
    if [ $time_diff -le $frequency ]; then
        exit 0
    fi
fi


echo $current_timestamp > "${last_check_file}"


echo "Publisher variables:"
echo " * clone_target = ${clone_target}"
echo " * target       = ${target}"
echo " * repo_url     = ${repo_url}"
echo " * repo         = ${repo}"
echo " * frequency    = ${frequency}"


# make sure vars are sane
if echo "${clone_target}-${repo}-${repo_url}-${target}" | grep -q "\.\."; then
    echo "l337 hax0r attempt detected. Stahp"
    exit 13
fi


# does the clone directory exist?
if [ ! -d "${clone_target}" ]; then


    echo "Clone target (${clone_target}) not a directory, attempting to create..."
    mkdir -p "${clone_target}"


    if [ ! -d "${clone_target}" ]; then
        echo " > Unable to create directory!"
        exit 1
    fi


    echo " > Directory successfully created!"
fi


pushd "${clone_target}"


if [ ! -d "${repo}" ]; then


    echo "Initial git clone of ${repo_url}"


    if ! git clone "${repo_url}"; then
        echo " > Unable to clone repo, check URL and try again..."
        exit 1
    fi


    # we dont need to fetch if we just cloned...
    dont_fetch=true
fi


# more quick error checking that the rest of the script depends on
if [ ! -d "${repo}" ]; then
    echo "Why doesn't directory ${repo} exist? Weird..."
    exit 1
fi
if [ ! -d "${repo}/published" ]; then
    echo "Why doesn't directory ${repo}/published exist? Weird..."
    exit 1
fi


pushd "${repo}"


# nothing fancy
if [ "x$dont_fetch" != "xtrue" ]; then
    fetched=$(git fetch 2>"${bad_fetch_file}")
fi


# no fetch output? no problem (..no syncing)
if [ "x$fetched" = "x" ]; then
    exit 0
fi


if [ -f "${bad_fetch_file}" ]; then
    echo "Bad fetch detected!"
    cat "${bad_fetch_file}"
    rm "${bad_fetch_file}"
    exit 1
fi


# also nothing fancy
# -a = --archive
# -v = --verbose
# -h = --human-readable
rsync -a -v -h --delete --progress "published/" "${target}"


popd
popd
