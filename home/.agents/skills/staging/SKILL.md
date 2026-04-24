---
name: staging
description: Run an AWS CLI investigation or task against the staging environment using the spritz-staging profile.
disable-model-invocation: true
argument-hint: <task description>
allowed-tools: Bash(aws *), Read, Grep, Glob
---

# Staging AWS Task

Using the AWS CLI, use the `spritz-staging` profile (`--profile spritz-staging`) to handle the following task, inferring the tools you will need to explore. Investigations often involve checking CloudWatch logs, but you may need ECS, RDS, S3, Lambda, or other services depending on the task.

If `spritz-staging` doesn't exist, check available profiles with `aws configure list-profiles` and ask the user which to use.

Task: $ARGUMENTS
