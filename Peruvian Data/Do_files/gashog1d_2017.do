**********************************************************************************************
*ENAHO (2004-2018)
*Author: Yaakov Levin
*Last updated: 2/23
*Cleans ENAHO raw data
*Inputs: ENAHO raw data - modules 100,601,603,605,606,606d,607,609,610,611,612,634
*Output:
	*A matrix containing the aggregate tradable, non tradable, non classified, and durable expenditures
**********************************************************************************************

clear all
set more off
*Set path to the root of working directory
    global ccc_root    "C:/Users/g1ysl01/Documents/Arce_consumption/Peruvian Data"
*Set path to folder containing do-files
    global ccc_dofiles "$ccc_root/Do_files"
*Set path to input folder
    global ccc_in      "$ccc_root/Raw_Data"
*Set path to output folder
    global ccc_out     "$ccc_root/out"

cd "$ccc_root"

*First sum all of the components made up of a single var
use "$ccc_in/sumaria/2017/sumaria-2017-12.dta", clear
gen one_sum = gru21hd + gru21hd1 + gru91hd3 
gen two_sum = g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3
gen three_sum = sg42 + sg422 + sg421 

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum three_sum  

*Save in file
save Trash/temp_sums, replace


*GRU11HD
************************************Module 605**********************************
use "$ccc_in/module 05/2017/2017.dta", clear

//Generate flag for p559d, t559b and p559c vars checking they should be summed or not
//I think need flag for all 50 vals
forval i=1/15{
	if `i'<10{
		gen p559d_`i'_flag = 1 if p559d_0`i'>0
		gen t559b_`i'_flag = 1 if t559b_0`i'==21
		gen p559c_`i'_flag = 1 if p559c_0`i'==1
	}
	if `i'>=10{
		gen p559d_`i'_flag = 1 if p559d_`i'>0
		gen t559b_`i'_flag = 1 if t559b_`i'==21
		gen p559c_`i'_flag = 1 if p559c_`i'==1
	}
}

//Also generate flags for P204=1, P203!=8,9, and P208A >= 14
gen sum_flag = 0
replace sum_flag = 1 if p204==1 & (p203!=8 & p203!=9) & p208a>=14

