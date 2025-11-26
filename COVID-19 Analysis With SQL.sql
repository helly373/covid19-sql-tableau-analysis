/*

Queries used for Tableau Project

*/



-- 1. 

Select * from CovidDeaths$


Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc






-- View all records in CovidDeaths table
SELECT * FROM CovidDeaths$
ORDER BY 3, 4;

-- View selected columns from CovidDeaths for analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1,2;

-- Analyze total cases vs total deaths (death percentage)
SELECT location, date, total_cases, total_deaths, 
       ROUND((total_deaths/total_cases), 4) * 100 AS DeathPercent
FROM CovidDeaths$
WHERE location LIKE '%India%'
ORDER BY 1,2;

-- Analyze total cases vs population (infection rate)
SELECT location, date, population, total_cases, 
       ROUND((total_cases/population), 4) * 100 AS PopulationPercent
FROM CovidDeaths$
WHERE location LIKE '%India%'
ORDER BY 1,2;

-- Countries with highest infection rate compared to population
SELECT location, continent, population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX(ROUND((total_cases/population), 4)) * 100 AS PopulationPercent
FROM CovidDeaths$
WHERE total_cases IS NOT NULL
GROUP BY location, population, continent
ORDER BY PopulationPercent DESC;

-- Continents with the highest total death count
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Countries with the highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global daily totals and death percentage
SELECT date, 
       SUM(new_cases) AS total_Cases, 
       SUM(CAST(new_deaths AS int)) AS total_deaths, 
       SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercent
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Overall global totals and death percentage
SELECT SUM(new_cases) AS total_Cases, 
       SUM(CAST(new_deaths AS int)) AS total_deaths, 
       SUM(CAST(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercent
FROM CovidDeaths$
WHERE continent IS NOT NULL;

-- Compare total population vs vaccination progress
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVacination$ vac
     ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2;

-- Using CTE to calculate rolling vaccination progress
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS int)) 
               OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths$ dea
    JOIN CovidVacination$ vac
         ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 AS VaccinationPercent
FROM PopvsVac;

-- Create and use temporary table for vaccination analysis
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert vaccination data with rolling totals
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVacination$ vac
     ON dea.location = vac.location
    AND dea.date = vac.date;

-- Display vaccination percentage per country
SELECT *, (RollingPeopleVaccinated/Population) * 100 AS VaccinationPercent
FROM #PercentPopulationVaccinated;

-- Create a view to store vaccination progress for visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVacination$ vac
     ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Retrieve data from the created view
SELECT *
FROM PercentPopulationVaccinated;
