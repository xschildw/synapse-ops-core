#!/bin/bash
#
# Build Synapse stack in new VPC.
#

set +x

# dev, staging or prod
STACK=${1}

# example: 544
INSTANCE=${2}

# example: 544.0
REPO_AND_WORKERS_VERSION=${3}

# example: 0
REPO_BEANSTALK_VERSION=${4}

# example: 544.0-4-gd18c3167f2
PORTAL_VERSION=${5}

# example: 0
PORTAL_BEANSTALK_VERSION=${6}

# example Blue
VPC_SUBNET_COLOR=${7}

# example 5.5.0
BEANSTALK_PLATFORM_VERSION=${8}

# BEANSTALK or ECS_FARGATE
DEPLOYMENT_TARGET=${9}

# Folder containing source code
SRC_PATH=${10}

# Need to get the URL of the Cognito Pool from the Global Resources Stack
COGNITO_USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name synapse-${STACK}-global-resources --query "Stacks[0].Outputs[?OutputKey=='CognitoUserPoolId'].OutputValue" --output text)
COGNITO_DISCOVERY_DOCUMENT=https://cognito-idp.us-east-1.amazonaws.com/${COGNITO_USER_POOL_ID}/.well-known/openid-configuration

cd $SRC_PATH

mvn clean install

CMD_PROPS=""
CMD_PROPS+=" -Dorg.sagebionetworks.stack=$STACK"
CMD_PROPS+=" -Dorg.sagebionetworks.instance=$INSTANCE"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.version.repo=$REPO_AND_WORKERS_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.version.workers=$REPO_AND_WORKERS_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.version.portal=$PORTAL_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.vpc.subnet.color=$VPC_SUBNET_COLOR"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.number.repo=$REPO_BEANSTALK_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.number.workers=0"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.number.portal=$PORTAL_BEANSTALK_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.storage.type=gp3"
CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.iops=-1"
CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.multi.az=true"
CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.instance.count=1"
CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.storage.type=gp3"
CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.iops=-1"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.image.version.amazonlinux=$BEANSTALK_PLATFORM_VERSION"
CMD_PROPS+=" -Dorg.sagebionetworks.docs.deploy=false"
CMD_PROPS+=" -Dorg.sagebionetworks.docs.source=dev.release.rest.doc.sagebase.org"
CMD_PROPS+=" -Dorg.sagebionetworks.docs.destination=rest-docs.synapse.org/rest"
CMD_PROPS+=" -Dorg.sagebionetworks.oauth2.sagebio.discoveryDocument=$COGNITO_DISCOVERY_DOCUMENT"
CMD_PROPS+=" -Dorg.sagebionetworks.deployment.target=$DEPLOYMENT_TARGET"
if [[ "prod" == "$STACK" ]]; then
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.instance.type=m6g.large"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.instance.memory=4096"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.instance.class=db.r6g.2xlarge"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.allocated.storage=512"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.max.allocated.storage=1280"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.instance.class=db.r6g.4xlarge"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.allocated.storage=3072"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.max.allocated.storage=4096"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.repo=12"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.repo=6"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.ssl.arn.repo=arn:aws:acm:us-east-1:325565585839:certificate/a53c76a0-c54b-4538-81f0-028e28d8e812"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.repo=prod.sagebase.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.workers=12"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.workers=8"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.ssl.arn.workers=arn:aws:acm:us-east-1:325565585839:certificate/a53c76a0-c54b-4538-81f0-028e28d8e812"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.workers=prod.sagebase.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.portal=8"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.portal=3"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.ssl.arn.portal=arn:aws:acm:us-east-1:325565585839:certificate/7c42c355-3d69-4537-a5e6-428212db646f"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.portal=synapse.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.doi.datacite.enabled=true"
  CMD_PROPS+=" -Dorg.sagebionetworks.repositoryservice.endpoint.prod=https://repo-prod.prod.sagebase.org/repo/v1"
  CMD_PROPS+=" -Dorg.sagebionetworks.enable.rds.enhanced.monitoring=true"
  CMD_PROPS+=" -Dorg.sagebionetworks.vpc.ops.export.prefix=us-east-1-synapse-ops-vpc-v2"
else
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.instance.type=t4g.large"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.instance.class=db.t4g.medium"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.allocated.storage=128"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.rds.max.allocated.storage=256"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.instance.class=db.t4g.large"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.allocated.storage=256"
  CMD_PROPS+=" -Dorg.sagebionetworks.tables.rds.max.allocated.storage=512"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.repo=4"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.repo=2"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.repo=dev.sagebase.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.workers=4"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.workers=2"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.workers=dev.sagebase.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.max.instances.portal=2"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.min.instances.portal=2"
  CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.ssl.arn.portal=arn:aws:acm:us-east-1:449435941126:certificate/7d391bab-0663-4438-a418-2422b051adc7"
  CMD_PROPS+=" -Dorg.sagebionetworks.route.53.hosted.zone.portal=dev.sagebase.org"
  CMD_PROPS+=" -Dorg.sagebionetworks.enable.rds.enhanced.monitoring=false"
  CMD_PROPS+=" -Dorg.sagebionetworks.repo.time.to.live.hours=0"
fi
export CMD_PROPS

java -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.template.repo.RepositoryBuilderMain
