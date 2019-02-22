#!/bin/bash

# Correction des anomalies des données essentielles publiées par l'AIFE


source=$1

for file in `ls original-data`
do
    xsltproc $DECP_HOME/scripts/sources/$source/fix.xslt ./original-data/$file > $file
done
