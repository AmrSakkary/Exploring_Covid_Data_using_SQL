-- First 10 rows of the data we work on
SELECT TOP 10 LOCATION, date, total_cases,
	new_cases,
	total_deaths,
	population
FROM covid_death
ORDER BY 1,2;

-- death percent over time
SELECT LOCATION,
	date, 
	total_cases,
	total_deaths,
	round((total_deaths / total_cases) * 100 , 2) death_percent
FROM covid_death
ORDER BY 1,2;

-- death percent from the start to the end time in Egypt
SELECT TOP 1 location, 
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 as death_percent 
FROM covid_death
where location = 'Egypt'
ORDER BY 2 desc;

-- death percent based on location is Egypt over time 
SELECT location,
	date,
	total_cases,
	total_deaths,
	round((total_deaths / total_cases) * 100 , 2) death_percent
FROM covid_death
where location = 'Egypt'
ORDER BY 1,2;

-- percent of the population infected over time in Egypt
SELECT location, 
	date,
	population,
	total_cases,
	(total_cases / population) * 100 as infection_percent
FROM covid_death
where location = 'Egypt'
ORDER BY 1,2;

-- Max infection percent based on the location
SELECT location,
	population,
	max(total_cases) highest_infection_count,
	max((total_cases / population) * 100) AS max_infection_percent
FROM covid_death 
GROUP BY location, population
ORDER BY 4 DESC;

-- Max death count based on the location
SELECT DISTINCT LOCATION,
	max(total_deaths) highest_death_count
FROM covid_death
where continent is not null
GROUP BY location
ORDER BY 2 DESC;

-- Max death count based on each group
SELECT location,
	max(total_deaths) highest_death_count
FROM covid_death
where continent is null
GROUP BY location
ORDER BY 2 DESC

-- Max death count based on the continent
SELECT continent,
	max(total_deaths) highest_death_count
FROM covid_death
where continent is not null
GROUP BY continent
ORDER BY 2 DESC

--------------------------------------------------

-- Global numbers

--  Daily cases , deaths and death percent  (per day)
SELECT date,
	sum(new_cases) total_cases,
	sum(new_deaths) total_deaths,
	(sum(new_deaths) / sum(new_cases)) * 100 as death_percent
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- total cases , deaths and death percent by (4 june 2022)
SELECT sum(new_cases) total_cases,
	sum(new_deaths) total_deaths,
	(sum(new_deaths) / sum(new_cases)) * 100 AS death_percent
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 1;


-- Making a rolling summition to calculate the vaccination by location and time
SELECT continent,location, date,population,
		new_vaccinations,
		sum(new_vaccinations) over (partition by location order by location,date) as rolling_vaccination
FROM covid_vaccination
WHERE continent IS NOT NULL ;
-------------------------------------------------------------
-- calculating the vaccination vs population
-- using CTE

WITH vac_vs_pop AS 
	(SELECT vac.continent,
			vac.LOCATION, vac.date,vac.population,
			vac.new_vaccinations,
			sum(new_vaccinations) OVER (PARTITION BY vac.LOCATION ORDER BY vac.LOCATION,vac.date) AS rolling_vaccination
		FROM covid_vaccination vac
		WHERE continent IS NOT NULL ) -- order by 2,3

SELECT *,
	(rolling_vaccination / population) * 100 vaccination_percent
FROM vac_vs_pop


-- Using Temp Table
drop table if exists #vac_vs_pop
create table #vac_vs_pop
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination numeric
)

INSERT INTO #vac_vs_pop
SELECT vac.continent,
	vac.location,
	vac.date,
	vac.population,
	vac.new_vaccinations,
	sum(new_vaccinations) OVER (PARTITION BY vac.location ORDER BY vac.location,vac.date) AS rolling_vaccination
FROM covid_vaccination vac
WHERE continent IS NOT NULL

SELECT *,
	(rolling_vaccination / population) * 100 vaccination_percent
FROM #vac_vs_pop

-- creating view to store data for later visuals
create view vac_vs_pop as (
SELECT vac.continent,
	vac.location,
	vac.date,
	vac.population,
	vac.new_vaccinations,
	sum(new_vaccinations) OVER (PARTITION BY vac.location ORDER BY vac.location,vac.date) AS rolling_vaccination
FROM covid_vaccination vac
WHERE continent IS NOT NULL
);

SELECT *
FROM vac_vs_pop;