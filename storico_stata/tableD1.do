log using tableD1,replace

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

keep nquest year age hhold_size gender region weight y* cn acom5 studio

//Drop data before 1995, n=86729
drop if year < 1995

//After dropping if residing in a small location n=75977 (same as paper)
drop if acom5 == 1

//After dropping if age of household head outside [25,60] n=42202 (vs 43,505 in paper)
drop if age<25
drop if age>60

//Create consumption as in paper
//gen consumption = cn/hhold_size
gen consumption = cn - yca2 - yl2
gen consumption_pc = cn/hhold_size
gen income = (yl1+yt+ym+yc)

//Deflate income and consumption variables using OECD CPI numbers (base year is 2015)
replace income = income/(86.4/100) if year == 2006
replace consumption = consumption/(86.4/100) if year == 2006
replace income = income/(99.9/100) if year == 2014
replace consumption = consumption/(99.9/100) if year == 2014
/*replace income = income/(.9384078) if year == 2006
replace consumption = consumption/(.9384078) if year == 2006
replace income = income/(1.072381) if year == 2014
replace consumption = consumption/(1.072381) if year == 2014
*/

//Drop if negative income/consumption
drop if income<.01
drop if consumption < .01

//Define income to consumption ration
gen inc_cons_ratio = income/consumption

//gen cutoff vals and use to trim top and bottom .5% of data
//Basically adding wieghts in order until get .5% of weight then use current inc_cons_ratio as cutoff val
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

//Use cutoffs to drop top and bot .5% of data
drop if inc_cons_ratio > `top_cutoff'
drop if inc_cons_ratio < `bot_cutoff'

//After dropping outliers and negative income n=41740 (vs 42,286 in paper)

//After dropping all data not in 2006 or 2014 n=7036 (vs 7060 in paper)
drop if year != 2006 & year != 2014


//gen log consumption var
gen ln_cons = log(consumption)
gen ln_cons_pc = log(consumption_pc)

//Literally just get average log consumption in 2006 and 2014 using weights
sum ln_cons if year == 2006 [aweight = weight]
sum ln_cons if year == 2014 [aweight = weight]
sum ln_cons_pc if year == 2006 [aweight = weight]
sum ln_cons_pc if year == 2014 [aweight = weight]
