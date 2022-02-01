*Changing working directory to use relative path for referencing
*NB files and folders are set relative to the working directory
cd "C:\Users\User\Downloads\Assignment\Covid"
ls
log using "covidLog.log", replace
ls


import delimited "Global_Mobility_Report.csv", clear
duplicates report
browse
save "Global_Mobility_Report.dta", replace


import delimited "owid-covid-data.csv", clear 
duplicates report

browse
*filter by continent => Europe
keep if strmatch(continent, "*Europe*")==1 & regexm(date, "2020-0[2-6]" )
* for consistency sake
rename location country_region

*Orthodox = ["Moldova", "Greece", "Poland", "Czech", "Serbia", "Romania", "Ukraine", "Bulgaria", "Belarus", "Russia"]
*Catholics = ["Croatia", "Austria", "Belgium", "France", "Germany", "Italy", "Spain", "Switzerland","Portugal","United Kingdom"]
* Vatican is not selected because there are no records on mobility report
keep if regexm(country_region, "Moldova|Greece|Poland|Czech|Serbia|Romania|Ukraine|Bulgaria|Belarus|Russia|Croatia|Austria|Belgium|France|Germany|Italy|Spain|Switzerland|Portugal|United Kingdom")

sort country_region date
count
* filter to remain the chosen countries

*merging the using dataset, mobility report, into the master dataset, Covid statistics data
merge 1:m country_region date using "Global_Mobility_Report.dta",

*keep merged results only
keep if _merge==3
* _merge is no longer useful hence drop it
drop _merge
duplicates report
count
* there are no duplicates but sub_region values exist
* the selected countries have been merged using their covid cases and mobility results
* checking if all the countries selected are showing
tab country_region

browse
* renaming columns from mobility report dataset
rename (retail_and_recreation_percent_ch grocery_and_pharmacy_percent_cha parks_percent_change_from_baseli transit_stations_percent_change_ workplaces_percent_change_from_b residential_percent_change_from_) (retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent)

save "mergedDataset.dta", replace
*use "mergedDataset.dta", clear

*Splitting out the date segments
*generating a date variable that can be used with time-series features
gen convertedDate = date(date, "YMD")
format convertedDate  %tdNN/DD/CCYY
gen day = day(convertedDate)
gen week = week(convertedDate)
gen month = month(convertedDate)

*there are several observations for some countries from the mobility report on the same date
*list date convertedDate if convertedDate==date("2020-04-26", "YMD"), abbreviate(13)

*using collapse to aggregate the data by date, keeping the numerical columns in the dataset

*collapse (sum) total_cases new_cases new_cases_smoothed total_deaths new_deaths new_deaths_smoothed total_cases_per_million new_cases_per_million new_cases_smoothed_per_million total_deaths_per_million new_deaths_per_million new_deaths_smoothed_per_million reproduction_rate icu_patients icu_patients_per_million hosp_patients hosp_patients_per_million weekly_icu_admissions weekly_icu_admissions_per_millio weekly_hosp_admissions weekly_hosp_admissions_per_milli new_tests total_tests total_tests_per_thousand new_tests_per_thousand new_tests_smoothed new_tests_smoothed_per_thousand positive_rate tests_per_case stringency_index population population_density median_age aged_65_older aged_70_older gdp_per_capita extreme_poverty cardiovasc_death_rate diabetes_prevalence female_smokers male_smokers handwashing_facilities hospital_beds_per_thousand life_expectancy human_development_index excess_mortality_cumulative_abso excess_mortality_cumulative excess_mortality excess_mortality_cumulative_per_ retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent day week month , by (convertedDate country_region)


collapse (sum) total_cases new_cases total_deaths new_deaths total_cases_per_million new_cases_per_million total_deaths_per_million new_deaths_per_million retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent, by (convertedDate country_region)


save "mergedDatasetWithoutStringColumns.dta", replace
*use "mergedDatasetWithoutStringColumns.dta", clear


*function starts ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
capture program drop multipleGraphFunction
program define multipleGraphFunction, rclass

*use "mergedDatasetWithoutStringColumns.dta", clear
*encoding country_region as country
encode country_region, gen(country)
label list country

*converting convertedDate time-series 
tsset country convertedDate, daily

* keeping only columns of interest
keep country total_cases new_cases total_deaths new_deaths total_cases_per_million new_cases_per_million total_deaths_per_million new_deaths_per_million retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent convertedDate

*reshaping to accomodate the countries of interest when plotting the countries on the same time-series graphs
*convertedDate gives the duration under study, country
reshape wide total_cases new_cases total_deaths new_deaths total_cases_per_million new_cases_per_million total_deaths_per_million new_deaths_per_million retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent, i(convertedDate) j(country)

