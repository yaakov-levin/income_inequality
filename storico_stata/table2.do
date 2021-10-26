//log using italy_stats,replace

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

//Use cutoffs to drop top and bot .05% of data
drop if inc_cons_ratio > `top_cutoff'
//The bottom cutoff is 0, so I drop a bunch of values here. Not sure what to do exactly
drop if inc_cons_ratio <= `bot_cutoff'

//drop data not in 2006 or 2014
drop if year != 2006 & year != 2014


//Create a categorical education variable as defined in otonello paper
gen educ = 1 if studio == 1 | studio ==2 
replace educ = 2 if studio == 3
replace educ = 3 if studio == 4 | studio == 5
replace educ = 4 if studio == 6

//Deflate income and consumption variables using OECD CPI numbers (base year is 2015)
replace income = income/(86.4/100) if year == 2006
replace consumption = consumption/(86.4/100) if year == 2006
replace income = income/(99.9/100) if year == 2014
replace consumption = consumption/(99.9/100) if year == 2014

//Generate variables for regression
gen age_sqr = age^2
gen hhold_size_sqr = hhold_size^2
gen ln_inc = ln(income)
gen ln_consump = ln(consumption)

//Run regressions as in paper and generate residual values for consumption and income
reg ln_inc age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
predict resid_inc_log, residuals
gen resid_income = exp(resid_inc_log)

reg ln_consump age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year [pweight = weight]
predict resid_consump_log, residuals
gen resid_consump = exp(resid_consump_log)

drop total_weight

//Generate matrix to store all values
matrix final_table = J(3,8,.)
matrix rownames final_table = ">90/<10" ">75/<25" ">50/<50"
matrix colnames final_table = "2006i" "2014i" "2006c" "2014c" "2006ri" "2014ri" "2006rc" "2014rc"

//Store values for 10th,25th,50th,75th,and 90th percentiles of income and residual income
sum income [aweight = weight] if year == 2006, detail
matrix income_pctiles_2006 = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]
sum resid_income [aweight = weight] if year == 2006, detail
matrix resid_income_pctiles_2006 = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]
sum income [aweight = weight] if year == 2014, detail
matrix income_pctiles_2014 = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]
sum resid_income [aweight = weight] if year == 2014, detail
matrix resid_income_pctiles_2014 = [r(p10),r(p25),r(p50),r(p50),r(p75),r(p90)]

//Create matrices to hold data for each percentile for each value for each year that is used to truncate 
matrix income_2006 = J(6,2,0)
matrix rownames income_2006 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames income_2006 = "val_sum" "wt_sum"

matrix income_2014 = J(6,2,0)
matrix rownames income_2014 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames income_2014 = "val_sum" "wt_sum"

matrix consump_2006 = J(6,2,0)
matrix rownames consump_2006 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames consump_2006 = "val_sum" "wt_sum"

matrix consump_2014 = J(6,2,0)
matrix rownames consump_2014 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames consump_2014 = "val_sum" "wt_sum"

matrix resid_income_2006 = J(6,2,0)
matrix rownames resid_income_2006 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames resid_income_2006 = "val_sum" "wt_sum"

matrix resid_income_2014 = J(6,2,0)
matrix rownames resid_income_2014 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames resid_income_2014 = "val_sum" "wt_sum"

matrix resid_consump_2006 = J(6,2,0)
matrix rownames resid_consump_2006 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames resid_consump_2006 = "val_sum" "wt_sum"

matrix resid_consump_2014 = J(6,2,0)
matrix rownames resid_consump_2014 = "<10" "<25" "<50" ">50" ">75" ">90"
matrix colnames resid_consump_2014 = "val_sum" "wt_sum"

