#!/bin/bash
set +x
# Dependencies:
#  - awscli     see https://docs.aws.amazon.com/cli/latest/userguide/installing.html for installation instructions
#  - jq         typically found as the package 'jq' on most distros


catch_error() {
  echo -e "ERROR: ${@}"
  [ -r "${TMPFILE}" ] && rm ${TMPFILE}
  exit 1
}


# Returns the hosted_zone (domain name) for a given domain (i.e. test.com, www.test.com or www.staging.test.co.uk)
# For the last example: tries in order: co.uk, then test.co.uk, then staging.test.co.uk, then www.staging.test.co.uk
# Returns no output if the domain is not in our hosted zones list
get_domain_hosted_zone() {
  DOMAIN=$1
  [ -z ${DOMAIN} ] && catch_error "get_hosted_zone_id needs a domain name as argument, exiting..."

  OLDIFS=$IFS
  IFS=. DP=(${DOMAIN##*-})
  IFS=$OLDIFS
  TD=${DP[-1]}
  for (( nI=${#DP[@]}-2 ; nI>=0 ; nI-- )) ; do
    TD="${DP[nI]}.${TD}"
    HZ=$( aws route53 list-hosted-zones | \
      jq ".HostedZones | map(select(.Name == \"${TD}.\" )) | .[0].Name" | \
      sed "s/hostedzone//g;s/\///g;s/\"//g" \
    )
    if [ "${HZ}" != "null" ]; then
      echo ${HZ%?}
    fi
  done
}

get_hosted_zone_id() {
  DOMAIN=$1
  [ -z ${DOMAIN} ] && catch_error "get_hosted_zone_id needs a domain name as argument, exiting..."
  aws route53 list-hosted-zones | \
    jq -r ".HostedZones | map(select(.Name == \"${DOMAIN}.\")) | .[0].Id" | \
    sed "s/hostedzone//g;s/\///g;s/\"//g"
}

dns-aws-add() {
  # DNS record to create/update and Value to store
  RECORDSET=${1}
  VALUE=${2}
  # Record TTL
  TTL=60

  # make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set
  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
  then
    if [ -r ~/.aws/credentials ]; then
      echo "AWS Client will use ~/.aws/credentials..."
    else
      catch_error "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY"
    fi
  else
    # Any subsequent aws client call will use this env vars
    export ${AWS_ACCESS_KEY_ID}, ${AWS_SECRET_ACCESS_KEY}
  fi

  # Record comment. Updated to avoid non-ascii characters make it fail. (i.e. @ mié mar 16 12:16:01 CET 2016)
  COMMENT="Auto updated by dns-r53 @ $(date +%Y-%m-%dT%H:%M)"

  [ -z "${RECORDSET}" ] && catch_error "Missing RECORDSET as first parameter"
  [ -z "${VALUE}" ] && "Missing VALUE as second parameter"

  HOSTED_ZONE=$( get_domain_hosted_zone ${RECORDSET} )
  [ -z "${HOSTED_ZONE}" ] && catch_error "Failed to determine the HOSTED_ZONE"

  echo "Getting Hosted Zone ID for [${HOSTED_ZONE}]..."
  ZONEID=$( get_hosted_zone_id $HOSTED_ZONE )
  [ -z "${ZONEID}" ] && catch_error "Failed to retrive ZONEID for '${HOSTED_ZONE}'"
  echo "Hosted Zone ID: ${ZONEID}"

  echo -e "\nUpdating TXT record for ${RECORDSET} to ${VALUE}"

  TMPFILE="/tmp/temporary-file.$$"
  read -r -d '' RRSET <<EOF
{
  "Comment": "${COMMENT}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "ResourceRecords": [ { "Value": "\"${VALUE}\"" } ],
        "Name": "${RECORDSET}",
        "Type": "TXT",
        "TTL": ${TTL}
      }
    }
  ]
}
EOF
  echo ${RRSET} > ${TMPFILE}

  # Update the Hosted Zone record
  OUTPUT=$(aws route53 change-resource-record-sets \
    --hosted-zone-id ${ZONEID} \
    --change-batch file://"${TMPFILE}" 2>&1)
  [ "$?" == 0 ] || catch_error "${OUTPUT}\n\nFailed to set TXT record:"

  # Clean up temp file
  rm ${TMPFILE}
}
