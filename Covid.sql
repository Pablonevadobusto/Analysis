-- Looking at Total Cases vs Total Deaths 

select location
		,date
		,total_cases
		,total_deaths
		,round((total_deaths / total_cases) * 100, 3) as DeathRate
FROM [dbo].[CovidDeaths]
WHERE location like '%spain%'
order by 2

-- Looking at Total Cases vs Population 

select location
		,date
		,total_cases
		,population
		,round((total_cases / population) * 100, 3) as PopulationInfected
FROM [dbo].[CovidDeaths]
WHERE location like '%spain%'
order by 2

CREATE VIEW View4 as
select location
		,ISNULL(population,0) as population
		,date
		,ISNULL(MAX(total_cases),0) as HighestInfectionCount
		,ISNULL(round(MAX((total_cases / population)) * 100, 3),0) as PopulationInfected
FROM [dbo].[CovidDeaths]
GROUP BY location
		,population
		,date
		
-- Looking at Countries with Highest Infection Rate compared to Population

CREATE VIEW View3 as
select location
		,ISNULL(population,0) as population
		,ISNULL(MAX(total_cases),0) as HighestInfectionCount
		,ISNULL(round(MAX((total_cases / population)) * 100, 3),0) as PopulationInfected
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY Location
		,population

-- Showing Countries with Highest Death Count per Population

select location
		,population
		,MAX(CAST(total_deaths as int)) as HighestDeathCount
		,round(MAX((total_deaths / population)) * 100, 3) as DeadPopulationRate
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY Location
		,population
order by DeadPopulationRate desc

-- Showing Continents with Highest Death Count per Population

select continent
		,MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY continent
order by HighestDeathCount desc

CREATE VIEW View2 as
select location
		,MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is null
and location not in ('World','European Union','International')
GROUP BY location

-- Global Numbers
CREATE VIEW View1 as 
SELECT SUM(new_cases) as total_new_cases
		,SUM(CAST(new_deaths as int)) as total_new_deaths
		,SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent is not null


-- Looking at Total Population vs Vaccinations
/*3 ways of doing the same*/
-- CTE

;WITH ROLLING AS(
SELECT dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] as dea
	inner join [dbo].[CovidVaccinations] as vac
		ON dea.location = vac.location
		and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *
		,ROUND(RollingPeopleVaccinated/population *100,4) as PercentPopulationVaccinated
FROM ROLLING
ORDER BY 2,3

-- SUBQUERY
SELECT *
		,ROUND(RollingPeopleVaccinated/population *100,4) as PercentPopulationVaccinated
FROM(
SELECT dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] as dea
	inner join [dbo].[CovidVaccinations] as vac
		ON dea.location = vac.location
		and dea.date = vac.date
WHERE dea.continent is not null
) as a
ORDER BY 2,3

--Temp Table
DROP TABLE IF EXISTS #TT#
SELECT dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
INTO #TT#
FROM [dbo].[CovidDeaths] as dea
	inner join [dbo].[CovidVaccinations] as vac
		ON dea.location = vac.location
		and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

SELECT *
		,ROUND(RollingPeopleVaccinated/population *100,4) as PercentPopulationVaccinated
FROM #TT#
ORDER BY 2,3
offset 4 rows
fetch next 10 rows only

/* Creating View to store data for later visualizations */

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent
		,dea.location
		,dea.date 
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] as dea
	inner join [dbo].[CovidVaccinations] as vac
		ON dea.location = vac.location
		and dea.date = vac.date
WHERE dea.continent is not null
