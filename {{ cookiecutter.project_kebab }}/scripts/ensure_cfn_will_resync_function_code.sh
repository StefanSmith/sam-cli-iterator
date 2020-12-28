#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail

cloudFormationStackName=$1
functionCfnLogicalResourceId=$2
functionBuildDirectory=$3

functionName=$(aws cloudformation describe-stack-resource --stack-name "${cloudFormationStackName}" --logical-resource-id "${functionCfnLogicalResourceId}" --output text --query 'StackResourceDetail.PhysicalResourceId' || echo "")

if [[ -z "${functionName}" ]]
then
  echo "Unable to describe resource '${functionName}' in stack '${cloudFormationStackName}'. Skipping manual code change remediation."
  exit
fi

codeWasManuallyChanged=$(aws lambda get-function --function-name "${functionName}" --query 'Tags.__CODE_WAS_MANUALLY_CHANGED__' --output text || echo "")

if [[ "${codeWasManuallyChanged}" == "true" ]]
then
  uuidgen > "${functionBuildDirectory}/.random-data-to-force-cloudformation-resource-update"
fi