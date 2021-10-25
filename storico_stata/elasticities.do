log using italy_elasticities,replace

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
replace income = income/(86.4/100) if year == 2006
replace consumption = consumption/(86.4/100) if year == 2006
replace income = income/(99.9/100) if year == 2014
replace consumption = consumption/(99.9/100) if year == 2014
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

sum resid_income  if year == 2006
sum resid_income if year == 2014
sum resid_consump if year == 2006
sum resid_consump if year == 2014

//Calculate cutoff values for each decile for each year based off of weights
sort(resid_income)
preserve
drop if year == 2014
matrix deciles_2006 = J(9,1,.)
egen total_weight_2006 = sum(weight)
local curr_cutoff = 1
local curr_weight = 0
forval i = 1/`N'{
	//Only need 9 cutoff vals to split into 10 deciles so this is just a way to stop loop
	if `curr_cutoff' == 10{
			continue, break
	}
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > .1*total_weight_2006[1]{
		matrix deciles_2006[`curr_cutoff',1] = resid_income[`i'-1]
		local curr_cutoff = `curr_cutoff' + 1
		local curr_weight = weight[`i']
	}
} 
restore
//Calculate 2014 weights
preserve
drop if year == 2006
matrix deciles_2014 = J(9,1,.)
egen total_weight_2014 = sum(weight)
local curr_cutoff = 1
local curr_weight = 0
forval i = 1/`N'{
	//Only need 9 cutoff vals to split into 10 deciles so this is just a way to stop loop
	if `curr_cutoff' == 10{
			continue, break
	}
    local curr_weight = `curr_weight' + weight[`i']
	if `curr_weight' > .1*total_weight_2014[1]{
		matrix deciles_2014[`curr_cutoff',1] = resid_income[`i'-1]
		local curr_cutoff = `curr_cutoff' + 1
		local curr_weight = weight[`i']
	}
} 
restore
matrix list deciles_2006
matrix list deciles_2014



/*
//Define avg_incomes_residual and avg_consumption_residual to hold numbers for each decile. First col is 2006 data, second col is 2014 data
//Each row represents average for each decile
matrix avg_incomes_residual = J(10,2,.)
matrix avg_consumption_residual = J(10,2,.)
//Generate averages for the first decile of data
egen avg_inc_2006 = mean(resid_income) if year == 2006 & resid_income<deciles_2006[1,1]
egen avg_cons_2006 = mean(resid_consump) if year == 2006 & resid_income<deciles_2006[1,1]
egen avg_inc_2014 = mean(resid_income) if year == 2014 & resid_income<deciles_2014[1,1]
egen avg_cons_2014 = mean(resid_consump) if year == 2014 & resid_income<deciles_2014[1,1]
//Store values in respective matrices
sum avg_inc_2006
matrix avg_incomes_residual[1,1] = r(mean)
sum avg_cons_2006
matrix avg_consumption_residual[1,1] = r(mean)
sum avg_inc_2014
matrix avg_incomes_residual[1,2] = r(mean)
sum avg_cons_2014
matrix avg_consumption_residual[1,2] = r(mean)
//drop all new cols so don't get errors when generating them again
drop avg_inc_2006
drop avg_cons_2006
drop avg_inc_2014
drop avg_cons_2014
forval i=1/8{
	//get averages for decile of data with residual income between ith cutoff and i+1 cutoff 
	egen avg_inc_2006 = mean(resid_income) if year == 2006 & resid_income >= deciles_2006[`i',1] & resid_income < deciles_2006[`i'+1,1]
	egen avg_cons_2006 = mean(resid_consump) if year == 2006 & resid_income >= deciles_2006[`i',1] & resid_income < deciles_2006[`i'+1,1]
	egen avg_inc_2014 = mean(resid_income) if year == 2014 & resid_income >= deciles_2014[`i',1] & resid_income < deciles_2014[`i'+1,1]
	egen avg_cons_2014 = mean(resid_consump) if year == 2014 & resid_income >= deciles_2014[`i',1] & resid_income < deciles_2014[`i'+1,1]
	sum avg_inc_2006
	matrix avg_incomes_residual[`i'+1,1] = r(mean)
	sum avg_cons_2006
	matrix avg_consumption_residual[`i'+1,1] = r(mean)
	sum avg_inc_2014
	matrix avg_incomes_residual[`i'+1,2] = r(mean)
	sum avg_cons_2014
	matrix avg_consumption_residual[`i'+1,2] = r(mean)
	//drop all new cols so don't get errors when generating them again
	drop avg_inc_2006
	drop avg_cons_2006
	drop avg_inc_2014
	drop avg_cons_2014
}
egen avg_inc_2006 = mean(resid_income) if year == 2006 & resid_income>=deciles_2006[9,1]
egen avg_cons_2006 = mean(resid_consump) if year == 2006 & resid_income>=deciles_2006[9,1]
egen avg_inc_2014 = mean(resid_income) if year == 2014 & resid_income>=deciles_2014[9,1]
egen avg_cons_2014 = mean(resid_consump) if year == 2014 & resid_income>=deciles_2014[9,1]
sum avg_inc_2006
matrix avg_incomes_residual[10,1] = r(mean)
sum avg_cons_2006
matrix avg_consumption_residual[10,1] = r(mean)
sum avg_inc_2014
matrix avg_incomes_residual[10,2] = r(mean)
sum avg_cons_2014
matrix avg_consumption_residual[10,2] = r(mean)
//drop all new cols so don't get errors when generating them again
drop avg_inc_2006
drop avg_cons_2006
drop avg_inc_2014
drop avg_cons_2014
*/

