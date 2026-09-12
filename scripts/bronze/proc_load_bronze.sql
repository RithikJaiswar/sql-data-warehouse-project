/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
-- Inserting Bulk Data 
--TRUNCATE -> quickly delete all rows from a table, resetting is to an empty state.

--EXEC bronze.load_bronze;

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME; -- check the ETL duration time how much time it takes
	BEGIN TRY
		PRINT '================================================================================================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================================================================================================';

		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		
		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		-- Quality Check -> check that the data has not shifted and is in the correct columns.
		SELECT * FROM bronze.crm_cust_info

		--2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			--FIELDQUOTE = ',',
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();

		PRINT 'Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		SELECT * FROM bronze.crm_prd_info;

		--3
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		SELECT * FROM bronze.crm_sales_details;


		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------------------------------------------------------------------------------------------';
		--4 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_CUST_AZ12';
		TRUNCATE TABLE bronze.erp_CUST_AZ12;

		PRINT '>> Inserting Data into: bronze.erp_CUST_AZ12';
		BULK INSERT bronze.erp_CUST_AZ12
		FROM 'C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		--5 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_LOC_A101';
		TRUNCATE TABLE bronze.erp_LOC_A101;

		PRINT '>> Inserting Data into: bronze.erp_LOC_A101';
		BULK INSERT bronze.erp_LOC_A101
		FROM 'C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		--6 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_PX_CAT_G1V2';
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

		PRINT '>> Inserting Data into: bronze.erp_PX_CAT_G1V2';
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM "C:\Users\RITHIK\Desktop\Data Science\SQL\Sql Data_Warehouse\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv"
		WITH (
			FIRSTROW = 2, -- data will start from 2nd row
			FIELDTERMINATOR = ',', -- file separator / Delimeter
			TABLOCK -- locking entire table during loading it / lock the whole table
		);
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';
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
		PRINT 'ERROR OCCUR DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR); -- Casting the data type into nvarchar
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '================================================================================================================================';
	END CATCH
END