//Loop through all 50 i55d_n variables and replace vals that shouldn't be added with 0's.
//This is tricky since the var nums aren't sequential. 1-3,41-49,410-447
local var_num = 1
forval i=1/15{
	if `i' <= 3{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i559d`i' = 0 if p559d_`i'_flag!=1 | t559b_`i'_flag!=1 | p559c_`i'_flag!=1 | sum_flag == 0 
		//Increment varnum by 1 if i is 1 or 2
		if `i' <= 2{
			local var_num = `var_num'+1
		}
		//Set varnum to 41 is i is 3
		if `i' == 3{
			local var_num = 41
		}
	}
	//After 3, i559 vals skip to 41
	if `i' >= 4 & `i'<=12{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i559d`var_num' = 0 if p559d_`i'_flag!=1 | t559b_`i'_flag!=1 | p559c_`i'_flag!=1 | sum_flag == 0 
		//Increment varnum by 1 if i is less than 12
		if `i' <= 11{
			local var_num = `var_num'+1
		}
		//Set varnum to 410 is i is 12
		if `i' == 12{
			local var_num = 410
		}
	}
	//After 49, i559 vals skip to 410
	if `i' >= 13{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i559d`var_num' = 0 if p559d_`i'_flag!=1 | t559b_`i'_flag!=1 | p559c_`i'_flag!=1 | sum_flag == 0 
		//Increment varnum by 1
		local var_num = `var_num'+1
	}
}

//Sum all the i559d vars
gen i_sum = 0
local var_num = 1
forval i=1/15{
	if `i' <= 3{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i_sum = i_sum + i559d`var_num'
		//Increment varnum by 1 if i is 1 or 2
		if `i' <= 2{
			local var_num = `var_num'+1
		}
		//Set varnum to 41 is i is 3
		if `i' == 3{
			local var_num = 41
		}
	}
	//After 3, i559 vals skip to 41
	if `i' >= 4 & `i'<=12{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i_sum = i_sum + i559d`var_num'
		//Increment varnum by 1 if i is less than 12
		if `i' <= 11{
			local var_num = `var_num'+1
		}
		//Set varnum to 410 is i is 12
		if `i' == 12{
			local var_num = 410
		}
	}
	//After 49, i559 vals skip to 410
	if `i' >= 13{
		//If p559d, or t559b, or p559c flag is not 1 replace value in i559di with 0
		replace i_sum = i_sum + i559d`var_num'
		//Increment varnum by 1
		local var_num = `var_num'+1
	}
}

//Rename i_sum to one_sum since this is only tradable stuff
rename i_sum one_sum_05

//Collapse i_sum to get a value for each household
collapse (sum) one_sum_05, by(conglome vivienda hogar)


//Keep only relevant vars
keep conglome vivienda hogar one_sum_05 

//Save in a temp file to be retrieved later
save Trash/temp_g05hd7,replace

************************************Module 601**********************************

use "$ccc_in/module 601/enaho01-2017-601.dta", clear

//Rename vars
rename p601a good_type
rename i601c consump

//Drop rows of good types 44,46,47,49,50
drop if regexm(good_type,"^44") | regexm(good_type,"^47") | regexm(good_type,"^49") | regexm(good_type,"^50")

//Drop products in 46 and 48 that start with an 8 in produc61
tostring produc61 , gen(produc61str)
drop if regexm(good_type,"^46") & regexm(produc61str,"^8")
drop if regexm(good_type,"^48") & regexm(produc61str,"^8")

//Drop the category summary rows e.g dairy because these rows don't have detail on each purchase
drop if produc61==0  

//Destring good type var for easier checking later
destring(good_type),replace

//Turn missing vals and vals that shouldn't be summed into 0's
replace consump = 0 if p601c == . | p601c < 0 | p601a1 != 1 | consump == . 

gen one_sum_601 = 0
gen two_sum_601 = 0
replace one_sum_601 = consump if good_type < 4400 | (good_type >= 4500 & good_type < 4600)
replace two_sum_601 = consump if (good_type >= 4600 & good_type < 4700)| (good_type >= 4800 & good_type < 4900)

//Collapse and sum  i604b
collapse (sum) one_sum_601 two_sum_601 , by(conglome vivienda hogar)

//Merge with Sumaria data and collapsed 601 data
merge 1:1 conglome vivienda hogar using "Trash/temp_g05hd7.dta", nogen

//Add up one sums
gen one_sum = one_sum_601 + one_sum_05
gen two_sum = two_sum_601

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd

gen tot_sum = one_sum + two_sum + three_sum

gen diff_gru11hd = curr_sum - tot_sum

sum diff_gru11hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace


************************************Module 607 & 3******************************
*GRU31HD
use "$ccc_in/module 607/enaho01-2017-607.dta", clear

//Turn all missing vals/negative vals into 0's
replace i607b = 0 if i607b < 0 | i607b == . | p607a1 != 1

////Add category var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen category = 1 if p607n <= 5
replace category = 2 if p607n >= 6

gen one_sum_607 = i607b if category == 1
gen two_sum = i607b if category == 2

collapse (sum) one_sum_607 two_sum, by (conglome vivienda hogar )

save Trash/tmp_607.dta,replace


//Load module 03 data
use "$ccc_in/module 03/2017/2017.dta", clear

replace i311b_1 = 0 if i311b_1 == . | i311b_1 < 0 | p204 == 2
replace i311b_2 = 0 if i311b_2 == . | i311b_2 < 0 | p204 == 2

//Collapse and sum expenditures
gen one_sum_03 = i311b_1 + i311b_2

collapse (sum) one_sum_03, by(conglome vivienda hogar )

//Merge with collapsed 607 data
merge 1:1 conglome vivienda hogar using "Trash/tmp_607.dta", nogen

//Add up one sums
gen one_sum = one_sum_03 + one_sum_607

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd

gen tot_sum = one_sum + two_sum + three_sum

gen diff_gru31hd = curr_sum - tot_sum

sum diff_gru31hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace


************************************Module 1,603,605,611*************************
*GRU41HD

//Load module 01 data
use "$ccc_in/module 01/2017/2017.dta", clear

//Calculate I1172 sum
gen one_sum_100 = 0
//Loop through i1172_1,2,4-10 (3 doesn't exist)
forval i=1/9{
	if `i'<=8{
		//These if statements just skip over i1172_03 which doesn't exist
		if `i' <=2{
			replace i1172_0`i' = 0 if i1172_0`i' == . | i1172_0`i' < 0 | p1175_0`i' != 0
			replace one_sum_100 = one_sum_100 + i1172_0`i'
		}
		if `i' >=3{
			local var_num = `i'+1
			replace i1172_0`var_num' = 0 if i1172_0`var_num' == . | i1172_0`var_num' < 0 | p1175_0`var_num' != 0
			replace one_sum_100 = one_sum_100 + i1172_0`var_num'
		}
	}
	if `i'==9{
		local var_num = `i'+1
		replace i1172_`var_num' = 0 if i1172_`var_num' == . | i1172_`var_num' < 0 | p1175_`var_num' != 0
		replace one_sum_100 = one_sum_100 + i1172_`var_num'
	}
}

//Grab i1172_15
gen four_sum_100 = 0
replace i1172_15 = 0 if i1172_15 == . | i1172_15 < 0 | p1175_15 != 0
replace four_sum_100 = four_sum_100 + i1172_15

//Collapse i_sum
collapse (sum) one_sum_100 four_sum_100, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_100_sum.dta, replace

//Load module 603 data
use "$ccc_in/module 603/enaho01-2017-603.dta", clear

//Keep only relevant data
keep if p603n == 14
//Add all vars which should be used
gen one_sum_603 = 0
replace one_sum_603 = i603b if p603a1 == 1 & i603b > 0 & i603b != . 

//Collapse
collapse (sum) one_sum_603,by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_603_sum.dta, replace

//Load 611 Data
use "$ccc_in/module 611/enaho01-2017-611.dta", clear

//Keep only pertinent data
keep if p611n == 5
//Add all vars which should be used
gen two_sum_611 = 0
replace two_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . 

//Collapse
collapse (sum) two_sum_611, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_611_sum.dta, replace

//Load in module 605 data
use "$ccc_in/module 605/enaho01-2017-605.dta", clear

//Keep only pertinent data
keep if p605n == 5 | p605n == 6
//Add all vars which should be used
gen two_sum_605 = 0
replace two_sum_605 = i605b if p605a1 == 1 & i605b > 0 & i605b != . 

//Collapse
collapse (sum) two_sum_605, by(conglome vivienda hogar )

//Merge with module 1,603,and 611 data
merge 1:1 conglome vivienda hogar using "Trash/tmp_100_sum.dta", nogen
merge 1:1 conglome vivienda hogar using "Trash/tmp_603_sum.dta", nogen
merge 1:1 conglome vivienda hogar using "Trash/tmp_611_sum.dta", nogen

//Also merge with sumaria data to also get ga03hd, an entirely durable category
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

//Add up for each category
gen one_sum = one_sum_100 + one_sum_603
gen two_sum = two_sum_605 + two_sum_611 
gen three_sum = ga03hd
gen four_sum = four_sum_100

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum three_sum four_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru41hd = curr_sum - tot_sum

sum diff_gru41hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace


************************************Module 605**********************************
*GRU41HD1

//Load in module 605 data
use "$ccc_in/module 605/enaho01-2017-605.dta", clear

//Keep only pertinent data
keep if p605n == 2 | p605n == 4 | p605n == 7 | p605n == 8
//Add all vars which should be used
gen two_sum = 0
replace two_sum = i605b if p605a1 == 1 & i605b > 0 & i605b != . & p605n != 8
gen four_sum = 0
replace four_sum = i605b if p605a1 == 1 & i605b > 0 & i605b != . & p605n == 8

//Collapse
collapse (sum) two_sum four_sum,by(conglome vivienda hogar)

//Keep only relevant variables
keep conglome vivienda hogar two_sum four_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru41hd = curr_sum - tot_sum

sum diff_gru41hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace


************************************Modules 603,605,610*************************
*GRU51HD

//Load module 603 data
use "$ccc_in/module 603/enaho01-2017-603.dta", clear

//Keep only relevant data
keep if p603n != 14

//Add all vars which should be used
gen one_sum_603 = 0
replace one_sum_603 = i603b if p603a1 == 1 & i603b > 0 & i603b != . & p603n != 5 & p603n != 13  
gen two_sum_603 = 0
replace two_sum_603 = i603b if p603a1 == 1 & i603b > 0 & i603b != . & p603n == 13  
gen four_sum_603 = 0
replace four_sum_603 = i603b if p603a1 == 1 & i603b > 0 & i603b != . & p603n == 5 

//Collapse
collapse (sum) one_sum_603 two_sum_603 four_sum_603,by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_603_sum.dta, replace

//Load in module 605 data
use "$ccc_in/module 605/enaho01-2017-605.dta", clear

//Keep only pertinent data
keep if p605n == 3
//Add all vars which should be used
gen two_sum_605 = 0
replace two_sum_605 = i605b if p605a1 == 1 & i605b > 0 & i605b != . 

//Collapse
collapse (sum) two_sum_605,by(conglome vivienda hogar)

//Save in a temp file
save Trash/tmp_605_sum.dta, replace

//Load in module 610 data
use "$ccc_in/module 610/enaho01-2017-610.dta", clear

//Keep only pertinent data
keep if p610n == 1 | p610n == 3 | p610n == 4 | p610n == 5 | p610n == 6
//Add all vars which should be used
gen one_sum_610 = 0
replace one_sum_610 = i610b if p610a1 == 1 & i610b > 0 & i610b != . & (p610n == 3 | p610n == 4)
gen two_sum_610 = 0
replace two_sum_610 = i610b if p610a1 == 1 & i610b > 0 & i610b != . & (p610n == 1)
gen three_sum_610 = 0
replace three_sum_610 = i610b if p610a1 == 1 & i610b > 0 & i610b != . & (p610n == 5)
gen four_sum_610 = 0
replace four_sum_610 = i610b if p610a1 == 1 & i610b > 0 & i610b != . & (p610n == 6)

//Collapse
collapse (sum) one_sum_610 two_sum_610 three_sum_610 four_sum_610, by(conglome vivienda hogar )

//Merge
merge 1:1 conglome vivienda hogar using "Trash/tmp_603_sum.dta", nogen
merge 1:1 conglome vivienda hogar using "Trash/tmp_605_sum.dta", nogen


//Add up for each category
gen one_sum = one_sum_603 + one_sum_610
gen two_sum = two_sum_603 + two_sum_605 + two_sum_610
gen three_sum = three_sum_610
gen four_sum = four_sum_603 + four_sum_610

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum three_sum four_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1 + gru51hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru51hd = curr_sum - tot_sum

sum diff_gru51hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace

************************************Modules 604,605*****************************
*GRU71HD

//Load in module 604 data
use "$ccc_in/module 634/enaho01-2017-634.dta", clear

//Keep only pertinent data
keep if p604n <=5 | (p604n >= 7 & p604n <= 9)

//Add all vars which should be used
gen one_sum_604 = 0
replace one_sum_604 = i604b if p604a1 == 1 & i604b > 0 & i604b != . & (p604n == 1 | p604n == 2)
gen two_sum_604 = 0
replace two_sum_604 = i604b if p604a1 == 1 & i604b > 0 & i604b != . & p604n != 1 & p604n != 2 & p604n != 9
gen four_sum_604 = 0
replace four_sum_604 = i604b if p604a1 == 1 & i604b > 0 & i604b != . & (p604n == 9) 

//Collapse
collapse (sum) one_sum_604 two_sum_604 four_sum_604, by(conglome vivienda hogar)

//Save in temp file
save Trash/tmp_604_sum.dta, replace

//Load in module 605 data
use "$ccc_in/module 605/enaho01-2017-605.dta", clear

//Keep only pertinent data
keep if p605n == 1

//Add all vars which should be used
gen two_sum_605 = 0
replace two_sum_605 = i605b if p605a1 == 1 & i605b > 0 & i605b != . 

//Collapse
collapse (sum) two_sum_605, by(conglome vivienda hogar)

//Merge with temp data
merge 1:1 conglome vivienda hogar using "Trash/tmp_604_sum.dta", nogen

//Add up for each category
gen one_sum = one_sum_604
gen two_sum = two_sum_604 + two_sum_605
gen four_sum = four_sum_604

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum four_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1 + gru51hd + gru71hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru71hd = curr_sum - tot_sum

sum diff_gru71hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace

************************************Modules 1,3,604*****************************
*GRU81HD

//Load module 01 data
use "$ccc_in/module 01/2017/2017.dta", clear

//Calculate I1172 sum
gen two_sum_100 = 0
//Loop through i1172_11-14
forval i=11/14{
	replace i1172_`i' = 0 if i1172_`i' == . | i1172_`i' < 0 | p1175_`i' != 0 | p1171_`i' != 1
	replace two_sum_100 = two_sum_100 + i1172_`i'
}

//Collapse i_sum
collapse (sum) two_sum_100, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_100_sum.dta, replace

//Load module 03 data
use "$ccc_in/module 03/2017/2017.dta", clear

//Keep important data
gen two_sum_300 = 0
replace two_sum_300 = i315a if i315a != . & i315a > 0 & p204 == 1 & p3151 == 1

//Collapse data
collapse (sum) two_sum_300, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_03_sum.dta, replace

//Load in module 604 data
use "$ccc_in/module 634/enaho01-2017-634.dta", clear

//Keep only pertinent data
keep if p604n >=10 & p604n <= 13

//Add all vars which should be used
gen two_sum_604 = 0
replace two_sum_604 = i604b if p604a1 == 1 & i604b > 0 & i604b != . & p604n != 13
gen three_sum_604 = 0
replace three_sum_604 = i604b if p604a1 == 1 & i604b > 0 & i604b != . & p604n == 13

//Collapse
collapse (sum) two_sum_604 three_sum_604, by(conglome vivienda hogar )

//Merge with temp data
merge 1:1 conglome vivienda hogar using "Trash/tmp_100_sum.dta", nogen
merge 1:1 conglome vivienda hogar using "Trash/tmp_03_sum.dta", nogen

//Add up for each category
gen two_sum = two_sum_100 + two_sum_300 + two_sum_604
gen three_sum = three_sum_604

//Keep only relevant variables
keep conglome vivienda hogar two_sum three_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1 + gru51hd + gru71hd + gru81hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru71hd = curr_sum - tot_sum

sum diff_gru71hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace

************************************Module 03,606,611***************************
*GRU91HD

//Load module 03 data
use "$ccc_in/module 03/2017/2017.dta", clear

//Keep important data
gen one_sum_03 = 0
replace one_sum_03 = i311b_3 if i311b_3 != . & i311b_3 > 0 & p204 == 1 & p311a1_3 == 1
replace one_sum_03 = one_sum_03 + i311b_4 if i311b_4 != . & i311b_4 > 0 & p204 == 1 & p311a1_4 == 1

//Collapse data
collapse (sum) one_sum_03, by(conglome vivienda hogar )

//Save in temp file
save Trash/tmp_03_sum.dta, replace

//Load module 606 data
use "$ccc_in/module 606/enaho01-2017-606.dta", clear

//Add all vars which should be used
gen one_sum_606 = 0
replace one_sum_606 = i606b if p606a1 == 1 & i606b > 0 & i606b != . & (p606n == 1 | p606n == 5 | p606n == 6 | p606n == 7)
gen two_sum_606 = 0
replace two_sum_606 = i606b if p606a1 == 1 & i606b > 0 & i606b != . & (p606n == 3 | p606n == 4)
gen four_sum_606 = 0
replace four_sum_606 = i606b if p606a1 == 1 & i606b > 0 & i606b != . & (p606n == 2 | p606n == 8)

//Collapse data
collapse (sum) one_sum_606 two_sum_606 four_sum_606, by(conglome vivienda hogar )

//Save in temp file
save Trash/tmp_606_sum.dta, replace

//Load module 611 data
use "$ccc_in/module 611/enaho01-2017-611.dta", clear

//Keep only pertinent data
keep if p611n == 4

//Change vars not used to 0's
gen two_sum_611 = 0
replace two_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . 

//Collapse
collapse (sum) two_sum_611, by(conglome vivienda hogar)

//Merge with temp data
merge 1:1 conglome vivienda hogar using "Trash/tmp_03_sum.dta", nogen
merge 1:1 conglome vivienda hogar using "Trash/tmp_606_sum.dta", nogen

//Add up for each category
gen one_sum = one_sum_606 + one_sum_03
gen two_sum = two_sum_606 + two_sum_611
gen four_sum = four_sum_606

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum four_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru41hd1 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1 + gru51hd + gru71hd + gru81hd + gru91hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen diff_gru71hd = curr_sum - tot_sum

sum diff_gru71hd

keep conglome vivienda hogar diff* 

*Save in check file check data
save Trash/check,replace

************************************Module 606,611******************************
*GRU121HD

//Load module 606 data
use "$ccc_in/module 606d/enaho01-2017-606d.dta", clear

//Add correct vars
gen one_sum_606d = 0
replace one_sum_606d = i606f if p606e1 == 1 & i606f > 0 & i606f != . & p606n <= 9
gen two_sum_606d = 0
replace two_sum_606d = i606f if p606e1 == 1 & i606f > 0 & i606f != . & p606n > 9

//Collapse data
collapse (sum) one_sum_606d two_sum_606d, by(conglome vivienda hogar )

//Save in temp file
save Trash/tmp_606d_sum.dta, replace

//Load module 611 data
use "$ccc_in/module 611/enaho01-2017-611.dta", clear

//Keep only pertinent data
keep if t611n <= 3 | t611n == 6 | t611n == 7 | t611n == 9 | t611n == 13 

//Change vars not used to 0's
gen one_sum_611 = 0
replace one_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 1 | t611n == 6 | t611n == 11 | t611n == 13)
gen two_sum_611 = 0
replace two_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 2 | t611n == 3 | t611n == 7)
gen four_sum_611 = 0
replace four_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 9)

//Collapse
collapse (sum) one_sum_611 two_sum_611 four_sum_611, by(conglome vivienda hogar )

//Merge with temp data
merge 1:1 conglome vivienda hogar using "Trash/tmp_606d_sum.dta", nogen

//Add up for each category
gen one_sum = one_sum_606 + one_sum_611
gen two_sum = two_sum_606 + two_sum_611
gen four_sum = four_sum_611

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum four_sum   

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
//Load in temp sums
use "Trash/temp_sums.dta", clear

collapse (sum) one_sum two_sum three_sum four_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria/2017/sumaria-2017-12.dta", nogen

gen curr_sum = gru21hd + gru21hd1 + gru91hd3 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23 + sg25 + g07hd1 + g07hd2 + gru51hd1 +  gru61hd + gru71hd1 + gru71hd2 + gru91hd1 +  gru101hd + gru111hd + gru111hd1 + gru121hd2 + gru111hd2 + gru121hd3 + sg42 + sg422 + sg421 + gru11hd + gru31hd + gru41hd + gru41hd1 + gru51hd + gru71hd + gru81hd + gru121hd + gru91hd

gen tot_sum = one_sum + two_sum + three_sum + four_sum

gen final_diff_agg = gashog1d - tot_sum

sum final_diff_agg

keep conglome vivienda hogar one_sum two_sum three_sum four_sum tot_sum curr_sum gashog1d final* factor07

*Calculate consumption shares
gen wt_sum_one = factor07*one_sum
gen wt_sum_two = factor07*two_sum
gen wt_sum_three = factor07*three_sum
gen wt_sum_four = factor07*four_sum

gen wt_sum_gashod = factor07*gashog1d

gen diff = wt_sum_gashod - wt_sum_one - wt_sum_two - wt_sum_three - wt_sum_four 
sum diff

egen sum_one = sum(wt_sum_one)
egen sum_two = sum(wt_sum_two)
egen sum_three = sum(wt_sum_three)
egen sum_four = sum(wt_sum_four)

egen sum_gashog = sum(wt_sum_gashod)

mat sums = [sum_one[1]/sum_gashog[1],sum_two[1]/sum_gashog[1],sum_three[1]/sum_gashog[1],sum_four[1]/sum_gashog[1]]

mat list sums

svmat sums

save Trash/final_2017_sums, replace