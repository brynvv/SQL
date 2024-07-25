USE [Sandbox]
GO

CREATE VIEW [dbo].[BV_testview_1] as


SELECT TOP 100
	SQF_UCI2,
	SQF_RSLT,
	SQF_QTYP,
	SQF_PGRD

FROM 
	[SIPR]..[SITS].[SRS_SQF]	
WHERE
	(SQF_QTYP LIKE '%A-Level%' OR SQF_QTYP LIKE '%Advanced Level%') 		
	AND SQF_QUAY LIKE '2015'