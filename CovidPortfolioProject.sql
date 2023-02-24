--problem with our dataset is that it has the continent as location as well,
--so it is giving data related to continent and world
-- that's why, we need to put condition where continent is not null in each query

--sample query to check the data

select * from CovidDeaths
where continent is not null
order by location, date;

Select * from covidVaccinations
where continent is not null
order by location, date;

--Select the data that we are going to use
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
Order by location, date;

--looking at total cases vs total deaths
--what percentage of India are dead due to covid
select location, date, new_cases, total_cases, total_deaths, (total_deaths / total_cases)*100 as deathPercentage
from CovidDeaths
where location = 'India'
Order by location, date; 

--looking at total cases vs population
--what percentage of India are affected by covid
select location, date, new_cases, total_cases, population, (total_cases/population)*100 as covidPercentage
from CovidDeaths
where location = 'India'
Order by location, date;

--looking at countries with higest infection rate compared to Population
select location, population, max(total_cases) as maxCases, (max(total_cases/population))*100 as covidPercentage
from CovidDeaths
where continent is not null
group by location, population
Order by covidPercentage desc;

--looking at countries with highest death rate as compared to population
select location, population, max(cast (total_deaths as bigint)) as maxDeaths, (max(total_deaths/population))*100 as deathPercentage
from CovidDeaths
where continent is not null
group by location, population
Order by deathPercentage desc;

--looking at continents with highest death rate as compared to population
select continent, max(cast (total_deaths as bigint)) as maxDeaths, (max(total_deaths/population))*100 as deathPercentage
from CovidDeaths
where continent is not null
group by continent
Order by deathPercentage desc;

--looking at the global data of cases and deaths, per date
select date, sum(new_cases) as totalCase, sum(cast(new_deaths as int)) as totalDeaths, 
			(sum(cast(new_deaths as int))/sum(new_cases))*100 as deathPercentage
from covidDeaths
where continent is not null
group by date
order by date

--joining the data from both the tables
select *
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date;

--looking at total population vs new vaccinations date wise 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date;

--looking at total population vs total vaccinations date wise using partition by
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) 
as total_vaccinations_till
--, (total_vaccinations_till / dea.population)*100 as vaccination_percentage
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date;

--since we can't use the alias column 'total_vaccinations_till', we need to use CTE to display
-- percentage of total people vaccinations per population
With PopulationVsVaccinations (Continent, Location, Date, Population, New_vacctinations, total_vaccinations_till)
AS
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) 
as total_vaccinations_till
--, (total_vaccinations_till / dea.population)*100 as vaccination_percentage
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by dea.location, dea.date;
)
select * , (total_vaccinations_till / population)*100 as vaccination_percentage
from PopulationVsVaccinations
--where location = 'India'
--order by vaccination_percentage desc;

-- we can execute the same query using temp table

drop table if exists #PopulationVsVaccinations

create table #PopulationVsVaccinations
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	total_vaccinations_till numeric
)
Insert into #PopulationVsVaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) 
as total_vaccinations_till
--, (total_vaccinations_till / dea.population)*100 as vaccination_percentage
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by dea.location, dea.date;


select * , (total_vaccinations_till / population)*100 as vaccination_percentage
from #PopulationVsVaccinations
order by location, date
--where location = 'India'
--order by vaccination_percentage desc;


/* 
In above query percentage will go above 100 for few locations because in many locations, we have more than
one dose of vaccination 
*/

-- creating view to store data for later visualization
create view PopulationVsVaccinations AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert (bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) 
as total_vaccinations_till
--, (total_vaccinations_till / dea.population)*100 as vaccination_percentage
from covidDeaths as dea join covidVaccinations as vac
	ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by dea.location, dea.date;

select * from PopulationVsVaccinations;