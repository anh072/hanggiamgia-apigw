SERVICE_NAME = giare
ENV ?= test
AWS_ROLE ?= arn:aws:iam::838080186947:role/deploy-role
APP_REGION = us-east-1

COMPOSE_RUN_AWS = docker-compose run --rm aws
COMPOSE_RUN_LINT = docker-compose run --rm lint
COMPOSE_RUN_PYTHON = docker-compose run --rm python

TAG ?= test
IMAGE_REPOSITORY = 838080186947.dkr.ecr.$(APP_REGION).amazonaws.com/jwt-authorizer

lint: dotenv
	$(COMPOSE_RUN_LINT) yamllint jwt-authorizer/
.PHONY: lint

validate: dotenv
	$(COMPOSE_RUN_AWS) make _validate
.PHONY: validate

localBuild: dotenv
	make _localBuild
.PHONY: localBuild

localTest: dotenv
	make _localTest
.PHONY: localTest

deployApp: dotenv
	make _deployApp
.PHONY: deployApp

# replaces .env with DOTENV if the variable is specified
dotenv:
ifdef DOTENV
	cp -f $(DOTENV) .env
else
	$(MAKE) .env
endif

# creates .env with .env.template if it doesn't exist already
.env:
	cp -f .env.template .env

_validate: _assumeRole
	aws --region $(APP_REGION) cloudformation validate-template --template-body file://jwt-authorizer/template.yaml

_localBuild:
	cd jwt-authorizer && sam build --parameter-overrides ImageTag=$(TAG)

_localTest:
	cd jwt-authorizer && sam local invoke --env-vars events/env.json -e events/event.json --debug "Authorizer"

_deployApp: _assumeRole
	cd jwt-authorizer && sam deploy --image-repository $(IMAGE_REPOSITORY) \
		--stack-name $(SERVICE_NAME)-$(ENV)-jwt-authorizer \
		--no-fail-on-empty-changeset \
		--no-confirm-changeset \
		--parameter-overrides ImageTag=$(TAG) \
		--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
		--region $(APP_REGION) \
		--debug


_assumeRole:
ifndef AWS_SESSION_TOKEN
	$(eval ROLE = "$(shell aws sts assume-role --role-arn "$(AWS_ROLE)" --role-session-name "deploy-assume-role" --query "Credentials.[AccessKeyId, SecretAccessKey, SessionToken]" --output text)")
	$(eval export AWS_ACCESS_KEY_ID = $(shell echo $(ROLE) | cut -f1))
	$(eval export AWS_SECRET_ACCESS_KEY = $(shell echo $(ROLE) | cut -f2))
	$(eval export AWS_SESSION_TOKEN = $(shell echo $(ROLE) | cut -f3))
endif