* checking infections, death distribution
twoway (tsline total_cases1) (tsline total_cases2) (tsline total_cases3) (tsline total_cases4) (tsline total_cases5) (tsline total_cases6) (tsline total_cases7) (tsline total_cases8) (tsline total_cases9) (tsline total_cases10)
twoway (tsline new_cases1) (tsline new_cases2) (tsline new_cases3) (tsline new_cases4) (tsline new_cases5) (tsline new_cases6) (tsline new_cases7) (tsline new_cases8) (tsline new_cases9) (tsline new_cases10)
twoway (tsline total_deaths1) (tsline total_deaths2) (tsline total_deaths3) (tsline total_deaths4) (tsline total_deaths5) (tsline total_deaths6) (tsline total_deaths7) (tsline total_deaths8) (tsline total_deaths9) (tsline total_deaths10)
twoway (tsline new_deaths1) (tsline new_deaths2) (tsline new_deaths3) (tsline new_deaths4) (tsline new_deaths5) (tsline new_deaths6) (tsline new_deaths7) (tsline new_deaths8) (tsline new_deaths9) (tsline new_deaths10)

*checking out mobility during the period
twoway (tsline retail_and_recreation_percent1) (tsline retail_and_recreation_percent2) (tsline retail_and_recreation_percent3) (tsline retail_and_recreation_percent4) (tsline retail_and_recreation_percent5) (tsline retail_and_recreation_percent6) (tsline retail_and_recreation_percent7) (tsline retail_and_recreation_percent8) (tsline retail_and_recreation_percent9) (tsline retail_and_recreation_percent10)
twoway (tsline grocery_and_pharmacy_percent1) (tsline grocery_and_pharmacy_percent2) (tsline grocery_and_pharmacy_percent3) (tsline grocery_and_pharmacy_percent4) (tsline grocery_and_pharmacy_percent5) (tsline grocery_and_pharmacy_percent6) (tsline grocery_and_pharmacy_percent7) (tsline grocery_and_pharmacy_percent8) (tsline grocery_and_pharmacy_percent9) (tsline grocery_and_pharmacy_percent10)
twoway (tsline parks_percent1) (tsline parks_percent2) (tsline parks_percent3) (tsline parks_percent4) (tsline parks_percent5) (tsline parks_percent6) (tsline parks_percent7) (tsline parks_percent8) (tsline parks_percent9) (tsline parks_percent10)
twoway (tsline transit_stations_percent1) (tsline transit_stations_percent2) (tsline transit_stations_percent3) (tsline transit_stations_percent4) (tsline transit_stations_percent5) (tsline transit_stations_percent6) (tsline transit_stations_percent7) (tsline transit_stations_percent8) (tsline transit_stations_percent9) (tsline transit_stations_percent10)
twoway (tsline workplaces_percent1) (tsline workplaces_percent2) (tsline workplaces_percent3) (tsline workplaces_percent4) (tsline workplaces_percent5) (tsline workplaces_percent6) (tsline workplaces_percent7) (tsline workplaces_percent8) (tsline workplaces_percent9) (tsline workplaces_percent10)
twoway (tsline residential_percent1) (tsline residential_percent2) (tsline residential_percent3) (tsline residential_percent4) (tsline residential_percent5) (tsline residential_percent6) (tsline residential_percent7) (tsline residential_percent8) (tsline residential_percent9) (tsline residential_percent10)

*graph save "Graph" "graph.gph"
end

*NB the visuals from the multipleGraphFunction were not saved just included
*function ends ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


*function calling for Catholics group
use "mergedDatasetWithoutStringColumns.dta", clear
keep if regexm(country_region, "Croatia|Austria|Belgium|France|Germany|Italy|Spain|Switzerland|Portugal|United Kingdom")
multipleGraphFunction

