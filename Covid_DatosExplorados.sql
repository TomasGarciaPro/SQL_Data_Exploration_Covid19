--Looking at the probability of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deaths_percentage
FROM Covid19..CovidDeaths
WHERE total_cases IS NOT NULL AND location LIKE 'Chile'
ORDER BY 1, 2


-- Looking the likelihood of dying per country in 2022-03-02 ordered by percentage of deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deaths_percentage
FROM Covid19..CovidDeaths
WHERE total_cases IS NOT NULL AND date LIKE '2022-03-02'
ORDER BY 5 DESC


-- Looking at the percentage of cases per population

SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM Covid19..CovidDeaths
WHERE location LIKE 'Chile'
ORDER BY 1, 2;


-- Top twenty countries with the highest infection ratio by population

SELECT TOP 20 location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM Covid19..CovidDeaths
WHERE date LIKE '2022-03-02'
ORDER BY 5 DESC;


-- Group by to looking the cases_percentage

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentagePopulationInfected
FROM Covid19..CovidDeaths GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- Showing the countries with highest death count by population

SELECT location, population, MAX(total_deaths) as HighestDeathsCount, MAX(total_deaths/population)*100 as PercentagePopulationDeath
FROM Covid19..CovidDeaths GROUP BY location, population
ORDER BY PercentagePopulationDeath DESC


-- Showing the countries with highest deaths

SELECT location, MAX(CAST(total_deaths AS INTEGER)) as DeathsCount
FROM Covid19..CovidDeaths GROUP BY location
ORDER BY DeathsCount DESC


-- Showing the countries with highest deaths filter

SELECT location, MAX(CAST(total_deaths AS INTEGER)) as DeathsCount
FROM Covid19..CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathsCount DESC


-- Showing the deaths count by aggrupations

SELECT location, MAX(CAST(total_deaths AS INTEGER)) as DeathsCount
FROM Covid19..CovidDeaths 
WHERE continent IS NULL
GROUP BY location
ORDER BY DeathsCount DESC


-- Total cases by date

SELECT date, SUM(new_cases) as Total_cases
FROM Covid19..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total deaths percentage by date

SELECT date, SUM(new_cases) as Total_cases, SUM(CAST(new_deaths AS int)) as Total_deaths, 100*SUM(CAST(new_deaths AS int))/SUM(new_cases) AS TotalDeathsPercentage
FROM Covid19..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total deaths percentage

SELECT SUM(new_cases) as Total_cases, SUM(CAST(new_deaths AS int)) as Total_deaths, 100*SUM(CAST(new_deaths AS int))/SUM(new_cases) AS TotalDeathsPercentage
FROM Covid19..CovidDeaths
WHERE continent IS NOT NULL




-- JOIN TABLES --

SELECT * 
FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
ON DEA.date = VAC.date AND
DEA.location = VAC.location


-- Looking at the new vaccinations per day

SELECT DEA.date, DEA.continent, DEA.location,DEA.population, DEA.total_deaths, VAC.new_vaccinations FROM
Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
ON DEA.date = VAC.date AND
DEA.location = VAC.location
WHERE DEA.continent IS NOT NULL
ORDER BY DEA.location, DEA.date


-- Looking at the cumulative quantity new vaccinations per day

