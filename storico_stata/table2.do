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

keep nquest year age hhold_size gender region weight y* c* acom5 studio


label variable yl "Compensation of employees"
label variable yl1 "Net wages and salaries"
label variable yl2 "Fringe benefits"
label variable yt "Pensions and other transfers"
label variable ytp "Pensions and Arrears"
label variable yta "Other transfers"
label variable ytp "Pensions and Arrears"
label variable ym "Net income from self-employment and entrepreneurial income"
label variable ym1 "Income from self-employment"
label variable ym3 "Entrepreneurial income (profits and dividends) "
label variable yc "Property income"
label variable yca "Income from buildings"
label variable ycf "Income from financial assets "


//Drop data before 1995, n=86729
drop if year < 1995

//Drop if residing in a small location n=75977
drop if acom5 == 1

//Drop if age of household head outside [25,60] n=42202
drop if age<25
drop if age>60

//Create consumption and income cols as in paper
//gen income = yl1+yt+ym+yc
gen income = y1
//gen income = ytp1 +yta + yl1+ym1 + yc
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
//The bottom cutoff is 0, so I drop a bunch of values here. Not sure what to do exactly
drop if inc_cons_ratio <= `bot_cutoff'

sum income

//drop data not in 2006 or 2014
//n=7036 vs 7060 in paper
drop if year != 2006 & year != 2014

sum income if year == 2006
sum income if year == 2014

//Create a categorical education variable as defined in paper
gen educ = 1 if studio == 1 | studio ==2 
replace educ = 2 if studio == 3
replace educ = 3 if studio == 4 | studio == 5
replace educ = 4 if studio == 6

sum income if year == 2006
//Deflate income and consumption variables using OECD CPI numbers (base year is 2015)
/*replace income = income/(86.4/100) if year == 2006
replace consumption = consumption/(86.4/100) if year == 2006
replace income = income/(99.9/100) if year == 2014
replace consumption = consumption/(99.9/100) if year == 2014
*/
replace income = income/(86.36923/100) if year == 2006
replace consumption = consumption/(86.36923/100) if year == 2006
replace income = income/(99.93023/100) if year == 2014
replace consumption = consumption/(99.93023/100) if year == 2014

sum income if year == 2006

//Use sample weights to get unbiased income and consumption numbers
//replace income = income*peso
//replace consump = consump*peso

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

matrix income_pctile_vals = J(5,2,.)
matrix consump_pctile_vals = J(5,2,.)
matrix resid_income_pctile_vals = J(5,2,.)
matrix resid_consump_pctile_vals = J(5,2,.)

matrix index_test = J(5,2,.)
matrix pctile_cons_test = J(3,1,.)


matrix cutoffs = [10,25,50,75,90]

//Calculate 2006 non residual values
preserve
drop if year != 2006
egen total_weight = sum(weight)
//Loop to generate income and consumption percentile vals for 2006
sort(income)
local curr_cutoff = 1
local curr_weight = 0
local N = _N
forval i = 1/`N'{
    local curr_weight = `curr_weight' + weight[`i']
	//Find household at each cutoff value
	if `curr_weight' > cutoffs[1,`curr_cutoff']*.01*total_weight[1]{
		local weighted_cons_sum = 0
		local weighted_inc_sum = 0
		local obs_counter = 0
		local pctile_weight = 0
		//for 10 or 25 percentile, take weighted sum until 10/25
		if `curr_cutoff' == 1 | `curr_cutoff' == 2{
			forval j = 1/`i'{
				local weighted_cons_sum = `weighted_cons_sum' + consumption[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix income_pctile_vals[`curr_cutoff',1] = `weighted_inc_sum'/`pctile_weight'
			matrix consump_pctile_vals[`curr_cutoff',1] = `weighted_cons_sum'/`pctile_weight'
		}
		//for 75 or 90 percentile, same concept, but loop is diff
		if `curr_cutoff' == 4 | `curr_cutoff' == 5{
			forval j = `i'/`N'{
				local weighted_cons_sum = `weighted_cons_sum' + consumption[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix income_pctile_vals[`curr_cutoff',1] = `weighted_inc_sum'/`pctile_weight'
			matrix consump_pctile_vals[`curr_cutoff',1] = `weighted_cons_sum'/`pctile_weight'
		}
		
		
		
		
		
		//For 50th pctile instead put in the average weighted for top and bot halves
		if `curr_cutoff' == 3{
			gen weighted_inc = income*weight
			gen weighted_cons = consumption*weight
			
			sum weighted_inc if income > income[`i']
			local upper_half_inc = r(mean)/`curr_weight' 
			sum weighted_inc if income < income[`i']
			local lower_half_inc = r(mean)/`curr_weight'
			matrix income_pctile_vals[`curr_cutoff',1] = `upper_half_inc'/`lower_half_inc'
			
			sum weighted_cons if income > income[`i']
			local upper_half_cons = r(mean)/`curr_weight' 
			sum weighted_cons if income < income[`i']
			local lower_half_cons = r(mean)/`curr_weight'
			matrix consump_pctile_vals[`curr_cutoff',1] = `upper_half_cons'/`lower_half_cons'
			
			drop weighted_inc
			drop weighted_cons
		}
		
		local curr_cutoff = `curr_cutoff' + 1
		//Break loop after calculating 90th percentile
		if `curr_cutoff' == 6{
				continue, break
		}
	}
}

//Calculate 2014 non residual values
restore
preserve
drop if year != 2014
egen total_weight = sum(weight)
//Loop to generate income and consumption percentile vals for 2014
sort(income)
local curr_cutoff = 1
local curr_weight = 0
local N = _N
forval i = 1/`N'{
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > cutoffs[1,`curr_cutoff']*.01*total_weight[1]{
	    local weighted_cons_sum = 0
		local weighted_inc_sum = 0
		local obs_counter = 0
		local pctile_weight = 0
		//for 10 or 25 percentile, take weighted sum until 10/25
		if `curr_cutoff' == 1 | `curr_cutoff' == 2{
			forval j = 1/`i'{
				local weighted_cons_sum = `weighted_cons_sum' + consumption[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix income_pctile_vals[`curr_cutoff',2] = `weighted_inc_sum'/`pctile_weight'
			matrix consump_pctile_vals[`curr_cutoff',2] = `weighted_cons_sum'/`pctile_weight'
		}
		//for 75 or 90 percentile, same concept, but loop is diff
		if `curr_cutoff' == 4 | `curr_cutoff' == 5{
			forval j = `i'/`N'{
				local weighted_cons_sum = `weighted_cons_sum' + consumption[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix income_pctile_vals[`curr_cutoff',2] = `weighted_inc_sum'/`pctile_weight'
			matrix consump_pctile_vals[`curr_cutoff',2] = `weighted_cons_sum'/`pctile_weight'
		}
		
		//For 50th pctile instead put in the average weighted for top and bot halves
		if `curr_cutoff' == 3{
			gen weighted_inc = income*weight
			gen weighted_cons = consumption*weight
			
			sum weighted_inc if income > income[`i']
			local upper_half_inc = r(mean)/`curr_weight' 
			sum weighted_inc if income < income[`i']
			local lower_half_inc = r(mean)/`curr_weight'
			matrix income_pctile_vals[`curr_cutoff',2] = `upper_half_inc'/`lower_half_inc'
			
			sum weighted_cons if income > income[`i']
			local upper_half_cons = r(mean)/`curr_weight' 
			sum weighted_cons if income < income[`i']
			local lower_half_cons = r(mean)/`curr_weight'
			matrix consump_pctile_vals[`curr_cutoff',2] = `upper_half_cons'/`lower_half_cons'
			
			drop weighted_inc
			drop weighted_cons
		}
		
		local curr_cutoff = `curr_cutoff' + 1
		//Break loop after calculating 90th percentile
		if `curr_cutoff' == 6{
				continue, break
		}
	}
}


//Calculate 2006 residual values
restore
preserve
drop if year != 2006
egen total_weight = sum(weight)
//Loop to generate income and consumption percentile vals for 2014
sort(resid_income)
local curr_cutoff = 1
local curr_weight = 0
local N = _N
forval i = 1/`N'{
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > cutoffs[1,`curr_cutoff']*.01*total_weight[1]{
	    local weighted_cons_sum = 0
		local weighted_inc_sum = 0
		local obs_counter = 0
		local pctile_weight = 0
		//for 10 or 25 percentile, take weighted sum until 10/25
		if `curr_cutoff' == 1 | `curr_cutoff' == 2{
			forval j = 1/`i'{
				local weighted_cons_sum = `weighted_cons_sum' + resid_consump[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + resid_income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix resid_income_pctile_vals[`curr_cutoff',1] = `weighted_inc_sum'/`pctile_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',1] = `weighted_cons_sum'/`pctile_weight'
		}
		//for 75 or 90 percentile, same concept, but loop is diff
		if `curr_cutoff' == 4 | `curr_cutoff' == 5{
			forval j = `i'/`N'{
				local weighted_cons_sum = `weighted_cons_sum' + resid_consump[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + resid_income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix resid_income_pctile_vals[`curr_cutoff',1] = `weighted_inc_sum'/`pctile_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',1] = `weighted_cons_sum'/`pctile_weight'
		}
		
		//For 50th pctile instead put in the average weighted for top and bot halves
		if `curr_cutoff' == 3{
			gen weighted_inc = resid_income*weight
			gen weighted_cons = resid_consump*weight
			
			sum weighted_inc if resid_income > resid_income[`i']
			local upper_half_inc = r(mean)/`curr_weight' 
			sum weighted_inc if resid_income < resid_income[`i']
			local lower_half_inc = r(mean)/`curr_weight'
			matrix resid_income_pctile_vals[`curr_cutoff',1] = `upper_half_inc'/`lower_half_inc'
			
			sum weighted_cons if resid_income > resid_income[`i']
			local upper_half_cons = r(mean)/`curr_weight' 
			sum weighted_cons if resid_income < resid_income[`i']
			local lower_half_cons = r(mean)/`curr_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',1] = `upper_half_cons'/`lower_half_cons'
			
			drop weighted_inc
			drop weighted_cons
		}
		
		local curr_cutoff = `curr_cutoff' + 1
		//Break loop after calculating 90th percentile
		if `curr_cutoff' == 6{
				continue, break
		}
	}
}

