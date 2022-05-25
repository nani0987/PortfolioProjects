Create Database covid_portfolio_proj;
Use covid_portfolio_proj;
Create Table coviddeaths
(
iso_code char (3),
continent varchar (255),
location varchar (255),
date DATE,
population Integer,
total_cases Integer,
new_cases Integer,
new_cases_smoothed Double,
total_deaths Integer,
new_deaths Integer,
new_deaths_smoothed Double,
total_cases_per_million Double,
new_cases_per_million Double,
new_cases_smoothed_per_million Double,
total_deaths_per_million Double,
new_deaths_per_million Double,
new_deaths_smoothed_per_million Double,
reproduction_rate Double,
icu_patients Integer,
icu_patients_per_million Double,
hosp_patients Integer,
hosp_patients_per_million Double,
weekly_icu_admissions Integer,
weekly_icu_admissions_per_million Double,
weekly_hosp_admissions Integer,
weekly_hosp_admissions_per_million Double
);

-- Check if the local infile is On or Off
Show Variables Like 'local_infile';

-- Turn on the local infile if it is off
Set Global local_infile = 1;

-- Load CSV data into the table
Load Data local infile 'F:/SQL Training/Portfolio Projects/Covid Data/CovidDeaths.csv'
into table coviddeaths
Fields Terminated by ','
Ignore 1 Rows;

Select Count(*) From coviddeaths;
Select * From coviddeaths;

Create Table covidvaccinations
(
iso_code char (3),
continent varchar (255),
location varchar (255),
date DATE,
total_tests Integer,
new_tests Integer,
total_tests_per_thousand Double,
new_tests_per_thousand Double,
new_tests_smoothed Double,
new_tests_smoothed_per_thousand Double,
positive_rate Double,
tests_per_case Double,
tests_units Char,
total_vaccinations Integer,
people_vaccinated Integer,
people_fully_vaccinated Integer,
total_boosters Integer,
new_vaccinations Integer,
new_vaccinations_smoothed Double,
total_vaccinations_per_hundred Double,
people_vaccinated_per_hundred Double,
people_fully_vaccinated_per_hundred Double,
total_boosters_per_hundred Double,
new_vaccinations_smoothed_per_million Double,
new_people_vaccinated_smoothed Double,
new_people_vaccinated_smoothed_per_hundred Double,
stringency_index Double,
population_density Double,
median_age Double,
aged_65_older Double,
aged_70_older Double,
gdp_per_capita Double,
extreme_poverty Double,
cardiovasc_death_rate Double,
diabetes_prevalence Double,
female_smokers Double,
male_smokers Double,
handwashing_facilities Double,
hospital_beds_per_thousand Double,
life_expectancy Double,
human_development_index Double,
excess_mortality_cumulative_absolute Double,
excess_mortality_cumulative Double,
excess_mortality Double,
excess_mortality_cumulative_per_million Double
);

-- Load CSV data into the table
Load Data local infile 'F:/SQL Training/Portfolio Projects/Covid Data/CovidVaccinations.csv'
into table covidvaccinations
Fields Terminated by ','
Ignore 1 Rows;

-- Select the data we are going to use

Select * from coviddeaths
Where continent Is Not Null And continent <> '';

Select location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Order By 1,2; 

-- Total cases Vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
From coviddeaths
Where location = 'India'
Order By 1,2; 

-- Total cases Vs Population
Select location, date, total_cases, total_deaths, (total_cases/population)*100 As CasePercentage
From coviddeaths
Where location = 'India'
Order By 1,2;

-- Date of Max death in India
Select location, date, total_cases, total_deaths, new_deaths From coviddeaths 
Where new_deaths = (Select Max(new_deaths) From coviddeaths Where location = 'India');

-- Date of Max death in all continents
Select continent, Max(total_deaths) From coviddeaths Group By continent;

-- Countries with highest infection rate compared to its population
Select location, population, Max(total_cases) As HighestInfectionCount, Max((total_cases/population)*100) As PopulationPercentInfected
From coviddeaths
Group By location
Order By PopulationPercentInfected Desc;

