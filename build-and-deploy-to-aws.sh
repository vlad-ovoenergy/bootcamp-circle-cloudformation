#! /bin/bash
<<COMMENT
Deploys the app to a specified Auto Scaling Group. Procedure:

1. Builds the artifact using sbt
2. Uploads it to s3://bucket/${prefix}/
3. Doubles the size of the ASG
4. Waits until all instances are healthy
5. Terminates the old instances

Arguments:
- $1 = ASG name (required)
- $2 = S3 prefix (required)

The S3 prefix should match the parameter you pass to CloudFormation when creating the Auto Scaling Group.

Example:
./build-and-deploy-to-aws.sh todo-app-chris-asg-AutoScalingGroup-15JGK1GPHQD6D chris

COMMENT

asg_name=${1?'Auto scaling group name missing'}
s3_prefix=${2?'S3 prefix missing'}

s3_bucket=ovo-bootcamp-artifacts
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

if [ "$describe_asg_output" == "None" ]; then
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

while true; do
  healthy_instances_output=$(aws --region eu-west-1 autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$asg_name" \
    --query 'AutoScalingGroups[0].Instances[?HealthStatus==`Healthy` && LifecycleState==`InService`].InstanceId' \
    --output text)
  if [ "$healthy_instances_output" == "None" ]; then
    healthy_instances=()
  else
    healthy_instances=($healthy_instances_output)
  fi

  if [ ${#healthy_instances[@]} -lt $new_desired_cap ]; then
    echo "Expected $new_desired_cap heathy in-service instances but we only have ${#healthy_instances[@]}. Waiting 30 seconds..."
    sleep 30
  else
    echo "Success! We now have $new_desired_cap healthy instances in service."
    break
  fi
done

for old_instance in "${old_instances[@]}"; do
  echo "Terminating old instance $old_instance"
  aws --region eu-west-1 autoscaling terminate-instance-in-auto-scaling-group \
      --instance-id "$old_instance" \
      --should-decrement-desired-capacity
done

echo "Finished."
