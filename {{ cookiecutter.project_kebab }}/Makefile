# sam build directory
AWS_SAM_BUILD_DIR = .aws-sam/build

# Passed in when "build-%" target is called by sam build. Explicitly set for updating a single function's code.
ARTIFACTS_DIR ?= $(AWS_SAM_BUILD_DIR)/$(function)

include .env.development

.PHONY: dependencies build-% build-%-code build deploy iterate update tail

alias=
buildArgs=
function=
samBuildArgs=
samDeployArgs=
samLogsArgs=
syncManuallyChangedFunctionCode=y

dependencies:
	./scripts/install_dependencies.sh

######################
# Stack-wide targets #
######################

build:
	sam build --build-dir $(AWS_SAM_BUILD_DIR) $(samBuildArgs)

deploy: build
	sam deploy --stack-name $(CLOUDFORMATION_STACK_NAME) $(samDeployArgs)

destroy:
	aws cloudformation delete-stack --stack-name $(CLOUDFORMATION_STACK_NAME)

#############################
# Function-specific targets #
#############################

iterate: update tail

update: build-$(function)-code
	./scripts/update_function_code.sh $(CLOUDFORMATION_STACK_NAME) $(function) $(ARTIFACTS_DIR) $(alias)

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