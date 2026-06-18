# Security Policy

## reporting a vulnerability

please use [GitHub's private vulnerability reporting](https://github.com/vegcom/cozy-salt/security/advisories/new) — don't open a public issue for security stuff

we'll acknowledge within a few days and keep you updated as we work on it

## scope

cozy-salt is an IaC provisioning tool. relevant security concerns include:

- credential or secret exposure in states/pillars
- privilege escalation in provisioned configs
- insecure defaults that could affect deployed systems

## what's not in scope

- vulnerabilities in salt itself (report to [saltproject.io](https://saltproject.io))
- issues with your specific deployment/infrastructure
