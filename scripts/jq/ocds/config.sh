#!/bin/bash

if [[ -z $datetime ]]
then
 export datetime=`date "+%FT%T+02:00"`
fi

export dataset_id="5cd57bf68b4c4179299eb0e9"
export package_uri="https://www.data.gouv.fr/fr/datasets/r/68bd2001-3420-4d94-bc49-c90878df322c"
export dataset_url="https://www.data.gouv.fr/fr/datasets/$dataset_id"
export ocid_prefix="ocds-78apv2"
