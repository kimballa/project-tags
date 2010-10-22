#!/bin/bash
#
# This software is made available to you under the terms of the
# Apache 2.0 Public license.
#

bin=`dirname $0`
bin=`cd ${bin} && pwd`

targetdir="."
m2repo=~/.m2/repository

print_usage() {
  echo "Usage: $0 [-d <dirname>] [-m <m2-repo-dirname>]"
  return 0
}

# Given the filename of a source jar, unzip it and run tags over the file.
# Then add the tags filename to our growing list.
process_source() {
  srcjar=$1
  jardir=`dirname "${srcjar}"`

  if [ -d "${jardir}/.srcfiles" ]; then
    rm -rf "${jardir}/.srcfiles"
  fi
  mkdir "${jardir}/.srcfiles"

  pushd "${jardir}/.srcfiles" 2>/dev/null >/dev/null
  jar xf "${srcjar}"
  etags -R .
  popd 2>/dev/null >/dev/null
  newtags=`cat .taglist`
  echo "${newtags}\\ ${jardir}/.srcfiles/TAGS" > .taglist
}

while [ ! -z "$1" ]; do
  if [ "$1" == "-d" ]; then
    shift
    targetdir="$1"
  elif [ "$1" == "-m" ]; then
    shift
    m2repo="$1"
  elif [ "$1" == "-h" ]; then
    print_usage
    exit 0
  else
    echo "Cannot understand argument $1. Try -h"
    exit 1
  fi
  shift
done

cd "${targetdir}"

# Process tags in the current project sources
etags -R .
echo "./TAGS" > .taglist

if [ ! -f ".classpath" ]; then
  echo "No .classpath file in "`pwd`
  exit 1
fi

# Get a list of all dependency jars.
inputjars=`cat .classpath | awk '/<classpathentry kind="var"/ {print $3}' \
    | sed -e 's|/>$||' | sed -e 's|\"$||' | sed -e 's/path=\"//' | sed -e "s|^M2_REPO|$m2repo|"`

# Process tags for all dependencies
for jar in $inputjars; do
  sourcejar=`echo $jar | sed -e 's|\.jar$|-sources.jar|'`
  if [ -f "$sourcejar" ]; then
    echo Found sources $sourcejar
    process_source $sourcejar
  fi
done

