# sam build directory
AWS_SAM_BUILD_DIR = .aws-sam/build

# Passed in when "build-%" target is called by sam build. Explicitly set for updating a single function's code.
ARTIFACTS_DIR ?= $(AWS_SAM_BUILD_DIR)/$(function)

include .env.development

.PHONY:dependencies build-% build deploy iterate update tail

dependencies:
	./scripts/install_dependencies.sh

######################
# Stack-wide targets #
######################

# Pass samBuildArgs="<arg1> <arg2> ... <argN>" to specify arbitrary args for sam build command
samBuildArgs =

# Pass buildArgs="<arg1> <arg2> ... <argN>" to specify arbitrary args for runtime-specific build command (e.g. webpack)
buildArgs =

# Pass syncManuallyChangedFunctionCode=n in non-development environments to avoid remote calls to check function status
syncManuallyChangedFunctionCode = y

build:
	sam build --build-dir $(AWS_SAM_BUILD_DIR) $(samBuildArgs)

# Pass samDeployArgs="<arg1> <arg2> ... <argN>" to specify arbitrary args for sam deploy command
samDeployArgs =

deploy: build
	sam deploy --stack-name $(CLOUDFORMATION_STACK_NAME) $(samDeployArgs)

destroy:
	aws cloudformation delete-stack --stack-name $(CLOUDFORMATION_STACK_NAME)

#############################
# Function-specific targets #
#############################

# Pass function=<CloudFormation Function Resource Logical ID>
function =

# Optionally, pass alias=<Function Alias Name> to point alias at new function version
alias =

iterate: update tail

update: build-$(function)-code
	./scripts/update_function_code.sh $(CLOUDFORMATION_STACK_NAME) $(function) $(ARTIFACTS_DIR) $(alias)

# Pass samLogsArgs="<arg1> <arg2> ... <argN>" to specify arbitrary args for sam logs command
samLogsArgs =

tail:
	sam logs --stack-name $(CLOUDFORMATION_STACK_NAME) --name $(function) $(samLogsArgs)

########################################################
# Utility targets (not intended for direct invocation) #
########################################################
build-%: build-%-code
ifeq ($(syncManuallyChangedFunctionCode),y)
	./scripts/ensure_cfn_will_resync_function_code.sh $(CLOUDFORMATION_STACK_NAME) $(@:build-%=%) $(ARTIFACTS_DIR)
else
	@echo
endif

build-%-code:
	./scripts/build_function_code.sh ./src/functions/$(@:build-%-code=%) $(ARTIFACTS_DIR) $(buildArgs) > /tmp/$(shell date +%Y%m%d%H%M%S)-make-$@.log