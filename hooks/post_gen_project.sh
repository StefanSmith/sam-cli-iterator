#!/usr/bin/env bash

set -o nounset -o errexit -o pipefail

echo CLOUDFORMATION_STACK_NAME={{ cookiecutter.cloudformation_stack_name }} > .env.development