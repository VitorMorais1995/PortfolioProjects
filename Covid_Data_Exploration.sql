/* 
Covid 19 Data exploration 
I got this data in the website ....

skills used: CTE's, Temp Tables, Window Functions, Converting Data types, Creating views and Aggregate Functions.
*/

-- Let's take a look a the data we will work with
SELECT
	*
FROM
	Project_Covid.dbo.Covid_Deaths
ORDER BY
	3,
	4


-- Selecting the data that we need from this first table
SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	Project_Covid.dbo.Covid_Deaths
ORDER BY
	1,
	2


-- Let's compare the Total Cases vs Total Deaths
-- The death_percent column shows de probability to die if you get sick 
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
/*
to see how this percentage is in Brazil we just need to add the query below
WHERE	
	location LIKE '%brazil%' 
*/
ORDER BY 
	1,
	2 


-- Now, let's take a look at the Total Cases vs Population
-- This query will show us the percentage of population that got Covid
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
/*
to see how this percentage is in Brazil we just need to add the query below
WHERE	
	location LIKE '%brazil%' 
*/
ORDER BY 
	1,
	2


-- Looking at the countries with the Highest Infection Rate compared to Population
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


-- Looking at the countries with the Highest Death Count per Population
UPDATE Project_Covid.dbo.Covid_Deaths
	SET population = NULLIF(CAST(population AS FLOAT), 0)
SELECT
	location,
	CAST(population AS FLOAT) AS population,
	MAX(CAST(total_deaths AS FLOAT)) AS total_Deaths_Count
FROM 
	Project_Covid.dbo.Covid_Deaths 
GROUP BY
	location,
	population
ORDER BY 
	3 DESC


-- Now, I'll do the same thing for continents
-- Continents with the Highest Death Count per Population
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
SELECT
	SUM(CAST(new_cases AS FLOAT)) AS sum_new_cases,
	SUM(CAST(new_deaths AS FLOAT)) AS sum_new_deaths,
	((SUM(CAST(new_deaths AS FLOAT))/(SUM(CAST(new_cases AS FLOAT))*100))) as Death_Perc
FROM 
	Project_Covid.dbo.Covid_Deaths
ORDER BY 
	1


-- Another global analysis
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



-- Taking a look at Total Population vs Vaccinations
-- For this, we will need to use a join 
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



-- Using CTE to perform calculation on Partiton BY in previous query 
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




-- We can also use temp table to perfomr Calculation on Partition By in the previus query
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
	*,
	(rolling_people_vac/population)*100 AS PERC
FROM 
	#PercentPopVac


-- Creating a View to store data for later visualizations
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