-- Countries with highest death count per population
Select location, population, Max(total_deaths) As HighestDeathCount
From coviddeaths
Where continent Is Not Null And continent <> ''
Group By location
Order By HighestDeathCount Desc;

-- Continent with highest death count
Select continent, Max(total_deaths) As HighestDeathCount
From coviddeaths
Where continent Is Not Null And continent <> ''
Group By continent
Order By HighestDeathCount Desc;

-- Global numbers
Select Sum(new_cases) As total_new_cases, Sum(new_deaths) As total_new_deaths, Sum(new_deaths)/Sum(new_cases) *100 As NewDeathPercentage
From coviddeaths;

-- Using Window Function
SELECT continent, location, date, population, new_cases,
SUM(new_cases) OVER(PARTITION BY location Order By date)
FROM coviddeaths;

-- Joining table and exploring data
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location Order By d.date) As CumilativeNewCases
-- (CumilativeNewCases/population)*100
From coviddeaths d
Join covidvaccinations v On d.location = v.location And d.date = v.date
Where d.continent Is Not Null And d.continent <> ''
Order By 2,3;

-- Using CTE or Common Table Expression
With PopvsVac(continent, location, date, population, new_vaccinations, CumilativeNewCases)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location Order By d.date) As CumilativeNewCases
-- (CumilativeNewCases/population)*100
From coviddeaths d
Join covidvaccinations v On d.location = v.location And d.date = v.date
Where d.continent Is Not Null And d.continent <> ''
-- Order By 2,3
)
Select *, (CumilativeNewCases/population)*100 From PopvsVac;

-- Creating a Temp Table
Drop Table If Exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
	Continent varchar(255),
    Location varchar(255),
    Date datetime,
    Population Integer,
    New_Vaccination Integer,
    CumilativeNewCases Double
);

Insert Into PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location Order By d.date) As CumilativeNewCases
-- (CumilativeNewCases/population)*100
From coviddeaths d
Join covidvaccinations v On d.location = v.location And d.date = v.date
Where d.continent Is Not Null And d.continent <> '';

Select *, (CumilativeNewCases/population)*100 From PercentPopulationVaccinated;

-- Create View for visualization

-- India Death Percent
Create View IndiaDeathPercent As
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
From coviddeaths
Where location = 'India'
Order By 1,2;

-- India Covid Case Percentage
Create View CasePercentage As
Select location, date, total_cases, total_deaths, (total_cases/population)*100 As CasePercentage
From coviddeaths
Where location = 'India'
Order By 1,2;

-- Countries with Highest Infected Population
Create View PopulationPercentInfected As
Select location, population, Max(total_cases) As HighestInfectionCount, Max((total_cases/population)*100) As PopulationPercentInfected
From coviddeaths
Group By location
Order By PopulationPercentInfected Desc; 

-- Countries with highest death count per population
Create View HighestDeathCount As
Select location, population, Max(total_deaths) As HighestDeathCount
From coviddeaths
Where continent Is Not Null And continent <> ''
Group By location
Order By HighestDeathCount Desc;

-- Continent with highest death count
Create View HighestContDeathCount As
Select continent, Max(total_deaths) As HighestDeathCount
From coviddeaths
Where continent Is Not Null And continent <> ''
Group By continent
Order By HighestDeathCount Desc;

-- View for Global numbers
Create View GlobalNumbers As
Select Sum(new_cases) As total_new_cases, Sum(new_deaths) As total_new_deaths, Sum(new_deaths)/Sum(new_cases) *100 As NewDeathPercentage
From coviddeaths;

-- View of Cumilative New Cases
Create View CumilativeNewCases As
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER(PARTITION BY d.location Order By d.date) As CumilativeNewCases
-- (CumilativeNewCases/population)*100
From coviddeaths d
Join covidvaccinations v On d.location = v.location And d.date = v.date
Where d.continent Is Not Null And d.continent <> '';