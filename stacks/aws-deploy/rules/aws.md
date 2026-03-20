---
globs: "cdk.json,**/cdk/**/*.ts,template.yaml,template.yml,samconfig.toml,**/cloudformation/**"
---

# AWS Deploy Rules

## Stack
AWS CDK (TypeScript) or SAM/CloudFormation. Infrastructure as code only — no console ClickOps.

## CDK Patterns
- One stack per concern: `NetworkStack`, `DatabaseStack`, `ApiStack`
- Cross-stack references via `CfnOutput` + `Fn.importValue`
- Use L2 constructs (e.g., `new lambda.Function`) over L1 (`new CfnFunction`)
- `cdk diff` before every `cdk deploy` — review changes
- Tag all resources: `Tags.of(this).add('Environment', props.env)`

## SAM/CloudFormation Patterns
- `template.yaml` at project root with `AWS::Serverless::Function`
- `sam build && sam deploy --guided` for first deploy
- Parameters for environment-specific values (never hardcode ARNs)
- Use `!Ref` and `!GetAtt` for resource references, never raw strings

## Security
- IAM: least-privilege policies — never `Action: "*"` or `Resource: "*"`
- Secrets in AWS Secrets Manager or SSM Parameter Store (not env vars in templates)
- VPC for databases and internal services
- Enable CloudTrail and access logging on S3/API Gateway

## Testing
- `cdk synth` to validate templates without deploying
- `sam validate` for SAM templates
- Integration tests against deployed stack (use test stage/account)
- `aws cloudformation validate-template` for raw CloudFormation

## Common Mistakes
- Circular dependencies between stacks → split resources or use `CfnOutput`
- Lambda cold starts with VPC — use provisioned concurrency or optimize
- Missing `DeletionPolicy: Retain` on stateful resources (databases, S3)
- CloudFormation drift: manual console changes break next deploy
