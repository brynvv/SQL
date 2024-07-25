/*-- Create tariff lookup table and populate with data
CREATE TABLE tariff_lkup 
(
	Grade VARCHAR(2) PRIMARY KEY,
	Tariff_points INT
);

INSERT INTO tariff_lkup (Grade, Tariff_points) VALUES
('A*', 56),
('A', 48),
('B', 40),
('C', 32),
('D', 24),
('E', 16);
*/

-- open query retrieves application data from linked server, including UCI2 (personal ID) and PGRD (predicted A Level grade)
WITH alevel_data AS (
	SELECT * FROM openquery(SIPR, '
	    select 
		
			SITS.SRS_SQF.SQF_UCI2,
			SITS.SRS_SQF.SQF_RSLT,
			SITS.SRS_SQF.SQF_QTYP,
			SITS.SRS_SQF.SQF_PGRD
		
		from SITS.SRS_SQF 
		
		where 
			SITS.SRS_SQF.SQF_RSLT = ''Incomplete'' 
			and (SITS.SRS_SQF.SQF_QTYP Like ''%A-Level%'' or SITS.SRS_SQF.SQF_QTYP Like ''%Advanced Level%'') 
			and SITS.SRS_SQF.SQF_QUAY = ''2024''
')), 

-- create tariff lookup table
tariff_lkup AS
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
		alevel_data.SQF_UCI2, 
		alevel_data.SQF_RSLT, 
		alevel_data.SQF_QTYP, 
		alevel_data.SQF_PGRD,  
		tariff_lkup.Grade, 
		tariff_lkup.Tariff_points 
	FROM 
		alevel_data

	INNER JOIN 
		tariff_lkup ON alevel_data.SQF_PGRD = tariff_lkup.Grade
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


-- numbers rows based on ordering
rownumbered_table AS 
(
	SELECT 
		SQF_UCI2, 
		SQF_RSLT, 
		SQF_QTYP, 
		SQF_PGRD, 
		Grade, 
		Tariff_points, 
		(row_number() OVER (partition by SQF_UCI2 ORDER BY Tariff_points DESC)) AS Rownumber 
	FROM 
		ordered_table
), 

-- selects fields and renames
select_renamed AS 
(
	SELECT 
		SQF_UCI2 AS UCI2, 
		SQF_RSLT AS Result_status, 
		SQF_QTYP AS Qualification_type, 
		Grade AS Predicted_Grade, 
		Tariff_points AS Predicted_tariff_points, 
		Rownumber
	FROM 
		rownumbered_table
), 


-- filters to only students with exactly 3 A level grades (chooses the highest scoring)
[3grades_only] AS 
(
	SELECT 
		* 
	FROM 
		select_renamed
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
	

	







