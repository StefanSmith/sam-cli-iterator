#! /usr/bin/env bash

set -o nounset -o errexit -o pipefail

cloudFormationStackName=$1
functionCfnLogicalResourceId=$2
functionBuildDirectory=$3
functionAliasName=${4:-}

zip_file="$(mktemp -d)/code.zip"
pushd "${functionBuildDirectory}" > /dev/null
zip --quiet --recurse-paths "${zip_file}" .
popd > /dev/null

functionName=$(aws cloudformation describe-stack-resource --stack-name "${cloudFormationStackName}" --logical-resource-id "${functionCfnLogicalResourceId}" --output text --query 'StackResourceDetail.PhysicalResourceId')
functionArn=$(aws lambda get-function --function-name "${functionName}" --query 'Configuration.FunctionArn' --output text)
aws lambda tag-resource --resource "${functionArn}" --tags "__CODE_WAS_MANUALLY_CHANGED__=true"
functionCodeSha256=$(aws lambda update-function-code --zip-file "fileb://${zip_file}" --function-name "${functionName}" --query CodeSha256 --output text)

if [[ -n "${functionAliasName}" ]]; then
  oldFunctionVersion=$(aws lambda get-alias --function-name "${functionName}" --name "${functionAliasName}" --query FunctionVersion --output text)
  newFunctionVersion=$(aws lambda publish-version --function-name "${functionName}" --code-sha256 "${functionCodeSha256}" --query Version --output text)
  aws lambda update-alias --name "${functionAliasName}"  --function-name "${functionName}" --function-version "${newFunctionVersion}" > /dev/null
  aws lambda delete-function --function-name "${functionName}" --qualifier "${oldFunctionVersion}"
fi