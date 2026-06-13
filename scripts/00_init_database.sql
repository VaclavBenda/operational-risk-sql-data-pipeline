/*
====================================================================
					00_init_database.sql
====================================================================
Script Purpose:
	Creates the OperationalRiskDB database and the main schemas used in this
	project: bronze, silver and gold.

	This script represents the initial setup step of the project.

WARNING:
	Running this script will drop the existing OperationalRiskDB database if it
	already exists. Use it only when you want to recreate the project from scratch.

Usage Example:
	Run this script first before running any DDL or load procedures.
====================================================================
*/

USE master;
GO

-- Drop and recreate the database.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'OperationalRiskDB')
BEGIN
	ALTER DATABASE OperationalRiskDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE OperationalRiskDB;
END;
GO


CREATE DATABASE OperationalRiskDB;
GO

USE OperationalRiskDB;
GO

-- Create Medallion-style schemas.
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;