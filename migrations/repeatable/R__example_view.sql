-- Repeatable script: re-runs whenever its contents change. Use for views, procedures, functions.
-- Replace this placeholder with your own objects.

CREATE OR REPLACE VIEW GOLD.V_EXAMPLE AS
SELECT CURRENT_TIMESTAMP() AS deployed_at, '{{ env }}' AS environment;
