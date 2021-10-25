log using figB1,replace

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

//make age sqr variable
gen age_sqr = age^2

//make educ variable
gen educ = 1 if studio == 1 | studio ==2 
replace educ = 2 if studio == 3
replace educ = 3 if studio == 4 | studio == 5
replace educ = 4 if studio == 6

//deflate income and consumption
matrix cpi = [66.5 ,	69.2 ,	70.6 ,	72.0, 	73.2 ,	75.1 ,	77.1 ,	79.0 ,	81.2 ,	83.0 	,84.6 ,	86.4 ,	87.9 ,	90.9 	,91.6 ,	93.0 ,	95.6 ,	98.5 ,	99.7 	,99.9, 	100.0 ,	99.9 ]
local year = 1995
local counter = 1
forval i =1/11{
	replace income = income/(cpi[1,`counter']/100) if year == `year'
	replace consumption = consumption/(cpi[1,`counter']/100) if year == `year'
	if  `i' ==1{
		local year = `year' + 3
		local counter = `counter' + 3
	}
	if `i'!=1{
		local year = `year' + 2
		local counter = `counter' + 2
	}
}

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


gen ln_cons = log(consumption)
reg ln_cons year [pweight = weight]
predict resid_log_cons_basic, residuals
reg ln_cons age age_sqr i.gender i.educ hhold_size i.region i.educ#year i.gender#year i.year [pweight = weight]
predict resid_log_cons_big, residuals

//get per capita vals
//something like income*weight/pop

matrix b_1_resid = J(11,2,.)
matrix b_1_actual = J(11,2,.)
local year = 1995

egen avg_2006_resid = mean(resid_log_cons_basic) if year == 2006
egen avg_2006_actual = mean(resid_log_cons_big) if year == 2006
sum avg_2006_resid
local base_year_resid = r(mean) 
sum avg_2006_actual
local base_year_actual = r(mean)
drop avg_2006_resid
drop avg_2006_actual
forval i =1/11{
	egen curr_avg_resid = mean(resid_log_cons_basic) if year == `year' 
	egen curr_avg_actual = mean(resid_log_cons_big) if year == `year' 
	sum curr_avg_resid if year == `year'  
	matrix b_1_resid[`i',1] = r(mean) - `base_year_resid'
	sum curr_avg_actual if year == `year'  
	matrix b_1_actual[`i',1] = r(mean) - `base_year_actual'
	drop curr_avg_resid
	drop curr_avg_actual
	//Add col for year
	matrix b_1_resid[`i',2] = `year'
	matrix b_1_actual[`i',2] = `year'
	if `i' == 1{
		local year = 1998
	}
	else{
		local year = `year' + 2
	}
}

matrix list b_1_resid
matrix list b_1_actual




