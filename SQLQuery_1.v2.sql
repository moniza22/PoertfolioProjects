-- SELECT * 
-- FROM PortfolioProject..CovidDeaths
-- ORDER BY 3,4

-- SELECT *
-- FROM PortfolioProject..CovidVaccinations
-- ORDER BY 3,4

-- Selecting data to be used
SELECT location,date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- total_deaths/total_cases ratio in Canada
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Canada'
ORDER BY 1,2

-- ratio of covid cases vs the total population of Canada
SELECT location,date,population, total_cases, (total_cases/population)*100 AS covid_population_ratio
FROM PortfolioProject..CovidDeaths
WHERE location='Canada'
ORDER BY 1,2

-- countries with highest infection rate as compare to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected,
     MAX(total_deaths/total_cases) AS DeathrateVsTotalcases
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;



-- death rate vs population

SELECT 
      location,
      population, 
      MAX(total_cases) AS HighestInfectionCount,
      MAX(total_deaths) AS HighestDeathCount,
      MAX(total_deaths/population) AS PercentPopulationDied
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC

-- If we want to query the death rate and infection rate at continent level, 
-- we should include WHERE continent IS NULL in our query, because where 
-- continent is null the location shows records for the whole continent

SELECT 
       location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount,
       MAX(total_deaths) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC     

-- To get which country in each continent has highest death count
SELECT continent, MAX(total_deaths) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC


-- To get the sum of new cases each day all around world 
SELECT date, SUM(new_cases) AS WorldDailyCases
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC

-- To get the deathratio in infected people worldwide each day
SELECT date, SUM(new_cases) AS WorldDailyCases, SUM(new_deaths)/SUM(new_cases) AS WorldDeathRate
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC

-- 1
-- To get total worldwide infection cases and total deaths till date
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL

-- 2
-- To get total death count at continent level
SELECT location, SUM(new_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT IN ('High income','International','World','European Union','Lower middle income','Low income','Upper middle income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3
-- Highest infection count and Percent population infected
SELECT location, population, MAX(new_cases) AS HighestInfectionCount,(MAX(new_cases)/population)*100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

-- 4
-- Highest infection rate vs population
SELECT  
      location, population, date,
       MAX(total_cases) AS HighestInfectionCount, 
       MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location,population,date
ORDER BY PercentPopulationInfected DESC


-- Joining the CovidDeaths and CovidVaccinations table

SELECT *
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date 
     AND cd.location= cd.location
WHERE cd.continent IS NOT NULL     
ORDER BY cd.location

-- Population vs Vaccination
SELECT cd.location,cd.date, cd.population, cv.new_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date 
     AND cd.location= cd.location
WHERE cd.continent IS NOT NULL
ORDER BY cd.location 

-- Rolling people vaccination count
SELECT cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date
     AND cd.location=cv.location
WHERE cd.continent IS NOT NULL 
ORDER BY cd.location, cd.date

-- creating CTE to do further calculations with RollingPeopleVaccinated
WITH PopVsVac (location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
     (SELECT cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
     FROM PortfolioProject..CovidDeaths cd
     JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date
     AND cd.location=cv.location
     WHERE cd.continent IS NOT NULL
     -- ORDER BY cd.location, cd.date
     )
SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccPercentage
FROM PopVsVac 

-- creating Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
     location nvarchar(max),
     date datetime,
     population numeric,
     new_vaccinations numeric,
     RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date
     AND cd.location=cv.location
WHERE cd.continent IS NOT NULL
-- ORDER BY cd.location, cd.date

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccPercentage
FROM #PercentPopulationVaccinated

-- Creating view to store data for visualization

CREATE VIEW RollingPeopleVaccinated
AS (SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date
     AND cd.location=cv.location
WHERE cd.continent IS NOT NULL
-- ORDER BY cd.location, cd.date
)

SELECT *
FROM RollingPeopleVaccinated

CREATE VIEW PercentPopulationVaccinated
AS (SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date
     AND cd.location=cv.location
WHERE cd.continent IS NOT NULL
-- ORDER BY cd.location, cd.date
)


-- View total_deaths/total_cases ratio in Canada
CREATE VIEW TotalcasesVsPopulationCanada
AS (SELECT location,date,population, total_cases, (total_cases/population)*100 AS covid_population_ratio
FROM PortfolioProject..CovidDeaths
WHERE location='Canada'
-- ORDER BY 1,2  
)

-- View countries with highest infection rate as compare to population
CREATE VIEW HighestInfectionRate
AS (SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected,
     MAX(total_deaths/total_cases) AS DeathrateVsTotalcases
FROM PortfolioProject..CovidDeaths
GROUP BY location, population)
-- ORDER BY PercentPopulationInfected DESC

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

--View Highest infection rate vs population
CREATE VIEW HighestInfectionVsPopulation
AS (SELECT  
      location, 
      population, 
      MAX(total_cases) AS HighestInfectionCount, 
      MAX(total_cases/population) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population)
-- ORDER BY PercentPopulationInfected DESC;

-- View death rate vs population
CREATE VIEW DeathrateVsPopulation
AS (SELECT 
      location,
      population, 
      MAX(total_cases) AS HighestInfectionCount,
      MAX(total_deaths) AS HighestDeathCount,
      MAX(total_deaths/population) AS PercentPopulationDied
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population)
-- ORDER BY HighestDeathCount DESC

-- View To get the sum of new cases each day all around world 
CREATE VIEW WorldDailyCases
AS (SELECT date, SUM(new_cases) AS WorldDailyCases
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date)
-- ORDER BY date DESC

-- View To get the sum of daily deaths world wide
CREATE VIEW WorldDailyDeaths
AS (SELECT date ,SUM(new_deaths) AS WorldDailyDeaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date)
-- ORDER BY date DESC

--View Population vs Vaccination
CREATE VIEW PopulationVsVaccination
AS (SELECT cd.continent, cd.location,cd.date, cd.population, cv.new_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
     ON cd.date=cv.date 
     AND cd.location= cd.location
WHERE cd.continent IS NOT NULL)
-- ORDER BY cd.location 