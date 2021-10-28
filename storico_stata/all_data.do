//Creates tables for income, consumption, residual income, residual consumption
//for all years for all cutoff values

log using italy_analysis, replace 

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

//Run regressions as in paper and generate residual values for consumption and income
//Note that these regressions were run using data from all years 2002-2016, so residuals differ from regressions run with less data
reg ln_inc age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
predict resid_inc_log, residuals
gen resid_income = exp(resid_inc_log)

reg ln_consump age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
predict resid_consump_log, residuals
gen resid_consump = exp(resid_consump_log)

//Generate matrices to store all values. One matrix each for income, consumption, residual income, and residual consumption
//Income matrix
matrix final_table_inc = J(9,11,.)
matrix rownames final_table_inc = "<10" ">90" "R_10_90" "<25" ">75" "R_25_75" "<50" ">50" "R_50_50"
matrix colnames final_table_inc = "1995" "1998" "2000" "2002" "2004" "2006" "2008" "2010" "2012" "2014" "2016"
//Consumption matrix
matrix final_table_cons = J(9,11,.)
matrix rownames final_table_cons = "<10" ">90" "R_10_90" "<25" ">75" "R_25_75" "<50" ">50" "R_50_50"
matrix colnames final_table_cons = "1995" "1998" "2000" "2002" "2004" "2006" "2008" "2010" "2012" "2014" "2016"
//Residual Income matrix
matrix final_table_resid_inc = J(9,11,.)
matrix rownames final_table_resid_inc = "<10" ">90" "R_10_90" "<25" ">75" "R_25_75" "<50" ">50" "R_50_50"
matrix colnames final_table_resid_inc = "1995" "1998" "2000" "2002" "2004" "2006" "2008" "2010" "2012" "2014" "2016"
//Residual Consumption matrix
matrix final_table_resid_cons = J(9,11,.)
matrix rownames final_table_resid_cons = "<10" ">90" "R_10_90" "<25" ">75" "R_25_75" "<50" ">50" "R_50_50"
matrix colnames final_table_resid_cons = "1995" "1998" "2000" "2002" "2004" "2006" "2008" "2010" "2012" "2014" "2016"

