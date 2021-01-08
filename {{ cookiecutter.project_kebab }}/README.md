# {{ cookiecutter.project_name }}

## What is this?

An opinionated approach to rapidly iterating on Lambda function code using the SAM CLI. Using this approach, you're no
longer forced to choose between either fast _or_ accurate feedback. You can have both. The approach is demonstrated
using Javascript but the concepts could be applied to other programming languages.

## Context

To get fast feedback whilst coding, developers typically use SAM CLI's local service emulation features for Lambda and
API Gateway. This provides a rapid cycle but at the cost of truly realistic results. To get accurate feedback,
developers are typically forced to deploy the entire stack, which can take multiple minutes, depending on stack size and
complexity.

## The constraints

This solution is constrained by the following requirements:

- SAM CLI commands should continue to behave as normal. In particular, local commands should work as expected.
- There should be zero overhead to adding new Lambda functions

## Quick start

### Deploy stack
1. Run `make` to install dependencies
1. Run `make deploy` to deploy stack
   
### Update a single function
1. Visit the URL provided by the `HowdyUrl` CloudFormation stack output to invoke the `HowdyFunction` Lambda function 
1. Make changes to `howdy()` in `./src/domain/greetings.js`
1. Run `make update function=HowdyFunction` to update the deployed function code
1. Refresh your browser to see the changes
   
### Update a single function with an alias:
1. Visit the URL provided by the `HelloUrl` CloudFormation stack output to invoke the `HelloFunction` Lambda function
1. Make changes to `additionalGreeting()` in `./src/functions/HelloFunction/additionalGreeting.js`
1. Run `make update alias=live function=HelloFunction` to update the deployed function code
1. Refresh your browser to see the changes

## Customizing
- Edit `.env.development` to set `CLOUDFORMATION_STACK_NAME` 
- Edit `./scripts/install_dependences.sh` to define how dependencies are installed
- Edit `./scripts/build_function_code.sh` to define how function code is built

## Approach

### Single-function code updates

- A `make` recipe is defined which builds a single function and updates the function's code deployed in your AWS
  account. This avoids the need to deploy the entire stack to test each code change.
- Optionally, an existing function alias name can be specified. If specified, a new function version is published and
  the alias is updated to point to it. The alias' previous function version is then deleted.
- A full deployment is still required to update any non-code changes to a Lambda function (e.g. environment variables,
  permissions, event source mappings)
- If a single-function code update is performed and then the local code is reverted to the last version deployed by
  CloudFormation, the next full stack deployment will not deploy the reverted code because CloudFormation is unaware of
  single-function code updates. To work around this, single-function code updates also tag function resources
  with `__CODE_WAS_MANUALLY_CHANGED__`. During a full stack build, any function with this tag has an additional random
  data file added to the code package to force CloudFormation to update the function code. This behaviour can be
  disabled in non-development environments where code is always updated via stack deployments.
- `sam local` subcommands will also correctly reflect changes after a single-function code update
- `sam build <functionName>` is **not** used as it would leave the generated CloudFormation template with invalid code
  URIs to all other functions, which would lead to erroneous results from subsequent `sam local` or `sam deploy` calls

### Custom code builds

- SAM CLI's `BuildMethod: makefile` option is used to provide full control of the function code packaging process
- A single `make` recipe is defined with a wildcard target (`build-%`) for building any Lambda function. The recipe
  relies on `./scripts/build_function_code.sh` for the actual build. Edit this script to customise your per-function
  code build. The provided Javascript example expects the function handler code to reside
  in `src/functions/<LogicalResourceId>/index.js`, where `<LogicalResourceId>` is the function resource name in the
  CloudFormation template.
- To ensure consistency, both `sam build` and single-function code updates use the same underlying `make` target to
  build code

### Minimal code packages

- To keep deployment and cold start times low, Lambda function code package size is minimised. In the provided
  Javascript example, this is achieved through module bundling, code minification and tree-shaking

### Fast builds

- To reduce full application build times, SAM CLI's parallel build feature is used
- SAM CLI's build cache feature is not used since it is does not currently support `BuildMethod: makefile`
- In the provided Javascript example, [esbuild](https://esbuild.github.io) is used for fast bundling

## Commands

|Command|Definition|Optional Arguments
|---|---|---|
|`make`|Install project dependencies. Edit `./scripts/install_dependences.sh` to customize||
|`make build`|Build code for every function|`buildArgs`<br/>`samBuildArgs`<br/>`syncManuallyChangedFunctionCode`|
|`make deploy`|Build code for every function and deploy stack|`buildArgs`<br/>`samBuildArgs`<br/>`samDeployArgs`<br/>`syncManuallyChangedFunctionCode`|
|`make update function=<LogicalResourceId>`|Build and update deployed code for Lambda function specified by CloudFormation Stack `<LogicalResourceId>`|`alias`<br/>`buildArgs`|
|`make tail function=<LogicalResourceId>`|Follow CloudWatch logs for Lambda function specified by CloudFormation Stack `<LogicalResourceId>`|`samLogsArgs`|
|`make iterate function=<LogicalResourceId>`|`make update function=...` followed by `make tail function=...`|`alias`<br/>`buildArgs`<br/>`samLogsArgs`|
|`make destroy`|Delete CloudFormation stack||

## Makefile Arguments

|Argument|Definition|
|---|---|
|`alias=<FunctionAliasName>`| When updating code for a single-function, publish a new function version and update the named function alias. Also delete alias' previous function version. |
|`buildArgs="<arg1> <arg2> ... <argN>"`|Arbitrary args for runtime-specific build command (e.g. `esbuild`)|
|`samBuildArgs="<arg1> <arg2> ... <argN>"`|Arbitrary args for `sam build` command|
|`samDeployArgs="<arg1> <arg2> ... <argN>"`|Arbitrary args for `sam deploy` command|
|`samLogsArgs="<arg1> <arg2> ... <argN>"`| Arbitrary args for `sam logs` command|
`syncManuallyChangedFunctionCode=n`|When performing a full build, avoid remote calls to check each function's status and the addition of a random data file to function code packages|