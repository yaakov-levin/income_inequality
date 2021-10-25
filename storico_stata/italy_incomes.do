log using italy_incomes, replace

//Merge data
use comp.dta
drop if nord != 1
merge 1:1 nquest anno using rfam
drop _merge
merge 1:1 nquest anno using cons
drop _merge
merge 1:1 nquest anno using peso
drop _merge
//linb and ldip have data on individuals not just household heads so we need to drop those
/*
save working_data, replace
use linb.dta
drop if nord != 1
merge 1:1 nquest anno using working_data
drop _merge
save working_data, replace
use ldip.dta
drop if nord != 1
merge 1:1 nquest anno using working_data
*/

//Rename colsrename anno year
rename eta age
rename ncomp hhold_size
rename sesso gender
rename ireg region 
rename anno year
rename peso weight

//Drop data before 1995, n=86729
drop if year < 1995

//Drop if residing in a small location n=75977
drop if acom5 == 1

//Drop if age of household head outside [25,60] n=42202
drop if age<25
drop if age>60

//Create consumption and income cols as in paper
gen income_1 = yl1+yt+ym+yc
gen income_2 = ytp1 +yta + yl1+ym1 + yc
gen income_3 = y1
gen consumption = cn


forval num=1/3{
	preserve
	//Drop if negative income/consumption
	drop if income_`num'<0
	drop if consumption < 0

	//Define income to consumption ration
	gen inc_cons_ratio_`num' = income_`num'/consumption

	//gen cutoff vals and use to trim top and bottom .5% of data for each measure of income
	sort(inc_cons_ratio_`num')
	egen total_weight = sum(weight)
	local bot_cutoff = 0
	local top_cutoff = 0
	local curr_weight = 0
	local N = _N
	forval i = 1/`N'{
		local curr_weight = `curr_weight' + weight[`i']
		if `curr_weight' > .005*total_weight[1]{
			local bot_cutoff = inc_cons_ratio_`num'[`i'-1]
			continue, break
		}
	}
	local curr_weight = 0
	forval i = 0/`N'{
		local curr_weight = `curr_weight' + weight[`N' - `i']
		if `curr_weight' > .005*total_weight[1]{
			local top_cutoff = inc_cons_ratio_`num'[_N - `i' + 1]
			continue, break
		}
	}
	//Use cutoffs to drop top and bot .05% of data
	drop if inc_cons_ratio_`num' > `top_cutoff'
	//The bottom cutoff is often 0, so I drop a bunch of values here. Not sure what to do exactly
	drop if inc_cons_ratio_`num' <= `bot_cutoff'


	//drop data not in 2006 or 2014
	drop if year != 2006 & year != 2014

	//Create a categorical education variable as defined in paper
	gen educ = 1 if studio == 1 | studio ==2 
	replace educ = 2 if studio == 3
	replace educ = 3 if studio == 4 | studio == 5
	replace educ = 4 if studio == 6

	//Deflate income and consumption variables using OECD CPI numbers (base year is 2015)
	replace income_`num' = income_`num'/(86.4/100) if year == 2006
	replace consumption = consumption/(86.4/100) if year == 2006
	replace income_`num' = income_`num'/(99.9/100) if year == 2014
	replace consumption = consumption/(99.9/100) if year == 2014

	//Generate variables for regression
	gen age_sqr = age^2
	gen hhold_size_sqr = hhold_size^2
	gen ln_inc = ln(income_`num')
	gen ln_consump = ln(consumption)

	//Run regressions as in paper and generate residual values for consumption and income
	//reg ln_inc age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
	reg ln_inc age i.gender i.educ hhold_size i.region i.educ#year i.gender#year year [pweight = weight]
	predict resid_inc_log, residuals
	gen resid_income = exp(resid_inc_log)

	//reg ln_consump age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
	reg ln_consump age i.gender i.educ hhold_size i.region i.educ#year i.gender#year year [pweight = weight]
	predict resid_consump_log, residuals
	gen resid_consump = exp(resid_consump_log)

	sum resid_income  if year == 2006
	sum income_`num' if year == 2006
	sum resid_income if year == 2014
	sum income_`num' if year == 2014
	sum resid_consump if year == 2006
	sum resid_consump if year == 2014
	restore
}