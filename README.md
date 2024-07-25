This repo contains a demo of SQL skills using T-SQL in SSMS.

Including but not limited to
1. Temp tables
2. CTEs
3. OpenQuery
4. Joins
5. Aggregations
6. PIVOT function
7. Views
8. Stored procedures

The SQL script 'Tariff workflow - SQL' carries out data processing originally performed by an Alteryx workflow.

It is contained in this repo with a number of variations on how the 'main' dataset is stored and accessed, with examples of storing as a view and stored procedure.

1. Tariff workflow - SQL.sql - Selects linked server data into a temp table (for main data set).
2. Tariff workflow - SQL (openquery).sql - Uses openquery to retrieve main data set.
3. Testview1.sql - Since temp tables are not compatible with views, creates a view for the second view to select from.
4. Testview2.sql - Selects from first view.
5. Test_SP_Tariff.sql - Like 1., except a stored procedure.
