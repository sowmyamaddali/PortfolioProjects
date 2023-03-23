/*
Covid 19 Data Exploration 
Skills used: JOINs, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


/* Problem 1. When uploaded, all the data was (varchar(50)) 
-> this caused me several problems when it came to calculations.  I ended up changing that data type myself.
*/


--Change of data type 

----CovidDeaths Table----

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths float

ALTER TABLE CovidDeaths
ALTER COLUMN total_cASes float

ALTER TABLE CovidDeaths
ALTER COLUMN new_cASes float

ALTER TABLE CovidDeaths
ALTER COLUMN population numeric

ALTER TABLE CovidDeaths
ALTER COLUMN date datetime

----CovidVaccinations Table----

ALTER TABLE CovidVaccinations
ALTER COLUMN date datetime

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations float


-- Checking the tables were uploaded properly

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4


-- SELECT Data that we are going to be using

SELECT location, date, total_cASes, new_cASes, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2 

-- Looking at Total CASes vs Total Deaths
-- Shows the likelyhood of dying if you contract COVID in your country (I picked UK)
SELECT location, date, total_cASes, total_deaths, (total_deaths / NULLIF(total_cASes,0))*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2 


-- Looking at Total CASes vs Population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cASes, (total_cASes / population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2 


-- Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cASes) AS HighestInfectionCount, MAX((total_cASes/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Showing countries with Highest Death Count per Population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continent with the Highest Death Count
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT SUM(new_cASes) AS total_cASes, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths)/NULLIF(SUM(new_cASes),0)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2 


--Looking at Total Population vs Vaccinations

SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE

With PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualisations

CREATE View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL