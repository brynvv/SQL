### This repo contains a demo of SQL skills using T-SQL in SSMS.

#### Including but not limited to
1. Temp tables
2. CTEs
3. OpenQuery
4. Joins
5. Aggregations
6. PIVOT function
7. Views
8. Stored procedures

#### The SQL script 'Tariff workflow - SQL' carries out data processing on a table selected from a linked server.

This was developed to mimic the processing carried out by a previously developed Alteryx workflow.

The repo contains a number of variations on how the initial table is accessed and stored, including creating as a view and stored procedure.

1. **Tariff workflow.sql** - Selects linked server data into a temp table (creating the main data set).
2. **Tariff workflow (openquery).sql** - Uses openquery to retrieve main data set.
3. **Testview1.sql** - Since temp tables are not compatible with views, creates a view for the second view to select from.
4. **Testview2.sql** - Selects from first view.
5. **Test_SP_Tariff.sql** - Like 1., except a stored procedure.

#### What is the script actually doing?

Taking individual predicted A-level grades (one row per grade, many rows per student) and producing a single row 'Grade Profile' for each student with predicted grades and tariff score.
