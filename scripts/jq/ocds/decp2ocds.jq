def walk(f):
      . as $in
      | if type == "object" then
          reduce keys_unsorted[] as $key
            ( {}; . + { ($key):  ($in[$key] | walk(f)) } ) | f
      elif type == "array" then map( walk(f) ) | f
      else f
      end;
def getIdScheme(typeIdentifiant):
    typeIdentifiant |
    if . == "SIRET" then "FR-RCS"
    else .
    end;
def getBuyer:
    . | (if (."_type" == "Marché") then
    .acheteur else .autoriteConcedante end)
    ;
def getSupplier:
    . | (if (."_type" == "Marché") then
    (.titulaires // [] | unique_by(.id)) else (.concessionnaires // [] | unique_by(.id)) end) |
    if (. == null) then empty else .[] end
    ;

def formatDate(date):
    if (date|type == "string") then
        date | match("(\\d{4}-\\d\\d-\\d\\d)(.*)?") | (.captures[0].string + "T00:00:00" + (if .captures[1].string == "" then "Z" else .captures[1].string end))
    else null end
    ;

def getReleaseDate:
        (formatDate(.datePublicationDonnees) // $datetime)
    ;
def getDurationInDays(durationInMonths):
    durationInMonths * 30.5 | floor
    ;
def getReleaseIdMeta:
    (.uid | match("..$") | .string) as $suffix |
    if ((.uid | type) == "string") and ($suffix | test("\\d\\d")) and ($suffix | tonumber) == (.modifications |length) then
    {
        "id": (.uid | rtrimstr($suffix)),
        "seq": "00",
        "nbModif": (.modifications |length)
    }
    else
    {
        "id": .uid,
        "seq": "00",
        "nbModif": (.modifications |length)
    } end
    ;

def makeRelease(marche):
if marche == null then
    .
else
    .value as $modification |
    .key as $key |
    marche | .
end |

    # Defining variables
    if (._type == "Marché") then
    getReleaseIdMeta as $releaseIdMeta |

    getDurationInDays(.dureeMois) as $durationInDays |
    ($releaseIdMeta.id + "-" + $releaseIdMeta.seq) as $releaseId |
    ($ocidPrefix + "-" + $releaseIdMeta.id) as $ocid |
    [{
    "id": ($ocid + "-item-1"),
    "description": .objet,
    "classification":
    (if .codeCPV != null then {
        "scheme": "CPV",
        "id": .codeCPV
    } else empty
    end)
}] as $items |

    {
        "ocid": $ocid,
        "id": $releaseId,
        "decpUID": .uid,
        "date": getReleaseDate,
        "language": "fr",
        "tag": ["award"],
        "initiationType": "tender",
        "parties":
        [
            (getBuyer |
            {
                    "name": .nom,
                    "id": .id,
                    "roles": ["buyer"],
                    "identifier": {
                        "scheme": "FR-RCS",
                        "id": .id,
                        "legalName": .nom
                    }})
                    ,
          (getSupplier | {
                  "name": .denominationSociale,
                  "id": .id,
                  "roles": ["supplier"],
                  "identifier": {
                      "scheme": getIdScheme(.typeIdentifiant),
                      "id": .id,
                      "legalName": .denominationSociale
                  }
              })
              ],
        "buyer": getBuyer | {
            "name": .nom,
            "id": .id
        },
        "awards": [{
            "id": ($ocid + "-award-1"),
            "description": .objet,
            "status": "active",
            "date": formatDate(.dateNotification),
            "value": {
                "amount": .montant,
                "currency": "EUR"
            },
            "suppliers": [(getSupplier | {
                  "name": .denominationSociale,
                  "id": .id
                  })
              ],
            "items": $items,
            "contractPeriod": {
                "durationInDays": $durationInDays
            }
            }],
            "contracts":[
                {
                    "id": ($ocid + "-contract-1"),
                    "awardID": ($ocid + "-award-1"),
                    "value": {
                        "amount": .montant,
                        "currency": "EUR"
                    },
                    "description": .objet,
                    "period":   {
                        "durationInDays": $durationInDays
                    },
                    "status": "active",
                    "items": $items
                }
            ]
        }  else null end

    ;

{
	"version": "1.1",
	"uri": $packageUri,
	"publishedDate": $datetime,
	"publisher": {
		"name": "Secrétariat Général du Gouvernement français",
		"scheme": "FR-RCS",
		"uid": "12000101100010"
	},
	"license": "https://www.etalab.gouv.fr/licence-ouverte-open-licence",
	"publicationPolicy": $datasetUrl,
	"releases": [
        .marches[] |
        . as $marche |

        # Process modifications
        # (if (.modifications | length) > 0 then
        # (.modifications| to_entries | .[] | makeModification($marche)
        #
        # ) else
        # null end),

        # Process initial data
        makeRelease(null)
    ]
}
# Added to remove all null properties from the resulting tree
| walk(
    if type == "object" then
        with_entries(select( .value != null and .value != {} and .value != []))
    elif type == "array" then
        map(select( . != null and . != {} and . != []))
    else
        .
    end
)
