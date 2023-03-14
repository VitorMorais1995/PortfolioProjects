-- Let's compare the total cases vs total deaths
-- the death_percent column shows de probability to dye if you get sick 

UPDATE Project_Covid.dbo.Covid_Deaths
SET total_cases = NULLIF(CAST(total_cases AS FLOAT), 0)
SELECT
	location,
	CAST(date AS DATE) as date,
	CAST(total_cases AS FLOAT) AS total_cases,
	CAST(total_deaths AS FLOAT)AS total_deaths,
	((CAST(total_deaths AS FLOAT))/(CAST(total_cases AS FLOAT))*100) AS death_percent
FROM 
	Project_Covid.dbo.Covid_Deaths
-- let's see how this percentage is in Brazil
WHERE	
	location LIKE '%brazil%' 
ORDER BY 
	1,
	2 


-- Now, let's take a look at the total cases vs population
-- this query will show us the percentage of population that got Covid
UPDATE Project_Covid.dbo.Covid_Deaths
	SET total_cases = NULLIF(CAST(total_cases AS FLOAT), 0)
SELECT
	location,
	CAST(date AS DATE) as date,
	CAST(total_cases AS FLOAT) AS total_cases,
	CAST(population AS FLOAT)AS population,
	((CAST(total_cases AS FLOAT))/(CAST(population AS FLOAT))*100) AS percent_population_infected
FROM 
	Project_Covid.dbo.Covid_Deaths
-- let's see how this percentage is in Brazil
WHERE	
	location LIKE '%brazil%' 
ORDER BY 
	1,
	2 


-- Let's takea  look at the countries with highest infection rate compared to population
UPDATE Project_Covid.dbo.Covid_Deaths
	SET population = NULLIF(CAST(population AS FLOAT), 0)
SELECT
	location,
	CAST(population AS FLOAT) AS population,
	MAX(CAST(total_cases AS FLOAT)) AS highest_inf_Count,
	MAX(((CAST(total_cases AS FLOAT))/(CAST(population AS FLOAT))*100)) AS percent_pop_infect
FROM 
	Project_Covid.dbo.Covid_Deaths 
GROUP BY
	location,
	population
ORDER BY 
	4 DESC


-- Now, let's take a look at the countries with highest death counts per population
UPDATE Project_Covid.dbo.Covid_Deaths
	SET population = NULLIF(CAST(population AS FLOAT), 0)
SELECT
	location,
	CAST(population AS FLOAT) AS population,
	MAX(CAST(total_deaths AS FLOAT)) AS total_Deaths_Count
	--MAX(((CAST(total_deaths AS FLOAT))/(CAST(population AS FLOAT))*100)) AS percent_pop_infect
FROM 
	Project_Covid.dbo.Covid_Deaths 
GROUP BY
	location,
	population
ORDER BY 
	3 DESC


-- let's do the same thing for continents
-- showing the continets with the highest death count per pop.
SELECT
	continent,
	MAX(CAST(total_deaths AS FLOAT)) AS total_Deaths_Count
FROM 
	Project_Covid.dbo.Covid_Deaths 
WHERE
	continent <> ' '
GROUP BY
	continent
ORDER BY 
	2 DESC


-- Global numbers
-- toss this in tableau later
SELECT
	SUM(CAST(new_cases AS FLOAT)) AS sum_new_cases,
	SUM(CAST(new_deaths AS FLOAT)) AS sum_new_deaths,
	((SUM(CAST(new_deaths AS FLOAT))/(SUM(CAST(new_cases AS FLOAT))*100))) as Death_Perc
FROM 
	Project_Covid.dbo.Covid_Deaths
ORDER BY 
	1

-- ANOTHER GLOBAL ANALYSIS
SELECT
	CAST(date AS DATE) AS date,
	SUM(CAST(new_cases AS FLOAT)) AS sum_new_cases,
	SUM(CAST(new_deaths AS FLOAT)) AS sum_new_deaths
FROM 
	Project_Covid.dbo.Covid_Deaths
GROUP BY
	date
ORDER BY 
	1



-- NOW, LET'S TAKE A LOOK AT OUR OTHER TABLE, VACCS ONE
SELECT
	*
FROM
	Project_Covid.DBO.Covid_Vacs


-- now, let's join the two tables
SELECT
	*
FROM
	Project_Covid.DBO.Covid_Deaths AS Dea
JOIN 
	Project_Covid.DBO.Covid_Vacs AS Vacs
	ON Dea.location = Vacs.location
	AND Dea.date = Vacs.date

-- Looking at total population vs vacs
SELECT
	Dea.continent,
	Dea.location,
	CAST(Dea.date AS DATE) AS date,
	CAST(Dea.population as FLOAT) AS population,
	Vacs.new_vaccinations,
	SUM(CONVERT(FLOAT,Vacs.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS rolling_people_vac
FROM
	Project_Covid.DBO.Covid_Deaths AS Dea
JOIN 
	Project_Covid.DBO.Covid_Vacs AS Vacs
	ON Dea.location = Vacs.location
	AND Dea.date = Vacs.date
WHERE
	Dea.continent <> ' '
ORDER BY
	2,
	3



-- USE CT

WITH
	PopvsVacs (continent, location, date, population, new_vaccinations, rolling_people_vac) 
	AS
	(
	SELECT
	Dea.continent,
	Dea.location,
	CAST(Dea.date AS DATE) AS date,
	CAST(Dea.population as FLOAT) AS population,
	Vacs.new_vaccinations,
	SUM(CONVERT(FLOAT,Vacs.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS rolling_people_vac
FROM
	Project_Covid.DBO.Covid_Deaths AS Dea
JOIN 
	Project_Covid.DBO.Covid_Vacs AS Vacs
	ON Dea.location = Vacs.location
	AND Dea.date = Vacs.date
WHERE
	Dea.continent <> ' '
	)
SELECT
	*,
	(rolling_people_vac/population)*100 AS PERC
FROM 
	PopvsVacs




-- we can also use temp table

DROP TABLE IF EXISTS
	#PercentPopVac
CREATE TABLE
	#PercentPopVac
	(
	continent nvarchar(255),
	location nvarchar(255),
	Date datetime,
	population float,
	new_vaccinations float, 
	rolling_people_vac float
	)

INSERT INTO	
	#PercentPopVac
SELECT
	Dea.continent,
	Dea.location,
	CAST(Dea.date AS DATE) AS date,
	CAST(Dea.population as FLOAT) AS population,
	Vacs.new_vaccinations,
	SUM(CONVERT(FLOAT,Vacs.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS rolling_people_vac
FROM
	Project_Covid.DBO.Covid_Deaths AS Dea
JOIN 
	Project_Covid.DBO.Covid_Vacs AS Vacs
	ON Dea.location = Vacs.location
	AND Dea.date = Vacs.date

SELECT
	*--,
	--(rolling_people_vac/population)*100 AS PERC
FROM 
	#PercentPopVac


-- let's create a view 
CREATE VIEW
	PercentPopVac1 AS
SELECT 
	Dea.continent,
	Dea.location,
	CAST(Dea.date AS DATE) AS date,
	CAST(Dea.population as FLOAT) AS population,
	Vacs.new_vaccinations,
	SUM(CONVERT(FLOAT,Vacs.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS rolling_people_vac
FROM
	Project_Covid.DBO.Covid_Deaths AS Dea
JOIN 
	Project_Covid.DBO.Covid_Vacs AS Vacs
	ON Dea.location = Vacs.location
	AND Dea.date = Vacs.date


SELECT
	*
FROM
	PercentPopVac1