#!/bin/bash

# todo: params check and usage info

set -e

# read manifest
. $1/manifest.properties

# SEN config
SEN_CONFIG_ONTO=$HOME/config/settings/sen/ontologies

# SEN Ontology config
SEN_ONTO_TYPE=meta/x-vnd.sen-meta.ontology
SEN_ONTO_AUTHOR_ATTR="SEN:onto:author"
SEN_ONTO_SCHEMA_ATTR="SEN:onto:schema_url"
SEN_ONTO_VERSION_ATTR="SEN:onto:version"
SEN_ONTO_DESCRIPTION_ATTR="SEN:onto:description"
SEN_ONTO_STABLE_ATTR="SEN:onto:stable"

# Haiku MIME config
MIME_DB_PATH=$HOME/config/settings/mime_db
META_MIME_TYPE=application/x-vnd.Be-meta-mime

mkdir -p $SEN_CONFIG_ONTO

oni_output=/tmp/.oni-out
ontology_name=$(basename $1)
ontology_path=$oni_output/ontologies/$ontology_name

# clean up from previous run, separate dir per ontology given as arg
rm -fR $ontology_path

function create_mime_type()
{
    type_name=$(basename --suffix=.rdef $1)
    type_path=$(dirname $1)
    rsrc_path=$oni_output/$type_path/$type_name.rsrc

    rc -o $rsrc_path $1 && \
    mime install $rsrc_path &&
    rm $rsrc_path || false
}

# setup execution context
mkdir -p $ontology_path/meta
mkdir $ontology_path/entity
mkdir $ontology_path/relation

echo creating ontology $ontology_name from resource definitions...

find $1 -iname *.rdef -print0 | while IFS= read -r -d '' file
do
    echo "  $file ..."
    create_mime_type $file || (echo "Aborting."; exit 1)
done

echo registering ontology in SEN configuration...

sen_onto_path=$SEN_CONFIG_ONTO/$ontology_name
mkdir -p $sen_onto_path
addattr "BEOS:TYPE" -t mime $SEN_ONTO_TYPE $sen_onto_path

# write onto manifest attributes
addattr "$SEN_ONTO_SCHEMA_ATTR" "$SCHEMA" $sen_onto_path
addattr "$SEN_ONTO_VERSION_ATTR" "$VERSION" $sen_onto_path
addattr "$SEN_ONTO_AUTHOR_ATTR" "$AUTHOR" $sen_onto_path
addattr "$SEN_ONTO_DESCRIPTION_ATTR" "$DESCRIPTION" $sen_onto_path
if [ "$STABLE" = "true" ] || [ "$STABLE" = "1" ]; then
    addattr -t bool "$SEN_ONTO_STABLE_ATTR" true $sen_onto_path
fi

cp -a $ontology_path/* $SEN_CONFIG_ONTO/$ontology_name/

echo Done. Please restart to apply changes.
exit 0
