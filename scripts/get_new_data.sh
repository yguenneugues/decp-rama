#!/bin/bash

#**********************************************************************
#
# Extrait les marchés ajoutés par rapport à fichier agrégé ancien
#
#**********************************************************************

oldFile=$1
newFile=$2

echo "Extraction des UID des anciens et nouveaux marchés... "

# command qui identifie les différences entre $oldFile et $newFile
diff_marches='diff <(jq ".marches[].uid" $oldFile | sort -u) <(jq ".marches[].uid" $newFile | sort -u)'
# Sélection des différences correspondant aux nouveaux marchés
nouveaux_marches=$(eval $diff_marches | grep '>' | sed 's/> //g')
# Sélection des différences correspondant aux marchés disparus (plus présent dans $newFile alors qu'ils existaient dans $oldFile)
marches_disparus=$(eval $diff_marches | grep '<' | sed 's/< //g')

echo -e "\
Ancien fichier :        $(jq -M ".marches[].uid" $oldFile | sort -u | wc -l ) marchés uniques (via uid)\n
Nouveau fichier :       $(jq -M ".marches[].uid" $newFile | sort -u | wc -l ) marchés uniques\n
                        $(echo $nouveaux_marches | wc -w) nouveaux marchés uniques\n
                        $(echo $marches_disparus | wc -w) marchés disparaus\n"

nouveaux_marches_json=$(echo '{'$(echo $nouveaux_marches | sed 's/" "/": 1,"/g')': 1}')

daily_file="decp_$(date "+%F").json"

jq -M -c --slurpfile newUids <(echo "$nouveaux_marches_json") '{"marches": [(.marches[] | select (.uid | in($newUids[0])))]}' $newFile > $daily_file

echo "Nombre de marchés dans le fichier des nouveaux marchés :"
jq '.marches | length' $daily_file


# echo "Extraction des UID des anciens et nouveaux marchés, en remplaçant les espaces éventuels par 'xSPACEx'... "
#
# jq -r '.marches[].uid' $oldFile | sed 's/ /xSPACEx/g' > oldMarchesRaw
# jq -r '.marches[].uid' $newFile | sed 's/ /xSPACEx/g' > newMarchesRaw
#
# nbMarchesRaw=`cat newMarchesRaw | wc -l`
#
# sort -u oldMarchesRaw > oldMarchesNoDuplicates
# sort -u newMarchesRaw > newMarchesNoDuplicates
#
# nbMarchesUniqueOld=`cat oldMarchesNoDuplicates | wc -l`
# nbMarchesUniqueNew=`cat newMarchesNoDuplicates | wc -l`
#
# diff -u --suppress-common-lines oldMarchesNoDuplicates newMarchesNoDuplicates | grep -e "^+\w" | sed -E 's/^\+//' | sort -u > todayMarches
#
# nbNewMarches=`cat todayMarches | wc -l`
#
# # Bizarrement,la différence de nombre de ligne entre oldMarchesNoDuplicates et newMarchesNoDuplicates n'est pas équivalente au nombre de marchés dans todaysMarches
# # nbNewMarches=$(( $nbMarchesUniqueNew-$nbMarchesUniqueOld))
#
# echo -e "\
# Ancien fichier :        $nbMarchesUniqueOld marchés uniques (via uid)\n
# Nouveau fichier :       $nbMarchesUniqueNew marchés uniques\n
#                         $nbNewMarches nouveaux marchés uniques\n"
#
# # Si le nombre de nouveaux marchés uniques est trop important par rapport au précédent fichier decp.json (previous_decp.json) le temps de traitement devient trop important et le CI peut time out (5h pour extraire 8500 nouveaux marchés https://circleci.com/gh/etalab/decp-rama/234).
# # Pour éviter cela, si le nombre de marchés est important, on utilise une méthode jq (différence d'array) qui est un peu longue (30 min ?), mais don't le temps d'exécution ne devrait pas être lié au nombre de nouveaux marchés.
#
# if [[ $nbNewMarches -lt 2000 ]]
#
# # Méthode classique si peu de nouveaux marchés
# then
#
#     echo '{"marches":[' > temp.json
#
#     echo "Pour chaque nouvelle UID, export de l'objet marché correspondant vers un nouveau fichier..."
#     echo ""
#
#     i=1
#
#     for uid in `cat todayMarches`
#     do
#         uid=`echo $uid | sed 's/xSPACEx/ /g'`
#         echo "$i   $uid"
#         if [[ $i -lt $nbNewMarches ]]
#         then
#          object=`jq --arg uid "$uid" '.marches[] | select(.uid == $uid)' $newFile | sed 's/^\}/},/'`
#          ((i++));
#         else
#          object=`jq --arg uid "$uid" '.marches[] | select(.uid == $uid)' $newFile`
#         fi
#         echo "${object}" >> temp.json
#
#     done
#
#     echo ']}' >> temp.json
#
# else
#     # Méthode si nombreux nouveaux marchés
#     echo "L'ancien array est soustrait du nouveau, les objets identiques sont supprimés..."
#
#     time jq --slurpfile previous $oldFile '{"marches": (.marches - $previous[0].marches)} ' $newFile > temp.json
# fi
#
# echo "Nombre de marchés dans le fichier des nouveaux marchés :"
# jq '.marches | length' temp.json
#
# date=`date "+%F"`
# jq . temp.json > decp_$date.json
#
# # rm oldMarchesNoDuplicates newMarchesNoDuplicates oldMarchesRaw newMarchesRaw todayMarches temp.json
