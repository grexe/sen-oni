#!/bin/bash
# todo: params check and usage info

mimedb_path="$HOME/config/settings/mime_db"
oni_output=/tmp/.oni-out
ontology_name=$1
ontology_path=$oni_output/$ontology_name

# clean up from previous run, separate dir per ontology given as arg
rm -fR $ontology_path

function create_mime_type()
{
    type_name=$(basename --suffix=.rdef $1)
    type_path=$(dirname $1)
    rsrc_path=$oni_output/$type_path/$type_name.rsrc

    rc -o $rsrc_path $1 && \
    resattr -O -o $oni_output/$type_path/$type_name $rsrc_path && \

    rm $rsrc_path || false
}

# setup execution context
set -e
mkdir -p $ontology_path/meta
mkdir $ontology_path/entity
mkdir $ontology_path/relation

echo creating ontology "$ontology_name" from resource definitions...

find $1 -iname *.rdef -print0 | while IFS= read -r -d '' file
do
    echo "  $file"
    create_mime_type $file || (echo "Aborting."; exit 1)
done

echo installing ontology "$ontology_name" to MIME DB in $mimedb_path...

cp -a $ontology_path/* $mimedb_path/

echo please restart to apply changes.
exit 0
