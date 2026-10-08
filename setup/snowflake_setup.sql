-- One-time bootstrap. Run in a Snowsight worksheet as ACCOUNTADMIN.
-- Not part of the schemachange pipeline (it creates the things the pipeline needs).

USE ROLE ACCOUNTADMIN;

-- 1. Databases: one per environment, plus one for schemachange's change history
CREATE DATABASE IF NOT EXISTS DEV_DB;
CREATE DATABASE IF NOT EXISTS PROD_DB;
CREATE DATABASE IF NOT EXISTS DEPLOY_META;
CREATE SCHEMA IF NOT EXISTS DEPLOY_META.SCHEMACHANGE;

-- 2. Role used by the pipeline
CREATE ROLE IF NOT EXISTS CICD_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE CICD_ROLE;
GRANT ALL ON DATABASE DEV_DB      TO ROLE CICD_ROLE;
GRANT ALL ON DATABASE PROD_DB     TO ROLE CICD_ROLE;
GRANT ALL ON DATABASE DEPLOY_META TO ROLE CICD_ROLE;
GRANT ALL ON SCHEMA DEPLOY_META.SCHEMACHANGE TO ROLE CICD_ROLE;

-- 3. Service user (key-pair auth only, no password, so MFA is not required)
CREATE USER IF NOT EXISTS CICD_USER
  TYPE = SERVICE
  DEFAULT_ROLE = CICD_ROLE
  DEFAULT_WAREHOUSE = COMPUTE_WH;
GRANT ROLE CICD_ROLE TO USER CICD_USER;

-- 4. Attach your public key (paste the body of rsa_key.pub, no BEGIN/END lines)
-- ALTER USER CICD_USER SET RSA_PUBLIC_KEY = 'MIIBIjANBgkq...';

-- 5. Look up your account identifier for the SNOWFLAKE_ACCOUNT secret
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() AS snowflake_account;
