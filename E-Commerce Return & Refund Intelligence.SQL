CREATE DATABASE EcommerceIntelligence;

USE EcommerceIntelligence;

SELECT COUNT(*) AS total_records
FROM ecommerce_return_abuse_dataset;

SELECT TOP 10 *
FROM ecommerce_return_abuse_dataset ;        -- Check the total number of records

EXEC sp_help 'ecommerce_return_abuse_dataset';

                                              -- Check column names and data types
SELECT
 COLUMN_NAME,
 DATA_TYPE,
 IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ecommerce_return_abuse_dataset'
ORDER BY ORDINAL_POSITION;

                                                --Orders by product category
SELECT
    product_category,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.ecommerce_return_abuse_dataset
GROUP BY product_category
ORDER BY total_records DESC;
                                                       --Most common return reasons
SELECT
    return_reason,
    COUNT(*) AS return_records,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.ecommerce_return_abuse_dataset
WHERE return_reason IS NOT NULL
GROUP BY return_reason
ORDER BY return_records DESC;
                                     --Monthly order trends

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.ecommerce_return_abuse_dataset
WHERE order_date IS NOT NULL
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    order_year,
    order_month;

                                 --Customers with the most order records
SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders
FROM dbo.ecommerce_return_abuse_dataset
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_orders DESC;

                                    --Find possible duplicate records

SELECT
    order_id,
    customer_id,
    order_date,
    product_category,
    return_reason,
    COUNT(*) AS duplicate_count
FROM dbo.ecommerce_return_abuse_dataset
GROUP BY
    order_id,
    customer_id,
    order_date,
    product_category,
    return_reason
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
                                      --Overall dataset summary

WITH CategorySummary AS (
    SELECT
        product_category,
        COUNT(*) AS total_records,
        COUNT(DISTINCT order_id) AS unique_orders
    FROM dbo.ecommerce_return_abuse_dataset
    GROUP BY product_category
)
SELECT
    product_category,
    total_records,
    unique_orders
FROM CategorySummary
ORDER BY total_records DESC;

                                    --Rank product categories by record volume (CTE (Common Table Expression))
WITH MonthlySummary AS (
    SELECT
        DATEFROMPARTS(
            YEAR(order_date),
            MONTH(order_date),
            1
        ) AS order_month,
        COUNT(DISTINCT order_id) AS total_orders
    FROM dbo.ecommerce_return_abuse_dataset
    WHERE order_date IS NOT NULL
    GROUP BY
        YEAR(order_date),
        MONTH(order_date)
)
SELECT
    order_month,
    total_orders
FROM MonthlySummary
ORDER BY order_month;

                                  --Monthly trend using a CTE
WITH CustomerSummary AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM dbo.ecommerce_return_abuse_dataset
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_orders,
    RANK() OVER (
        ORDER BY total_orders DESC
    ) AS customer_rank
FROM CustomerSummary
ORDER BY customer_rank, customer_id;

                                         --Rank customers by order activity (Window functions)
WITH MonthlySummary AS (
    SELECT
        DATEFROMPARTS(
            YEAR(order_date),
            MONTH(order_date),
            1
        ) AS order_month,
        COUNT(DISTINCT order_id) AS total_orders
    FROM dbo.ecommerce_return_abuse_dataset
    WHERE order_date IS NOT NULL
    GROUP BY
        YEAR(order_date),
        MONTH(order_date)
)
SELECT
    order_month,
    total_orders,
    SUM(total_orders) OVER (
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_total_orders
FROM MonthlySummary
ORDER BY order_month;

                                                            --Running total of monthly orders
CREATE OR ALTER VIEW dbo.vw_Ecommerce_Return_Analysis
AS
SELECT
    order_id,
    customer_id,
    order_date,
    product_category,
    return_reason
FROM dbo.ecommerce_return_abuse_dataset;
GO

                                                             -- Test the reporting view
SELECT TOP 100 *
FROM dbo.vw_Ecommerce_Return_Analysis;
                                                              
CREATE  VIEW dbo.vw_Ecommerce_PowerBI
AS
SELECT
    order_id,
    customer_id,
    TRY_CONVERT(date, order_date) AS order_date,
    NULLIF(LTRIM(RTRIM(product_category)), '') 
        AS product_category,
    NULLIF(LTRIM(RTRIM(return_reason)), '') 
        AS return_reason
FROM dbo.ecommerce_return_abuse_dataset;
GO

                          --Test the view
SELECT TOP 20 *
FROM dbo.vw_Ecommerce_PowerBI;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM dbo.vw_Ecommerce_PowerBI;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'vw_Ecommerce_PowerBI'
ORDER BY ORDINAL_POSITION;


SELECT TOP (5) *
FROM ecommerce_return_abuse_dataset ;
