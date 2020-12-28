#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail

functionCodeRelativePath=$1
functionBuildDirectory=$2
esbuildArguments=${3:-}

rm -rf "${functionBuildDirectory:?}"

npx esbuild "${functionCodeRelativePath}/index.js" \
  --bundle \
  --outfile="${functionBuildDirectory}/${functionCodeRelativePath}/index.js" \
  --platform=node \
  --target=node12 \
  --minify \
  ${esbuildArguments}
