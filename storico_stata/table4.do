//Creates table where ratios for 10,25,75,and 90 percentiles are calculated using the entire percentile. 
//The 50/50 takes the ratio of weighted avg of top half of distribution with the lower half

//Merge data
use comp.dta
drop if nord != 1
merge 1:1 nquest anno using rfam
drop _merge
merge 1:1 nquest anno using cons
drop _merge
merge 1:1 nquest anno using peso

//Rename colsrename anno year
rename eta age
rename ncomp hhold_size
rename sesso gender
rename ireg region 
rename anno year
rename peso weight

keep nquest year age hhold_size gender region weight y1 cn acom5 studio

//Drop data before 1995, n=86729
drop if year < 1995

//Drop if residing in a small location n=75977
drop if acom5 == 1

//Drop if age of household head outside [25,60] n=42202
drop if age<25
drop if age>60

//Create consumption and income cols as in paper
gen income = y1
gen consumption = cn

//Drop if negative income/consumption
drop if income<0
drop if consumption < 0

//Define income to consumption ration
gen inc_cons_ratio = income/consumption

//gen cutoff vals and use to trim top and bottom .5% of data
//n=41747 (after also dropping those with negative income)
//Basically doing something along the lines of adding up all the weights before, then get a row num or something and drop stuff before
sort(inc_cons_ratio)
egen total_weight = sum(weight)
local bot_cutoff = 0
local top_cutoff = 0
local curr_weight = 0
local N = _N
forval i = 1/`N'{
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > .005*total_weight[1]{
	    local bot_cutoff = inc_cons_ratio[`i'-1]
		continue, break
	}
}
local curr_weight = 0
forval i = 0/`N'{
    local curr_weight = `curr_weight' + weight[`N' - `i']
	if `curr_weight' > .005*total_weight[1]{
	    local top_cutoff = inc_cons_ratio[_N - `i' + 1]
		continue, break
	}
}
sum income

//Use cutoffs to drop top and bot .05% of data
drop if inc_cons_ratio > `top_cutoff'
drop if inc_cons_ratio <= `bot_cutoff'

//Deflate income and consumption variables using OECD CPI numbers (base year is 2015)
matrix cpi = [66.5,72.0,75.1,79.0,83.0,86.4,90.9,93.0,98.5,99.9,99.9]
matrix year = [1995,1998,2000,2002,2004,2006,2008,2010,2012,2014,2016]
forval i = 1/11{
	replace income = income/(cpi[1,`i']/100) if year == year[1,`i']
	replace consumption = consumption/(cpi[1,`i']/100) if year == year[1,`i']
}

//Drop data before 2002
drop if year < 2002

//Create a categorical education variable as defined in paper
gen educ = 1 if studio == 1 | studio ==2 
replace educ = 2 if studio == 3
replace educ = 3 if studio == 4 | studio == 5
replace educ = 4 if studio == 6

//Generate variables for regression
gen age_sqr = age^2
gen hhold_size_sqr = hhold_size^2
gen ln_inc = ln(income)
gen ln_consump = ln(consumption)

matrix income_vals = J(1,9,.)

local curr_year = 2002
local sum_vals = 0
forval i = 1/8{
	sum income [aweight = weight] if year == `curr_year', detail
	egen upper_avg = sum(income), income < r(p50)
	matrix income_vals[1,`i'] = r(p50)
}





