/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME; -- check the ETL duration time how much time it takes
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '================================================================================================================================';
		PRINT 'Loading Silver Layer';
		PRINT '================================================================================================================================';

		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		-- BUILD & LOAD silver.crm_cust_info 
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_first_name,
		cst_last_name,
		cst_marital_status,
		cst_gndr,
		cst_create_date)

		SELECT cst_id,
			   cst_key,
			   TRIM(cst_first_name) AS cst_first_name,
			   TRIM(cst_last_name) AS cst_last_name,
			   CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
					WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
					ELSE 'n/a'
			   END AS cst_marital_status,-- Normalize marital status values to readable format
			   CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
					WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
					ELSE 'n/a'
			   END AS cst_gndr, -- Normalize gender values to readable format
			   cst_create_date  
		FROM   (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
				FROM   bronze.crm_cust_info
				WHERE  cst_id IS NOT NULL
		)t
		WHERE  flag_last = 1; -- Select the most recent record per customer 
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.crm_cust_info;

		--BUILD & LOAD silver.crm_prd_info 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)
		SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, -- Extract Category ID
		SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, -- Extract product id
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,
		CASE UPPER(TRIM(prd_line))
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales' 
			 WHEN 'T' THEN 'Touring'
			 ELSE 'n/a'
		END AS prd_line, -- Map product line into descriptive values
		CAST(prd_start_dt AS DATE) AS prd_start_dt ,
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt -- Calculate end date as one day before the next start date
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.crm_prd_info;

		--BUILD & LOAD silver.crm_sales_details
		PRINT '>> Truncating Table: silver.crm_sales_details';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
			 THEN sls_quantity * ABS(sls_price)
			 ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <=0
			 THEN sls_sales/NULLIF(sls_quantity,0)
			 ELSE sls_price
		END AS sls_price
		from bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.crm_sales_details;

		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		
		--BUILD & LOAD silver.erp_cust_az12 
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- Remove 'NAS' prefix if present
			 ELSE cid
		END AS cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			 ELSE bdate
		END AS bdate, -- Set Future Birthdates to NULL
		CASE WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'Male'
			 WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'Female'
			 ELSE 'n/a'
		END AS gen -- Normalize gender values and handle unknown cases
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.erp_cust_az12;

		--BUILD & LOAD silver.erp_loc_a101
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT
		REPLACE(cid,'-','') cid,
		CASE WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			 ELSE TRIM(cntry)
		END AS cntry -- Normalize and Handle missing or blank country codes
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.erp_loc_a101;

		--BUILD & LOAD silver.erp_px_cat_g1v2
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		SET @start_time = GETDATE();
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
		id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.		
		-- SELECT * FROM silver.erp_px_cat_g1v2;
		SET @batch_end_time = GETDATE();		
		
		DECLARE @total_seconds INT;
		SET @total_seconds = DATEDIFF(second, @batch_start_time, @batch_end_time);
		PRINT '>> Total Whole Batch Duration: ' 
		+ CAST(@total_seconds / 3600 AS NVARCHAR) + ' hours'
		+ CAST((@total_seconds % 3600) / 60 AS NVARCHAR) + ' minutes'
		+ CAST(@total_seconds % 60 AS NVARCHAR) + ' seconds';
		PRINT '>> Whole Batch Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

	END TRY
	BEGIN CATCH
		PRINT '================================================================================================================================';
		PRINT 'ERROR OCCUR DURING LOADING SILVER LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR); -- Casting the data type into nvarchar
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '================================================================================================================================';
	END CATCH
END
