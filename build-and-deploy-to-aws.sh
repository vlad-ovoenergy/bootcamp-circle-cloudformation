#! /bin/sh
<<COMMENT
Deploys the app to a specified Auto Scaling Group. Procedure:

1. Builds the tarball using sbt
2. Uploads it to s3://bucket/${prefix}/
3. Doubles the size of the ASG
4. Waits until all instances are healthy
5. Terminates the old instances

Arguments:
- $1 = ASG name (required)
- $2 = S3 prefix (required)
COMMENT

set -x

asg_name=${1?'Auto scaling group name missing'}
s3_prefix=${2?'S3 prefix missing'}

# TODO use correct bucket name
s3_bucket=delete-me-bootcamp-test
artifact_filename=bootcamp-circle-cloudformation-0.1.0-SNAPSHOT.tgz
s3_location="s3://${s3_bucket}/${s3_prefix}/${artifact_filename}"

echo "Building artifact"
sbt universal:packageZipTarball

echo "Uplading artifact to $s3_location"
aws --region eu-west-1 s3 cp "target/universal/$artifact_filename" "$s3_location"

echo "Finding the running instances in ASG"
describe_asg_output=$(aws --region eu-west-1 autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$asg_name" \
    --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text)

if [ "$describe_asg_output" -eq "None" ]; then
  echo "Could not find any instances. Is the ASG name correct?"
  exit 1
fi

old_instances=($describe_asg_output)
echo "Found ${#old_instances[@]} instances in ASG: ${old_instances[@]}"

current_desired_cap=$(aws --region eu-west-1 autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$asg_name" \
    --query 'AutoScalingGroups[0].DesiredCapacity' --output text)
new_desired_cap=$(( current_desired_cap * 2 ))

echo "Doubling the size of the ASG to $new_desired_cap"
aws --region eu-west-1 autoscaling set-desired-capacity \
    --auto-scaling-group-name "$asg_name" \
    --desired-capacity "$new_desired_cap"

# TODO wait until all instances are healthy and InService

# TODO terminate old instances