//Calculate 2014 residual values
restore
preserve
drop if year != 2014
egen total_weight = sum(weight)
//Loop to generate income and consumption percentile vals for 2014
sort(resid_income)
local curr_cutoff = 1
local curr_weight = 0
local N = _N
forval i = 1/`N'{
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > cutoffs[1,`curr_cutoff']*.01*total_weight[1]{
	    local weighted_cons_sum = 0
		local weighted_inc_sum = 0
		local obs_counter = 0
		local pctile_weight = 0
		//for 10 or 25 percentile, take weighted sum until 10/25
		if `curr_cutoff' == 1 | `curr_cutoff' == 2{
			forval j = 1/`i'{
				local weighted_cons_sum = `weighted_cons_sum' + resid_consump[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + resid_income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix resid_income_pctile_vals[`curr_cutoff',2] = `weighted_inc_sum'/`pctile_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',2] = `weighted_cons_sum'/`pctile_weight'
		}
		//for 75 or 90 percentile, same concept, but loop is diff
		if `curr_cutoff' == 4 | `curr_cutoff' == 5{
			forval j = `i'/`N'{
				local weighted_cons_sum = `weighted_cons_sum' + resid_consump[`j']*weight[`j']
				local weighted_inc_sum = `weighted_inc_sum' + resid_income[`j']*weight[`j']
				local obs_counter = `obs_counter' + 1
				local pctile_weight = `pctile_weight' + weight[`j']
			}
			matrix resid_income_pctile_vals[`curr_cutoff',2] = `weighted_inc_sum'/`pctile_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',2] = `weighted_cons_sum'/`pctile_weight'
		}
		
		
		//For 50th pctile instead put in the average weighted for top and bot halves
		if `curr_cutoff' == 3{
			gen weighted_inc = resid_income*weight
			gen weighted_cons = resid_consump*weight
			
			sum weighted_inc if resid_income > resid_income[`i']
			local upper_half_inc = r(mean)/`curr_weight'
			sum weighted_inc if resid_income < resid_income[`i']
			local lower_half_inc = r(mean)/`curr_weight'
			matrix resid_income_pctile_vals[`curr_cutoff',2] = `upper_half_inc'/`lower_half_inc'
			
			sum weighted_cons if resid_income > resid_income[`i']
			local upper_half_cons = r(mean)/`curr_weight'
			sum weighted_cons if resid_income < resid_income[`i']
			local lower_half_cons = r(mean)/`curr_weight'
			matrix resid_consump_pctile_vals[`curr_cutoff',2] = `upper_half_cons'/`lower_half_cons'
			
			drop weighted_inc
			drop weighted_cons
		}
		
		local curr_cutoff = `curr_cutoff' + 1
		//Break loop after calculating 90th percentile
		if `curr_cutoff' == 6{
				continue, break
		}
	}
}
*/
matrix list income_pctile_vals
matrix list consump_pctile_vals
matrix list resid_income_pctile_vals
matrix list resid_consump_pctile_vals

//Calculate 90/10 and 75/25 ratios
matrix income_ratios = J(2,2,.)
matrix consump_ratios = J(2,2,.)
matrix resid_income_ratios = J(2,2,.)
matrix resid_consump_ratios = J(2,2,.)

matrix income_ratios[1,1] = income_pctile_vals[5,1]/income_pctile_vals[1,1]
matrix income_ratios[2,1] = income_pctile_vals[4,1]/income_pctile_vals[2,1]
matrix income_ratios[1,2] = income_pctile_vals[5,2]/income_pctile_vals[1,2]
matrix income_ratios[2,2] = income_pctile_vals[4,2]/income_pctile_vals[2,2]

matrix consump_ratios[1,1] = consump_pctile_vals[5,1]/consump_pctile_vals[1,1]
matrix consump_ratios[2,1] = consump_pctile_vals[4,1]/consump_pctile_vals[2,1]
matrix consump_ratios[1,2] = consump_pctile_vals[5,2]/consump_pctile_vals[1,2]
matrix consump_ratios[2,2] = consump_pctile_vals[4,2]/consump_pctile_vals[2,2]

matrix resid_income_ratios[1,1] = resid_income_pctile_vals[5,1]/resid_income_pctile_vals[1,1]
matrix resid_income_ratios[2,1] = resid_income_pctile_vals[4,1]/resid_income_pctile_vals[2,1]
matrix resid_income_ratios[1,2] = resid_income_pctile_vals[5,2]/resid_income_pctile_vals[1,2]
matrix resid_income_ratios[2,2] = resid_income_pctile_vals[4,2]/resid_income_pctile_vals[2,2]

matrix resid_consump_ratios[1,1] = resid_consump_pctile_vals[5,1]/resid_consump_pctile_vals[1,1]
matrix resid_consump_ratios[2,1] = resid_consump_pctile_vals[4,1]/resid_consump_pctile_vals[2,1]
matrix resid_consump_ratios[1,2] = resid_consump_pctile_vals[5,2]/resid_consump_pctile_vals[1,2]
matrix resid_consump_ratios[2,2] = resid_consump_pctile_vals[4,2]/resid_consump_pctile_vals[2,2]

matrix list income_pctile_vals
matrix list income_ratios
matrix list consump_pctile_vals
matrix list consump_ratios
matrix list resid_income_pctile_vals
matrix list resid_income_ratios
matrix list resid_consump_pctile_vals
matrix list resid_consump_ratios
matrix list index_test

matrix final_table = J(3,8,.)
matrix rownames final_table = "90/10" "75/25" "50/50"
matrix colnames final_table = "2006i" "2014i" "2006c" "2014c" "2006ri" "2014ri" "2006rc" "2014rc"

//Yes, this is probably the most trash code I've written in a while
//Fill in income ratios
matrix final_table[1,1] = income_ratios[1,1]
matrix final_table[2,1] = income_ratios[2,1]
matrix final_table[1,2] = income_ratios[1,2]
matrix final_table[2,2] = income_ratios[2,2]

matrix final_table[3,1] = income_pctile_vals[3,1]
matrix final_table[3,2] = income_pctile_vals[3,2]
//Fill in consump ratios
matrix final_table[1,3] = consump_ratios[1,1]
matrix final_table[2,3] = consump_ratios[2,1]
matrix final_table[1,4] = consump_ratios[1,2]
matrix final_table[2,4] = consump_ratios[2,2]

matrix final_table[3,3] = consump_pctile_vals[3,1]
matrix final_table[3,4] = consump_pctile_vals[3,2]
//Fill in residual income ratios
matrix final_table[1,5] = resid_income_ratios[1,1]
matrix final_table[2,5] = resid_income_ratios[2,1]
matrix final_table[1,6] = resid_income_ratios[1,2]
matrix final_table[2,6] = resid_income_ratios[2,2]

matrix final_table[3,5] = resid_income_pctile_vals[3,1]
matrix final_table[3,6] = resid_income_pctile_vals[3,2]
//Fill in residual consumption ratios
matrix final_table[1,7] = resid_consump_ratios[1,1]
matrix final_table[2,7] = resid_consump_ratios[2,1]
matrix final_table[1,8] = resid_consump_ratios[1,2]
matrix final_table[2,8] = resid_consump_ratios[2,2]

matrix final_table[3,7] = resid_consump_pctile_vals[3,1]
matrix final_table[3,8] = resid_consump_pctile_vals[3,2]

esttab matrix(final_table) using table2.txt,replace