//Loop through all 2006 data
preserve
drop if year != 2006
local N = _N
forval i=1/`N'{
	//Check each percentile
	forval j=1/3{
		//Using non residualized income
		//Checks 10th,25th, and <50th percentiles
		if income[`i']<income_pctiles_2006[1,`j']{
			//Add to respective 2006 pctile bucket
			matrix income_2006[`j',1] = income_2006[`j',1] + income[`i']*weight[`i']
			matrix income_2006[`j',2] = income_2006[`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix consump_2006[`j',1] = consump_2006[`j',1] + consumption[`i']*weight[`i']
			matrix consump_2006[`j',2] = consump_2006[`j',2] + weight[`i']
		}
		//Checks 90th,75th, and >50th percentiles
		if income[`i']>income_pctiles_2006[1,7-`j']{
			//Add to respective 2006 pctile bucket
			matrix income_2006[7-`j',1] = income_2006[7-`j',1] + income[`i']*weight[`i']
			matrix income_2006[7-`j',2] = income_2006[7-`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix consump_2006[7-`j',1] = consump_2006[7-`j',1] + consumption[`i']*weight[`i']
			matrix consump_2006[7-`j',2] = consump_2006[7-`j',2] + weight[`i']
		}
		//Using residualized income
		//Checks 10th,25th, and <50th percentiles
		if resid_income[`i']<resid_income_pctiles_2006[1,`j']{
			//Add to respective 2006 pctile bucket
			matrix resid_income_2006[`j',1] = resid_income_2006[`j',1] + resid_income[`i']*weight[`i']
			matrix resid_income_2006[`j',2] = resid_income_2006[`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix resid_consump_2006[`j',1] = resid_consump_2006[`j',1] + resid_consump[`i']*weight[`i']
			matrix resid_consump_2006[`j',2] = resid_consump_2006[`j',2] + weight[`i']
		}
		//Checks 90th,75th, and >50th percentiles
		if resid_income[`i']>resid_income_pctiles_2006[1,7-`j']{
			//Add to respective 2006 pctile bucket
			matrix resid_income_2006[7-`j',1] = resid_income_2006[7-`j',1] + resid_income[`i']*weight[`i']
			matrix resid_income_2006[7-`j',2] = resid_income_2006[7-`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix resid_consump_2006[7-`j',1] = resid_consump_2006[7-`j',1] + resid_consump[`i']*weight[`i']
			matrix resid_consump_2006[7-`j',2] = resid_consump_2006[7-`j',2] + weight[`i']
		}
	}
}
restore

//Loop through all 2014 data
preserve
drop if year != 2014
local N = _N
forval i=1/`N'{
	//Check each percentile
	forval j=1/3{
		//Using non residualized income
		//Checks 10th,25th, and <50th percentiles
		if income[`i']<income_pctiles_2014[1,`j']{
			//Add to respective 2006 pctile bucket
			matrix income_2014[`j',1] = income_2014[`j',1] + income[`i']*weight[`i']
			matrix income_2014[`j',2] = income_2014[`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix consump_2014[`j',1] = consump_2014[`j',1] + consumption[`i']*weight[`i']
			matrix consump_2014[`j',2] = consump_2014[`j',2] + weight[`i']
		}
		//Checks 90th,75th, and >50th percentiles
		if income[`i']>income_pctiles_2014[1,7-`j']{
			//Add to respective 2006 pctile bucket
			matrix income_2014[7-`j',1] = income_2014[7-`j',1] + income[`i']*weight[`i']
			matrix income_2014[7-`j',2] = income_2014[7-`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix consump_2014[7-`j',1] = consump_2014[7-`j',1] + consumption[`i']*weight[`i']
			matrix consump_2014[7-`j',2] = consump_2014[7-`j',2] + weight[`i']
		}
		//Using residualized income
		//Checks 10th,25th, and <50th percentiles
		if resid_income[`i']<resid_income_pctiles_2014[1,`j']{
			//Add to respective 2006 pctile bucket
			matrix resid_income_2014[`j',1] = resid_income_2014[`j',1] + resid_income[`i']*weight[`i']
			matrix resid_income_2014[`j',2] = resid_income_2014[`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix resid_consump_2014[`j',1] = resid_consump_2014[`j',1] + resid_consump[`i']*weight[`i']
			matrix resid_consump_2014[`j',2] = resid_consump_2014[`j',2] + weight[`i']
		}
		//Checks 90th,75th, and >50th percentiles
		if resid_income[`i']>resid_income_pctiles_2014[1,7-`j']{
			//Add to respective 2006 pctile bucket
			matrix resid_income_2014[7-`j',1] = resid_income_2014[7-`j',1] + resid_income[`i']*weight[`i']
			matrix resid_income_2014[7-`j',2] = resid_income_2014[7-`j',2] + weight[`i']
			//Add to respective 2006 pctile bucket
			matrix resid_consump_2014[7-`j',1] = resid_consump_2014[7-`j',1] + resid_consump[`i']*weight[`i']
			matrix resid_consump_2014[7-`j',2] = resid_consump_2014[7-`j',2] + weight[`i']
		}
	}
}

//Generate matrix to store all values
matrix final_table = J(9,8,.)
matrix rownames final_table = ">90" "<10" ">90/<10" ">75" "<25" ">75/<25" ">50" "<50" ">50/<50"
matrix colnames final_table = "2006i" "2014i" "2006c" "2014c" "2006ri" "2014ri" "2006rc" "2014rc"





//esttab matrix(final_table) using table2.txt,replace

