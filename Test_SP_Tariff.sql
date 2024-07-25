USE [Sandbox]
GO

/****** Object:  StoredProcedure [Core].[sp_Senior_Staff]    Script Date: 11/07/2024 13:07:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_BV_test_1] AS
-- select student ID and predicted A level data into temporary table
IF OBJECT_ID('tempdb..#alevel_data') IS NOT NULL DROP TABLE #alevel_data
SELECT TOP 100
	SQF_UCI2,
	SQF_RSLT,
	SQF_QTYP,
	SQF_PGRD
INTO 
	#alevel_data
FROM 
	[SIPR]..[SITS].[SRS_SQF]	
WHERE
	(SQF_QTYP LIKE '%A-Level%' OR SQF_QTYP LIKE '%Advanced Level%') 		
	AND SQF_QUAY LIKE '2015';

-- create tariff lookup table
WITH tariff_lkup AS
(
	SELECT * FROM
	(
		VALUES
			('A*', 56),
			('A', 48),
			('B', 40),
			('C', 32),
			('D', 24),
			('E', 16)
	)
		AS lkup(Grade, Tariff_points)
),

-- joins tariff score from lookup table
joined_tariffscore AS 
(
	SELECT 
		#alevel_data.SQF_UCI2, 
		#alevel_data.SQF_RSLT, 
		#alevel_data.SQF_QTYP, 
		#alevel_data.SQF_PGRD,  
		tariff_lkup.Grade, 
		tariff_lkup.Tariff_points 
	FROM 
		#alevel_data

	INNER JOIN 
		tariff_lkup ON #alevel_data.SQF_PGRD = tariff_lkup.Grade
), 

-- orders grades from high scoring to low scoring (in terms of tariff) for each student
ordered_table AS 
(
	SELECT TOP 100 PERCENT 
		* 
	FROM 
		joined_tariffscore
	ORDER BY 
		SQF_UCI2 ASC, Tariff_points DESC
), 

-- numbers rows based on ordering & renames fields
rownumbered_table AS 
(
	SELECT 
		SQF_UCI2 AS UCI2, 
		SQF_RSLT AS Result_status, 
		SQF_QTYP AS Qualification_type,
		Grade AS Predicted_Grade, 
		Tariff_points AS Predicted_tariff_points, 
		(row_number() OVER (partition by SQF_UCI2 ORDER BY Tariff_points DESC)) AS Rownumber 
	FROM 
		ordered_table
),  

-- filters to only students with exactly 3 A level grades (chooses the highest scoring)
[3grades_only] AS 
(
	SELECT 
		* 
	FROM 
		rownumbered_table
	WHERE 
		Rownumber <= 3
),

-- totals tariff scores for each student (TO BE JOINED TO GRADE PROFILE DATA)
sum_tariffpoints_lkup AS 
(
	SELECT 
		UCI2,
		SUM(Predicted_tariff_points) AS predicted_tariff_score
	FROM 
		[3grades_only]
	GROUP BY 
		UCI2
),

-- pivots to get grades 1, 2 and 3 as columns
gradepivot AS 
(
	SELECT
		UCI2,
		[1],
		[2],
		[3]
	FROM [3grades_only]

	PIVOT 
	(
		MAX(Predicted_Grade)
		FOR Rownumber in ([1],[2],[3])
	) AS pivottable
),

-- combines rows
agg_grades AS
(
	SELECT
		UCI2,
		MAX([1]) AS [Grade 1],
		MAX([2]) AS [Grade 2],
		MAX([3]) AS [Grade 3]
	FROM 
		[gradepivot]
	GROUP BY 
		UCI2
),

-- concatenates grade columns for grade profile, adds flag for if all 3 grade columns populated (TO BE JOINED TO TARIFF SCORE DATA)
gradeprofile AS
(
	SELECT
		UCI2,
		[Grade 1],
		[Grade 2],
		[Grade 3],
		CONCAT([Grade 1],[Grade 2],[Grade 3]) AS Grade_Profile,
		CASE WHEN ([Grade 3] IS NOT NULL) THEN 'Y' ELSE 'N' END AS [3_Grades?]
	FROM
		agg_grades
)

--create view [Sandbox].[BV_testview] as

-- joins tariff score and grade profile data on UCI2 and returns only students with exactly 3 A level grades
SELECT
	gradeprofile.UCI2,
	gradeprofile.[Grade 1],
	gradeprofile.[Grade 2],
	gradeprofile.[Grade 3],
	gradeprofile.Grade_Profile,
	gradeprofile.[3_Grades?],
	sum_tariffpoints_lkup.predicted_tariff_score
FROM 
	gradeprofile
INNER JOIN 
	sum_tariffpoints_lkup
ON 
	gradeprofile.UCI2 = sum_tariffpoints_lkup.UCI2
WHERE 
	gradeprofile.[3_Grades?] LIKE 'Y'



	







