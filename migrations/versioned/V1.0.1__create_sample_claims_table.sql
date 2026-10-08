CREATE TABLE IF NOT EXISTS BRONZE.SAMPLE_CLAIMS (
    claim_id       NUMBER        NOT NULL,
    customer_name  VARCHAR(100),
    product        VARCHAR(100),
    claim_amount   NUMBER(10, 2),
    claim_date     DATE,
    status         VARCHAR(20),
    loaded_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