/*
//This chunk of code uses pre defined deciles to get elasticities
//Define avg_incomes_residual and avg_consumption_residual to hold numbers for each decile. First col is 2006 data, second col is 2014 data
//Each row represents average for each decile
matrix avg_incomes_residual = J(10,2,.)
matrix avg_consumption_residual = J(10,2,.)
forval i=1/10{
	//get averages for decile of data with residual income between ith cutoff and i+1 cutoff 
	egen avg_inc_2006 = mean(resid_income) if year == 2006 & cly == `i'
	egen avg_cons_2006 = mean(resid_consump) if year == 2006 & cly == `i'
	egen avg_inc_2014 = mean(resid_income) if year == 2014 & cly == `i'
	egen avg_cons_2014 = mean(resid_consump) if year == 2014 & cly == `i'
	sum avg_inc_2006
	matrix avg_incomes_residual[`i',1] = r(mean)
	sum avg_cons_2006
	matrix avg_consumption_residual[`i',1] = r(mean)
	sum avg_inc_2014
	matrix avg_incomes_residual[`i',2] = r(mean)
	sum avg_cons_2014
	matrix avg_consumption_residual[`i',2] = r(mean)
	//drop all new cols so don't get errors when generating them again
	drop avg_inc_2006
	drop avg_cons_2006
	drop avg_inc_2014
	drop avg_cons_2014
}
*/

/*
//This chunk of code uses pre defined deciles to get elasticities
//Define avg_incomes_residual and avg_consumption_residual to hold numbers for each decile. First col is 2006 data, second col is 2014 data
//Each row represents average for each decile
matrix avg_incomes_residual = J(10,2,.)
matrix avg_consumption_residual = J(10,2,.)
forval i=1/10{
	//get averages for decile of data with residual income between ith cutoff and i+1 cutoff 
	egen avg_inc_2006 = mean(income) if year == 2006 & cly == `i'
	egen avg_cons_2006 = mean(consump) if year == 2006 & cly == `i'
	egen avg_inc_2014 = mean(income) if year == 2014 & cly == `i'
	egen avg_cons_2014 = mean(consump) if year == 2014 & cly == `i'
	sum avg_inc_2006
	matrix avg_incomes_actual[`i',1] = r(mean)
	sum avg_cons_2006
	matrix avg_consumption_actual[`i',1] = r(mean)
	sum avg_inc_2014
	matrix avg_incomes_actual[`i',2] = r(mean)
	sum avg_cons_2014
	matrix avg_consumption_actual[`i',2] = r(mean)
	//drop all new cols so don't get errors when generating them again
	drop avg_inc_2006
	drop avg_cons_2006
	drop avg_inc_2014
	drop avg_cons_2014
}

//Using matrices of averages using residual numbers we calculate deltas. First col for income, second col for consumption
matrix deltas_residual = J(10,2,.)
forval i=1/10{
	//to each row in deltas_residual assigns log(2014 residual income/2006 residual income)
	matrix deltas_residual[`i',1]=log(avg_incomes_residual[`i',2]/avg_incomes_residual[`i',1])
	matrix deltas_residual[`i',2]=log(avg_consumption_residual[`i',2]/avg_consumption_residual[`i',1])
}

matrix list deltas_residual

//Finally using deltas calculate elasticities
matrix elasticities_residual = J(10,1,.)
forval i=1/10{
	//to each row in elasticities_residual assigns avg residual consumption/avg residual income
	matrix elasticities_residual[`i',1]=deltas_residual[`i',2]/deltas_residual[`i',1]
}

matrix list elasticities_residual
*/