*doing aggregate
use "mergedDatasetWithoutStringColumns.dta", clear
keep if regexm(country_region, "Croatia|Austria|Belgium|France|Germany|Italy|Spain|Switzerland|Portugal|United Kingdom")
collapse (sum) total_cases new_cases total_deaths new_deaths total_cases_per_million new_cases_per_million total_deaths_per_million new_deaths_per_million retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent, by (convertedDate)
tsset convertedDate, daily
twoway (tsline total_cases)  ,title(COVID-19 Cases) subtitle("(total_cases_Catholics)")
graph save "Graph" "graphs\total_cases_Catholics.gph", replace
twoway (tsline new_cases) ,title(COVID-19 Cases) subtitle("(new_cases_Catholics)")
graph save "Graph" "graphs\new_cases_Catholics.gph", replace
twoway (tsline new_deaths) ,title(COVID-19 Cases) subtitle("(new_deaths_Catholics)")
graph save "Graph" "graphs\new_deaths_Catholics.gph", replace
twoway (tsline retail_and_recreation_percent) ,title(COVID-19 Cases) subtitle("(retail_and_recreation_percent_Catholics)")
graph save "Graph" "graphs\retail_and_recreation_percent_Catholics.gph", replace
twoway (tsline grocery_and_pharmacy_percent) ,title(COVID-19 Cases) subtitle("(grocery_and_pharmacy_percent_Catholics)")
graph save "Graph" "graphs\grocery_and_pharmacy_percent_Catholics.gph", replace
twoway (tsline parks_percent) ,title(COVID-19 Cases) subtitle("(parks_percent_Catholics)")
graph save "Graph" "graphs\parks_percent_Catholics.gph", replace
twoway (tsline transit_stations_percent) ,title(COVID-19 Cases) subtitle("(transit_stations_percent_Catholics)")
graph save "Graph" "graphs\transit_stations_percent_Catholics.gph", replace
twoway (tsline workplaces_percent) ,title(COVID-19 Cases) subtitle("(workplaces_percent_Catholics)")
graph save "Graph" "graphs\workplaces_percent_Catholics.gph", replace
twoway (tsline residential_percent) ,title(COVID-19 Cases) subtitle("(residential_percent_Catholics)")
graph save "Graph" "graphs\residential_percent_Catholics.gph", replace

*Checking regression for the catholics variables
* R-squared and F = 0
regress total_cases  
* R-squared =  0.0141 and F = 0.96
regress total_cases new_cases new_deaths
* R-squared =   0.2920 and F =  13.61
regress total_cases new_cases new_deaths retail_and_recreation_percent grocery_and_pharmacy_percent
* R-squared =   0.8112 and F = 68.74
regress total_cases new_cases new_deaths retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent

*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*function calling for Orthodox group
use "mergedDatasetWithoutStringColumns.dta", clear
keep if regexm(country_region, "Moldova|Greece|Poland|Czech|Serbia|Romania|Ukraine|Bulgaria|Belarus|Russia")
multipleGraphFunction

*doing aggregated graph combining the countries
use "mergedDatasetWithoutStringColumns.dta", clear
keep if regexm(country_region, "Moldova|Greece|Poland|Czech|Serbia|Romania|Ukraine|Bulgaria|Belarus|Russia")
collapse (sum) total_cases new_cases total_deaths new_deaths total_cases_per_million new_cases_per_million total_deaths_per_million new_deaths_per_million retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent, by (convertedDate)
tsset convertedDate, daily
twoway (tsline total_cases),title(COVID-19 Cases) subtitle("(total_cases_Orthodox)")
graph save "Graph" "graphs\total_cases_Orthodox.gph", replace
twoway (tsline new_cases),title(COVID-19 Cases) subtitle("(new_cases_Orthodox)")
graph save "Graph" "graphs\new_cases_Orthodox.gph", replace
twoway (tsline new_deaths),title(COVID-19 Cases) subtitle("(new_deaths_Orthodox)")
graph save "Graph" "graphs\new_deaths_Orthodox.gph", replace
twoway (tsline retail_and_recreation_percent),title(COVID-19 Cases) subtitle("(retail_and_recreation_percent_Orthodox)")
graph save "Graph" "graphs\retail_and_recreation_percent_Orthodox.gph", replace
twoway (tsline grocery_and_pharmacy_percent),title(COVID-19 Cases) subtitle("(grocery_and_pharmacy_percent_Orthodox)")
graph save "Graph" "graphs\grocery_and_pharmacy_percent_Orthodox.gph", replace
twoway (tsline parks_percent),title(COVID-19 Cases) subtitle("(parks_percent_Orthodox)")
graph save "Graph" "graphs\parks_percent_Orthodox.gph", replace
twoway (tsline transit_stations_percent),title(COVID-19 Cases) subtitle("(transit_stations_percent_Orthodox)")
graph save "Graph" "graphs\transit_stations_percent_Orthodox.gph", replace
twoway (tsline workplaces_percent),title(COVID-19 Cases) subtitle("(workplaces_percent_Orthodox)")
graph save "Graph" "graphs\workplaces_percent_Orthodox.gph", replace
twoway (tsline residential_percent),title(COVID-19 Cases) subtitle("(residential_percent_Orthodox)")
graph save "Graph" "graphs\residential_percent_Orthodox.gph", replace

*Checking regression for the Orthodox variables
* R-squared and F = 0
regress total_cases  
* R-squared =  0.6390 and F =  118.61
regress total_cases new_cases new_deaths
* R-squared =   0.8592 and F =  201.36
regress total_cases new_cases new_deaths retail_and_recreation_percent grocery_and_pharmacy_percent
* R-squared =  0.8848 and F =  122.89
regress total_cases new_cases new_deaths retail_and_recreation_percent grocery_and_pharmacy_percent parks_percent transit_stations_percent workplaces_percent residential_percent
