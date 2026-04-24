---
name: prod
description: Run an AWS CLI investigation or task against the production environment using the spritz-prod profile.
disable-model-invocation: true
argument-hint: <task description>
allowed-tools: Bash(aws *), Read, Grep, Glob
---

# Production AWS Task

Using the AWS CLI, use the `spritz-prod` profile (`--profile spritz-prod`) to handle the following task, inferring the tools you will need to explore. Investigations often involve checking CloudWatch logs, but you may need ECS, RDS, S3, Lambda, or other services depending on the task.

This is production — prefer read-only commands. Confirm with the user before any mutating action.

If `spritz-prod` doesn't exist, check available profiles with `aws configure list-profiles` and ask the user which to use.

Task: $ARGUMENTS