//This whole chunk of code calculates elasticities assuming they are using actual income and consumption numbers

//Define matrix to hold numbers for each decile. First col is 2006 data, second col is 2014 data
matrix avg_incomes_actual = J(10,2,.)
matrix avg_consumption_actual = J(10,2,.)
//Generate averages. There's definitly a less verbose way of doing this, but it does seem to work
egen avg_inc_2006 = mean(income) if year == 2006 & resid_income<deciles_2006[1,1]
egen avg_cons_2006 = mean(consumption) if year == 2006 & resid_income<deciles_2006[1,1]
egen avg_inc_2014 = mean(income) if year == 2014 & resid_income<deciles_2014[1,1]
egen avg_cons_2014 = mean(consumption) if year == 2014 & resid_income<deciles_2014[1,1]
sum avg_inc_2006
matrix avg_incomes_actual[1,1] = r(mean)
sum avg_cons_2006
matrix avg_consumption_actual[1,1] = r(mean)
sum avg_inc_2014
matrix avg_incomes_actual[1,2] = r(mean)
sum avg_cons_2014
matrix avg_consumption_actual[1,2] = r(mean)
//drop all new cols so don't get errors when generating them again
drop avg_inc_2006
drop avg_cons_2006
drop avg_inc_2014
drop avg_cons_2014
forval i=1/8{
	egen avg_inc_2006 = mean(income) if year == 2006 & resid_income >= deciles_2006[`i',1] & resid_income < deciles_2006[`i'+1,1]
	egen avg_cons_2006 = mean(consumption) if year == 2006 & resid_income >= deciles_2006[`i',1] & resid_income < deciles_2006[`i'+1,1]
	egen avg_inc_2014 = mean(income) if year == 2014 & resid_income >= deciles_2014[`i',1] & resid_income < deciles_2014[`i'+1,1]
	egen avg_cons_2014 = mean(consumption) if year == 2014 & resid_income >= deciles_2014[`i',1] & resid_income < deciles_2014[`i'+1,1]
	sum avg_inc_2006
	matrix avg_incomes_actual[`i'+1,1] = r(mean)
	sum avg_cons_2006
	matrix avg_consumption_actual[`i'+1,1] = r(mean)
	sum avg_inc_2014
	matrix avg_incomes_actual[`i'+1,2] = r(mean)
	sum avg_cons_2014
	matrix avg_consumption_actual[`i'+1,2] = r(mean)
	//drop all new cols so don't get errors when generating them again
	drop avg_inc_2006
	drop avg_cons_2006
	drop avg_inc_2014
	drop avg_cons_2014
}
egen avg_inc_2006 = mean(income) if year == 2006 & resid_income>=deciles_2006[9,1]
egen avg_cons_2006 = mean(consumption) if year == 2006 & resid_income>=deciles_2006[9,1]
egen avg_inc_2014 = mean(income) if year == 2014 & resid_income>=deciles_2014[9,1]
egen avg_cons_2014 = mean(consumption) if year == 2014 & resid_income>=deciles_2014[9,1]
sum avg_inc_2006
matrix avg_incomes_actual[10,1] = r(mean)
sum avg_cons_2006
matrix avg_consumption_actual[10,1] = r(mean)
sum avg_inc_2014
matrix avg_incomes_actual[10,2] = r(mean)
sum avg_cons_2014
matrix avg_consumption_actual[10,2] = r(mean)
//drop all new cols so don't get errors when generating them again
drop avg_inc_2006
drop avg_cons_2006
drop avg_inc_2014
drop avg_cons_2014


//Using matrices of averages using residual numbers we calculate deltas. First col for income, second col for consumption
//Using matrices of averages using actual income and consumption numbers we calculate deltas. First col for income, second col for consumption
matrix deltas_actual = J(10,2,.)
forval i=1/10{
	matrix deltas_actual[`i',1]=log(avg_incomes_actual[`i',2]/avg_incomes_actual[`i',1])
	matrix deltas_actual[`i',2]=log(avg_consumption_actual[`i',2]/avg_consumption_actual[`i',1])
}

matrix list deltas_actual

//Finally using deltas calculate elasticities
matrix elasticities_actual = J(10,1,.)
forval i=1/10{
	matrix elasticities_actual[`i',1]=deltas_actual[`i',2]/deltas_actual[`i',1]
}

matrix list elasticities_actual



sum resid_income if year == 2006
sum resid_income if year == 2014
sum income if year == 2006
sum income if year == 2014
sum resid_consump  if year == 2006
sum resid_consump if year == 2014
sum consump if year == 2006
sum consump if year == 2014

matrix list avg_incomes_actual
matrix list deltas_actual