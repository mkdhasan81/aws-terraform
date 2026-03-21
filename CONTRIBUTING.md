# Contributing

## Branching

- `main` — production-ready, protected. No direct pushes.
- Feature branches: `feat/<description>`
- Bugfix branches: `fix/<description>`

## Workflow

1. Branch off `main`
2. Make changes, run local checks (see below)
3. Open a pull request — CI runs automatically
4. Get at least one approval before merging

## Local Checks (run before opening a PR)

```bash
# Format all .tf files
terraform fmt -recursive

# Validate the environment you changed
cd environments/dev
terraform init -backend=false
terraform validate
```

## Module Changes

- Every module must have `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`
- All variables must have `type` and `description`
- Use `validation` blocks for variables with constraints
- Security group rules between resources must use SG ID references, not CIDR blocks

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add RDS module
fix: correct NAT gateway subnet reference
chore: update AWS provider to 5.1
docs: update vpc module README
```
