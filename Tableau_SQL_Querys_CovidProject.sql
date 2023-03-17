/*
Querys used for Tableau project

*/

--1
-- Global numbers
SELECT
	SUM(CAST(new_cases AS FLOAT)) AS sum_new_cases,
	SUM(CAST(new_deaths AS FLOAT)) AS sum_new_deaths,
	((SUM(CAST(new_deaths AS FLOAT))/(SUM(CAST(new_cases AS FLOAT))))*100) as Death_Perc
FROM 
	Project_Covid.dbo.Covid_Deaths
ORDER BY 
	1,
	2

--2
-- Continents vs Deaths 
SELECT
	location,
	SUM(CAST(new_deaths AS FLOAT)) AS Total_Death_Count
FROM 
	Project_Covid.dbo.Covid_Deaths
WHERE
	continent = ' ' AND
	location not in ('World', 'European Union', 'international','High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY
	location
ORDER BY
	Total_Death_Count DESC
	

-- 3
-- Map with Death Count and Percent Population that Died
SELECT
	location,
	SUM(CAST(new_deaths AS FLOAT)) AS Total_Death_Count,
	MAX((CAST(total_deaths AS FLOAT))/(CAST(population AS FLOAT))*100) AS percent_population_that_died
FROM 
	Project_Covid.dbo.Covid_Deaths
GROUP BY
	location
ORDER BY
	Total_Death_Count DESC


--4
-- Country Death Count per year
SELECT
	location,
	CAST(population AS FLOAT) AS population,
	CAST(date AS DATE) as date,
	CAST(total_deaths AS FLOAT) AS Deaths_Count,
	MAX((CAST(total_deaths AS FLOAT))/(CAST(population AS FLOAT))*100) AS percent_population_died
FROM 
	Project_Covid.dbo.Covid_Deaths
GROUP BY
	location,
	population,
	date,
	total_deaths
ORDER BY 
	percent_population_died DESC