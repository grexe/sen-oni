#!/bin/bash
# todo: params check and usage info

SEN_ONTO_TYPE=meta/x-vnd.sen-meta.ontology
SEN_CONFIG_ONTO=$HOME/config/settings/sen/ontologies

MIME_DB_PATH=$HOME/config/settings/mime_db
META_MIME_TYPE=application/x-vnd.Be-meta-mime

mkdir -p $SEN_CONFIG_ONTO

oni_output=/tmp/.oni-out
ontology_name=$(basename $1)
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

echo creating ontology $ontology_name from resource definitions...

find $1 -iname *.rdef -print0 | while IFS= read -r -d '' file
do
    echo "  $file"
    create_mime_type $file || (echo "Aborting."; exit 1)
done

echo installing ontology $ontology_name to MIME DB in $MIME_DB_PATH...
cp -a $ontology_path/* $MIME_DB_PATH/

echo registering ontology in SEN configuration...

mkdir $SEN_CONFIG_ONTO/$ontology_name
addattr "BEOS:TYPE" $META_MIME_TYPE $SEN_CONFIG_ONTO/$ontology_name
addattr "META:TYPE" $SEN_ONTO_TYPE $SEN_CONFIG_ONTO/$ontology_name

cp -a $ontology_path/* $SEN_CONFIG_ONTO/$ontology_name/

echo Done. Please restart to apply changes.
exit 0