//Loop through all years of data
forval i=1/11{
	//Drop other years of data
	preserve
	drop if year != year[1,`i']
	
	//Store pctile cutoff vals for current year
	sum income [aweight = weight], detail
	matrix income_pctiles = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]
	sum resid_income [aweight = weight], detail
	matrix resid_income_pctiles = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]
	
	//Each loop calculates values ratios in order of >90/<10, >75/<25, and >50/<50
	forval j=1/3{
		//Create matrix to store values and weights for income, consumption, and residual numbers
		matrix temp_nums = J(4,4,0)
		matrix colnames temp_nums = "i" "c" "ri" "rc"
		matrix rownames temp_nums = "sum_upper" "wt_upper" "sum_lower" "wt_lower"
		//Loop through all values in current year
		local N = _N
		forval k=1/`N'{
			//Using non residualized income
			//Checks 10th,25th, and <50th percentiles
			if income[`k']<income_pctiles[1,`j']{
				//add to income cells
				matrix temp_nums[3,1] = temp_nums[3,1]+income[`k']*weight[`k']
				matrix temp_nums[4,1] = temp_nums[4,1]+weight[`k']
				//add to consump cells
				matrix temp_nums[3,2] = temp_nums[3,2]+consumption[`k']*weight[`k']
				matrix temp_nums[4,2] = temp_nums[4,2]+weight[`k']
			}
			//Checks 90th,75th, and >50th percentiles
			if income[`k']>income_pctiles[1,7-`j']{
				//add to income cells
				matrix temp_nums[1,1] = temp_nums[1,1]+income[`k']*weight[`k']
				matrix temp_nums[2,1] = temp_nums[2,1]+weight[`k']
				//add to consump cells
				matrix temp_nums[1,2] = temp_nums[1,2]+consumption[`k']*weight[`k']
				matrix temp_nums[2,2] = temp_nums[2,2]+weight[`k']
			}
			//Using residualized income
			//Checks 10th,25th, and <50th percentiles
			if resid_income[`k']<resid_income_pctiles[1,`j']{
				//add to income cells
				matrix temp_nums[3,3] = temp_nums[3,3]+resid_income[`k']*weight[`k']
				matrix temp_nums[4,3] = temp_nums[4,3]+weight[`k']
				//add to consump cells
				matrix temp_nums[3,4] = temp_nums[3,4]+resid_consump[`k']*weight[`k']
				matrix temp_nums[4,4] = temp_nums[4,4]+weight[`k']
			}
			//Checks 90th,75th, and >50th percentiles
			if resid_income[`k']>resid_income_pctiles[1,7-`j']{
				//add to income cells
				matrix temp_nums[1,3] = temp_nums[1,3]+resid_income[`k']*weight[`k']
				matrix temp_nums[2,3] = temp_nums[2,3]+weight[`k']
				//add to consump cells
				matrix temp_nums[1,4] = temp_nums[1,4]+resid_consump[`k']*weight[`k']
				matrix temp_nums[2,4] = temp_nums[2,4]+weight[`k']
			}
		}
		//Use values in temp_nums to fill in one ratio's vals in final table e.g. >90,<10, and >90/<10 for current year i
		//Reminder that rows of final tables are: "<10" ">90" "R_10_90" "<25" ">75" "R_25_75" "<50" ">50" "R_50_50"
		//(`j'-1)*3 is last filled in row in final table

		//Fill in income vals
		//Lower sum/lower weight
		matrix final_table_inc[1+(`j'-1)*3,`i'] = temp_nums[3,1]/temp_nums[4,1]
		//Upper sum/upper weight
		matrix final_table_inc[2+(`j'-1)*3,`i'] = temp_nums[1,1]/temp_nums[2,1]
		//Ratio
		matrix final_table_inc[3+(`j'-1)*3,`i'] = final_table_inc[2+(`j'-1)*3,`i']/final_table_inc[1+(`j'-1)*3,`i']
		
		//Fill in consumption vals
		//Lower number
		matrix final_table_cons[1+(`j'-1)*3,`i'] = temp_nums[3,2]/temp_nums[4,2]
		//Upper number
		matrix final_table_cons[2+(`j'-1)*3,`i'] = temp_nums[1,2]/temp_nums[2,2]
		//Ratio
		matrix final_table_cons[3+(`j'-1)*3,`i'] = final_table_cons[2+(`j'-1)*3,`i']/final_table_cons[1+(`j'-1)*3,`i']
		
		//Fill in residual income vals
		//Lower number
		matrix final_table_resid_inc[1+(`j'-1)*3,`i'] = temp_nums[3,3]/temp_nums[4,3]
		//Upper number
		matrix final_table_resid_inc[2+(`j'-1)*3,`i'] = temp_nums[1,3]/temp_nums[2,3]
		//Ratio
		matrix final_table_resid_inc[3+(`j'-1)*3,`i'] = final_table_resid_inc[2+(`j'-1)*3,`i']/final_table_resid_inc[1+(`j'-1)*3,`i']
		
		//Fill in residual consumption vals
		//Lower number
		matrix final_table_resid_cons[1+(`j'-1)*3,`i'] = temp_nums[3,4]/temp_nums[4,4]
		//Upper number
		matrix final_table_resid_cons[2+(`j'-1)*3,`i'] = temp_nums[1,4]/temp_nums[2,4]
		//Ratio
		matrix final_table_resid_cons[3+(`j'-1)*3,`i'] = final_table_resid_cons[2+(`j'-1)*3,`i']/final_table_resid_inc[1+(`j'-1)*3,`i']
	}
	restore
} 

//Store tables
esttab matrix(final_table_inc) using income_all.txt, replace
esttab matrix(final_table_cons) using consumption_all.txt, replace
esttab matrix(final_table_resid_inc) using resid_income_all.txt, replace
esttab matrix(final_table_resid_cons) using resid_consumption_all.txt, replace


 
/*
//To graph we add the years as an actual row (not just names of rows). And concatenating gives type mismatches ergo clunky for loop. New matrix drops col for averages and adds row for years
matrix graphable = J(13,8,.)
forval i=1/12{
	forval j=1/8{
		matrix graphable[`i',`j'] = final_table[`i',`j']
	}
}
local curr_year = 2002
forval i=1/8{
	matrix graphable[13,`i'] = `curr_year'
	local curr_year = `curr_year' + 2
}
//Transpose matrix
matrix graphable = graphable'
//Save as variables
svmat graphable
//Rename variables
rename graphable3 inc_ratio
rename graphable6 cons_ratio
rename graphable9 resid_inc_ratio
rename graphable12 resid_cons_ratio
rename graphable1 inc_top
rename graphable2 inc_bot
rename graphable4 cons_top
rename graphable5 cons_bot
rename graphable7 r_inc_top
rename graphable8 r_inc_bot
rename graphable10 r_cons_top
rename graphable11 r_cons_bot
//Already have a var called year, so call time var date
rename graphable13 date

//graph ratios
line inc_ratio cons_ratio resid_inc_ratio resid_cons_ratio date
graph export 50pct_ratios.png, replace
//graph non residual levels
line inc_top inc_bot cons_top cons_bot date
graph export 50_pct_levels.png, replace
//graph residual levels
line r_inc_top r_inc_bot r_cons_top r_cons_bot date
graph export 50_pct_resid_levels.png, replace

esttab matrix(final_table) using table4.txt, replace
*/