SELECT DEA.date, DEA.continent, DEA.location,DEA.population, DEA.total_deaths, VAC.new_vaccinations, 
SUM(CONVERT(bigint, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS CumulativeVaccinations
FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
ON DEA.date = VAC.date AND
DEA.location = VAC.location
WHERE DEA.continent IS NOT NULL AND DEA.location LIKE 'Chile'
ORDER BY DEA.location, DEA.date


-- Looking at the cumulative percentage new vaccinations per day

WITH PopvsVac (date, continent, location, population, total_deaths, vaccinations, CumulativeVaccinations)
AS
(
SELECT DEA.date, DEA.continent, DEA.location,DEA.population, DEA.total_deaths, VAC.new_vaccinations, 
SUM(CONVERT(bigint, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS CumulativeVaccinations
FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
ON DEA.date = VAC.date AND
DEA.location = VAC.location
WHERE DEA.continent IS NOT NULL AND DEA.location LIKE 'Colombia'
)
SELECT *, (CumulativeVaccinations/population)*100 AS CumulativeVaccinationsPercentage
FROM PopvsVac


-- Looking at the cumulative percentage new vaccinations per day with a temp table

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated

(
Date date,
Continent NVARCHAR(255),
Location NVARCHAR(255),
Population NUMERIC,
New_vaccinations NUMERIC,
CumulativeVaccinations BIGINT
)

INSERT INTO #PercentPopulationVaccinated

SELECT DEA.date, DEA.continent, DEA.location, DEA.population, VAC.new_vaccinations, 
SUM(CONVERT(bigint, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS CumulativeVaccinations
FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
ON DEA.date = VAC.date AND
DEA.location = VAC.location
WHERE DEA.continent IS NOT NULL AND DEA.location LIKE 'Chile'

SELECT *, (CumulativeVaccinations/Population)*100 AS CumulativeVaccinationsPercentage
FROM #PercentPopulationVaccinated;


-- Creating a view

DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS

	SELECT DEA.date, DEA.continent, DEA.location, DEA.population, VAC.new_vaccinations, 
	SUM(CONVERT(bigint, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS CumulativeVaccinations
	FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
	ON DEA.date = VAC.date AND
	DEA.location = VAC.location
	WHERE DEA.continent IS NOT NULL AND DEA.location LIKE 'Chile'




                          -- Create some views to be used in data analysis request or visualizations --


-- Base view with all the rows and columns need it (Cases, Deaths and Vaccinations)

DROP VIEW IF EXISTS COVID_DB
CREATE VIEW dbo.COVID_DB AS
	SELECT DEA.continent, DEA.location, DEA.date, DEA.population, DEA.total_cases, DEA.new_cases, DEA.total_deaths, DEA.new_deaths,
	VAC.people_vaccinated, VAC.new_vaccinations, VAC.people_fully_vaccinated
	FROM Covid19..CovidDeaths AS DEA JOIN Covid19..CovidVaccinations AS VAC
	ON DEA.date = VAC.date AND
	DEA.location = VAC.location


-- Querying COVID_DB view

SELECT * FROM COVID_DB
ORDER BY location, date


-- View with only countries data, cleaning aggrupations

DROP VIEW IF EXISTS COVID_DB_COUNTRIES

CREATE VIEW COVID_DB_COUNTRIES AS
	SELECT * FROM COVID_DB
	WHERE continent IS NOT NULL


-- Querying COVID_DB_COUNTRIES view

SELECT * FROM COVID_DB_COUNTRIES
ORDER BY location, date


-- Querying COVID_DB_COUNTRIES countries

SELECT DISTINCT (location) FROM COVID_DB_COUNTRIES
ORDER BY location


-- View with data for aggrupations

DROP VIEW IF EXISTS COVID_DB_AGGR

CREATE VIEW COVID_DB_AGGR AS
	SELECT * FROM COVID_DB
	WHERE continent IS NULL


-- Querying COVID_DB_AGGR view

SELECT * FROM COVID_DB_AGGR
ORDER BY location, date


-- Querying aggrupations

SELECT DISTINCT location FROM COVID_DB_AGGR
ORDER BY location


-- View with data for income aggrupations

DROP VIEW IF EXISTS COVID_DB_INCOME

CREATE VIEW COVID_DB_INCOME AS
	SELECT * FROM COVID_DB
	WHERE continent IS NULL and location LIKE '%income'


-- Querying COVID_DB_INCOME view

SELECT * FROM COVID_DB_INCOME
ORDER BY location, date


-- View with data for continents

DROP VIEW IF EXISTS COVID_DB_CONTINENTS

CREATE VIEW COVID_DB_CONTINENTS AS
	SELECT * FROM COVID_DB
	WHERE continent IS NULL and location IN ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America')


-- Querying COVID_DB_CONTINENTS view

SELECT * FROM COVID_DB_CONTINENTS
ORDER BY location, date


-- View with data for all the world

DROP VIEW IF EXISTS COVID_DB_WORLD

CREATE VIEW COVID_DB_WORLD AS
	SELECT * FROM COVID_DB
	WHERE continent IS NULL and location LIKE 'WORLD'


-- Querying COVID_DB_WORLD view

SELECT * FROM COVID_DB_WORLD
ORDER BY location, date




-- Data analysis by country

-- Top five countries by people fully vaccinated

SELECT TOP 5 location, MAX(CAST(people_fully_vaccinated AS INT)) AS Fully_vaccinated
FROM COVID_DB_COUNTRIES
GROUP BY location
ORDER BY Fully_vaccinated DESC


-- Top five countries by people fully vaccinated over population

SELECT TOP 5 location, MAX(CAST(people_fully_vaccinated AS INT)/population)*100 AS Percentage_Fully_vaccinated
FROM COVID_DB_COUNTRIES
GROUP BY location
ORDER BY Percentage_Fully_vaccinated DESC


-- Top five countries by less people fully vaccinated

SELECT TOP 5 location, MAX(CAST(people_fully_vaccinated AS INT)) AS Fully_vaccinated
FROM COVID_DB_COUNTRIES
GROUP BY location
HAVING MAX(CAST(people_fully_vaccinated AS INT)/population)*100 > 0
ORDER BY Fully_vaccinated


-- Top five countries by less people fully vaccinated over population

SELECT TOP 5 location, MAX(CAST(people_fully_vaccinated AS INT)/population)*100 AS Percentage_Fully_vaccinated
FROM COVID_DB_COUNTRIES
GROUP BY location
HAVING MAX(CAST(people_fully_vaccinated AS INT)/population)*100 > 0
ORDER BY Percentage_Fully_vaccinated


-- Total cases, deaths and people fully vaccinated by income

SELECT location as income, SUM(CAST (new_cases AS BIGINT)) AS cases, SUM(CAST(new_deaths AS BIGINT)) AS deaths, SUM(CAST(new_vaccinations AS BIGINT)) as vaccinations
FROM COVID_DB_INCOME
GROUP BY location
ORDER BY cases DESC