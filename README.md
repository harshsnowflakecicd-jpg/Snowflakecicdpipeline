# snowflake-cicd

SQL change management for Snowflake using [schemachange](https://github.com/Snowflake-Labs/schemachange) and GitHub Actions.

## Layout

```
migrations/
  versioned/   V1.0.0__desc.sql   run once, in version order (tables, schema changes)
  repeatable/  R__desc.sql        re-run when content changes (views, procedures, functions)
  before_after/                   optional A__ scripts that run every deploy
tests/check_naming.py             CI naming/duplicate-version check
schemachange-config.yml           schemachange settings
.github/workflows/
  ci.yml       on pull request: sqlfluff lint, naming check, schemachange dry run on DEV
  deploy.yml   on merge to main: deploy DEV, then PROD (after approval)
```

## One-time Snowflake setup

Run as ACCOUNTADMIN (adjust names to your standards):

```sql
CREATE ROLE IF NOT EXISTS CICD_ROLE;
CREATE USER IF NOT EXISTS CICD_USER TYPE = SERVICE DEFAULT_ROLE = CICD_ROLE;
GRANT ROLE CICD_ROLE TO USER CICD_USER;

CREATE DATABASE IF NOT EXISTS DEPLOY_META;   -- holds schemachange change history
CREATE SCHEMA IF NOT EXISTS DEPLOY_META.SCHEMACHANGE;
GRANT ALL ON DATABASE DEPLOY_META TO ROLE CICD_ROLE;
GRANT ALL ON SCHEMA DEPLOY_META.SCHEMACHANGE TO ROLE CICD_ROLE;

GRANT USAGE ON WAREHOUSE <your_wh> TO ROLE CICD_ROLE;
GRANT ALL ON DATABASE <your_dev_db>  TO ROLE CICD_ROLE;
GRANT ALL ON DATABASE <your_prod_db> TO ROLE CICD_ROLE;
```

### Key-pair auth (recommended for CI)

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

```sql
ALTER USER CICD_USER SET RSA_PUBLIC_KEY = '<contents of rsa_key.pub without header/footer>';
```

Never commit `rsa_key.p8` (it is in `.gitignore`).

## GitHub setup

1. Create the repo and push (see below).
2. **Settings > Environments**: create `dev` and `prod`. Add required reviewers on `prod` for an approval gate.
3. Per environment, add:
   - Secrets: `SNOWFLAKE_ACCOUNT` (e.g. `orgname-accountname`), `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY` (full contents of the .p8 file)
   - Variables: `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`
4. For `ci.yml` (runs on PRs, outside an environment), add repo-level secrets `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY` and variables `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE_DEV`.
5. Protect `main`: require PRs and the `CI / validate` check.

```bash
git remote add origin https://github.com/<you>/snowflake-cicd.git
git push -u origin main
```

## Workflow

1. Branch, add a `V...` or edit an `R__...` script, open a PR.
2. CI lints and dry-runs against DEV.
3. Merge to `main` deploys DEV, then PROD after approval.

Use `{{ env }}` in scripts for environment-specific values.

## Local run

```bash
pip install -r requirements.txt
export SNOWFLAKE_ACCOUNT=... SNOWFLAKE_USER=... SNOWFLAKE_ROLE=CICD_ROLE \
       SNOWFLAKE_WAREHOUSE=... SNOWFLAKE_DATABASE=... SNOWFLAKE_PRIVATE_KEY_PATH=/path/to/rsa_key.p8
schemachange deploy --config-folder . --dry-run
```

> Pin and test your schemachange version; CLI flags and env var handling have changed between major versions.
