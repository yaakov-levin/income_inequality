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


************************************Module 605**********************************
use "$ccc_in/module 05/2018/2018.dta", clear

*G07HD1
//Note this flag isn't just used for G07HD1
gen sum_flag = 0
replace sum_flag = 1 if p204==1 & (p203!=8 & p203!=9) & p208a>=14

//Add all vals which should be used
gen g07hd1_sum = 0
forval i=1/7{
	replace g07hd1_sum = g07hd1_sum + i560d`i' if p560c_0`i' == 1 & sum_flag == 1 & i560d`i'!=.
}

*G07HD2
//Add all vals which should be used
gen g07hd2_sum = 0
forval i=8/10{
	if `i'<=9{
		replace g07hd2_sum = g07hd2_sum + i560d`i' if p560c_0`i' == 1 & sum_flag == 1 & i560d`i'!=.
	}
	if `i'==10{
		replace g07hd2_sum = g07hd2_sum + i560d`i' if p560c_`i' == 1 & sum_flag == 1 & i560d`i'!=.
	}
}

//Collapse to get single val for each household
collapse (sum) g07hd1_sum g07hd2_sum,by(conglome vivienda hogar )


*Keep pertinent vals and save to see if this worked
keep conglome vivienda hogar g07hd1_sum g07hd2_sum 

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen two_sum = g07hd1_sum + g07hd2_sum

*Save in file
save Trash/temp_sums, replace

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_g07hd = g07hd1 + g07hd2 - two_sum

keep conglome vivienda hogar diff_g07hd

*Save in file
save Trash/check, replace

************************************Module 602**********************************
use "$ccc_in/module 602/2018_602.dta", clear

*SG23
//Add all vars which should be used
gen sg23_sum = 0
replace sg23_sum = i602e1 if p602da == 1 & i602e1 > 0 
replace sg23_sum = sg23_sum + i602e2 if p602db == 2 & i602e2 > 0  

collapse (sum) sg23_sum,by(conglome vivienda hogar)

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen two_sum = sg23_sum

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_sg23 = sg23 - two_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Module 602a**********************************
use "$ccc_in/module 602/2018_602_a.dta", clear

*TODO check with Fernando on conglome =="005616"&vivienda =="002"&hogar =="11". Looks like survey was wrong.
*SG25
//Add all vars which should be used
gen sg25_sum = 0
replace sg25_sum = i602e3 if p602d1a == 1 & i602e3 > 0 & i602e3 != . 
replace sg25_sum = sg25_sum + i602e4 if p602d1b == 2 & i602e4 > 0 & i602e4 != .

//Collapse
collapse (sum) sg25_sum,by(conglome vivienda hogar)

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen two_sum = sg25_sum

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_sg25 = sg25 - two_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace



************************************Module 601**********************************
//Commented out because slow

use "$ccc_in/module 601/2018.dta", clear

*GRU111HD

//Drop obs that aren't used
keep if regexm(p601a,"^47") | regexm(p601a,"^50")
keep if produc61 != 0

//Add all vars which should be used
gen gru111hd_sum = 0
replace gru111hd_sum = i601c if p601a1 == 1 & i601c > 0 & i601c != . 

//Collapse
collapse (sum) gru111hd_sum,by(conglome vivienda hogar )

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen two_sum = gru111hd_sum

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru111hd = gru111hd - two_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


*GRU21HD
use "$ccc_in/module 601/2018.dta", clear

keep if regexm(p601a,"^44")
keep if produc61 != 0

//Add all vars which should be used
gen gru21hd_sum = 0
replace gru21hd_sum = i601c if p601a1 == 1 & i601c > 0 & i601c != . 

//Collapse
collapse (sum) gru21hd_sum,by(conglome vivienda hogar )

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen five_sum = gru21hd_sum

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore 

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru21hd = gru21hd - five_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace



************************************Module 611**********************************
*GRU21HD1
use "$ccc_in/module 611/2018.dta", clear

//Keep only pertinent data
keep if p611n == 11
//Add all vars which should be used
gen gru21hd1_sum = 0
replace gru21hd1_sum = i611b if p611a1 == 1 & i611b > 0 & i611b != . 

//Collapse
collapse (sum) gru21hd1_sum,by(conglome vivienda hogar )

//Add category sum var (1:T,2:NT,3:D,4:NC,5:T-vices)
gen five_sum = gru21hd1_sum

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore


//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru21hd1 = gru21hd1 - five_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Module 607 & 3******************************
*GRU31HD
use "$ccc_in/module 607/2018.dta", clear

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
use "$ccc_in/module 03/2018/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru31hd = gru31hd - two_sum - one_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Module 1,603,605,611*************************
*GRU41HD

//Load module 01 data
use "$ccc_in/module 01/2018/2018.dta", clear

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

//Loop through i1172_15,16
gen four_sum_100 = 0
forval i=15/16{
	if `i' == 15{
		replace i1172_`i' = 0 if i1172_`i' == . | i1172_`i' < 0 | p1175_`i' != 0
		replace four_sum_100 = four_sum_100 + i1172_`i'
	}
	if `i' == 16{
		replace i1172_`i' = 0 if i1172_`i' == . | i1172_`i' < 0 | p1175_`i' != 0
		replace one_sum_100 = one_sum_100 + i1172_`i'
	}
}


//Collapse i_sum
collapse (sum) one_sum_100 four_sum_100, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_100_sum.dta, replace

//Load module 603 data
use "$ccc_in/module 603/2018.dta", clear

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
use "$ccc_in/module 611/2018.dta", clear

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
use "$ccc_in/module 605/2018.dta", clear

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

//Add up for each category
gen one_sum = one_sum_100 + one_sum_603
gen two_sum = two_sum_605 + two_sum_611 
gen four_sum = four_sum_100

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum four_sum 

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru41hd = gru41hd - two_sum - one_sum - ga03hd

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Module 605**********************************
*GRU41HD1

//Load in module 605 data
use "$ccc_in/module 605/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru41hd1 = gru41hd1 - two_sum -  four_sum 

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Modules 603,605,610*************************
*GRU51HD

//Load module 603 data
use "$ccc_in/module 603/2018.dta", clear

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
use "$ccc_in/module 605/2018.dta", clear

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
use "$ccc_in/module 610/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru51hd = gru51hd - two_sum - one_sum - three_sum - four_sum 

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


/*
Single component
************************************Module 610**********************************
*GRU51HD1

//Load in module 610 data
use "$ccc_in/module 610/2018.dta", clear

//Keep only pertinent data
keep if p610n == 2
//Add all vars which should be used
gen mod_610_sum = 0
replace mod_610_sum = i610b if p610a1 == 1 & i610b > 0 & i610b != . 

//Collapse
collapse (sum) mod_610_sum, by(conglome vivienda hogar)
*/

*Single component NT services
/*
************************************Module 400**********************************
*GRU61HD

//Load in module 400 data
use "$ccc_in/module 400/2018.dta", clear

//Merge with module 3 to get question p204
merge 1:1 conglome vivienda hogar codperso using "$ccc_in/module 03/2018/2018.dta", nogen

//Loop through the 16 measures and change data accordingly. Then add to sum var
gen gru61hd_sum = 0
forval i=1/16{
	if `i'<10{
		replace i4160`i' = 0 if p4151_0`i' != 1 | i4160`i' < 0 | i4160`i' == . | p204 == 2
		replace gru61hd_sum = gru61hd_sum + i4160`i'		
	}
	if `i'>=10{
		replace i416`i' = 0 if p4151_`i' != 1 | i416`i' < 0 | i416`i' == . | p204 == 2
		replace gru61hd_sum = gru61hd_sum + i416`i'
	}
} 
*/


************************************Modules 604,605*****************************
*GRU71HD

//Load in module 604 data
use "$ccc_in/module 634/2018.dta", clear

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
use "$ccc_in/module 605/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru71hd = gru71hd - two_sum - one_sum - four_sum 

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Modules 1,3,604*****************************
*GRU81HD

//Load module 01 data
use "$ccc_in/module 01/2018/2018.dta", clear

//Calculate I1172 sum
gen two_sum_100 = 0
gen four_sum_100 = 0
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
use "$ccc_in/module 03/2018/2018.dta", clear

//Keep important data
gen two_sum_300 = 0
replace two_sum_300 = i315a if i315a != . & i315a > 0 & p204 == 1 & p3151 == 1

//Collapse data
collapse (sum) two_sum_300, by(conglome vivienda hogar )

//Save in a temp file
save Trash/tmp_03_sum.dta, replace

//Load in module 604 data
use "$ccc_in/module 634/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru81hd = gru81hd - two_sum - three_sum 

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


/*
Single component NT
************************************Module 03***********************************
*GRU101HD

//Load module 03 data
use "$ccc_in/module 03/2018/2018.dta", clear

//Keep important data
gen summed_03 = 0
replace summed_03 = i311b_5 if i311b_5 != . & i311b_5 > 0 & p204 == 1 & p311a1_5 == 1
replace summed_03 = summed_03 + i311b_6 if i311b_6 != . & i311b_6 > 0 & p204 == 1 & p311a1_6 == 1
replace summed_03 = summed_03 + i3121b if i3121b != . & i3121b > 0 & p204 == 1 & p3121a1 == 1

//Collapse data
collapse (sum) summed_03, by(conglome vivienda hogar)
*/

************************************Module 03,606,611***************************
*GRU91HD

//Load module 03 data
use "$ccc_in/module 03/2018/2018.dta", clear

//Keep important data
gen one_sum_03 = 0
replace one_sum_03 = i311b_3 if i311b_3 != . & i311b_3 > 0 & p204 == 1 & p311a1_3 == 1
replace one_sum_03 = one_sum_03 + i311b_4 if i311b_4 != . & i311b_4 > 0 & p204 == 1 & p311a1_4 == 1

//Collapse data
collapse (sum) one_sum_03, by(conglome vivienda hogar )

//Save in temp file
save Trash/tmp_03_sum.dta, replace

//Load module 606 data
use "$ccc_in/module 606/2018.dta", clear

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
use "$ccc_in/module 611/2018.dta", clear

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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru91hd = gru91hd - two_sum - four_sum - one_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace

************************************Module 606,611******************************
*GRU121HD

//Load module 606 data
use "$ccc_in/module 606d/2018.dta", clear

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
use "$ccc_in/module 611/2018.dta", clear

//Keep only pertinent data
keep if t611n <= 3 | t611n == 6 | t611n == 7 | t611n == 9 | t611n == 13 

//Change vars not used to 0's
gen one_sum_611 = 0
replace one_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 1 | t611n == 6)
gen two_sum_611 = 0
replace two_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 2 | t611n == 3 | t611n == 7)
gen four_sum_611 = 0
replace four_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 9 | t611n == 13)
gen five_sum_611 = 0
replace five_sum_611 = i611b if p611a1 == 1 & i611b > 0 & i611b != . & (t611n == 11)

//Collapse
collapse (sum) one_sum_611 two_sum_611 four_sum_611 five_sum_611, by(conglome vivienda hogar )

//Merge with temp data
merge 1:1 conglome vivienda hogar using "Trash/tmp_606d_sum.dta", nogen

//Add up for each category
gen one_sum = one_sum_606 + one_sum_611
gen two_sum = two_sum_606 + two_sum_611
gen four_sum = four_sum_611
gen five_sum = five_sum_611

//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum four_sum five_sum  

preserve
*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums, replace
restore

//Automated check for correctness
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru121hd = gru121hd - two_sum - four_sum - one_sum - five_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace


************************************Module 605**********************************
use "$ccc_in/module 05/2018/2018.dta", clear

//Generate flag for p559d, t559b and p559c vars checking they should be summed or not
//I think need flag for all 50 vals
forval i=1/50{
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
forval i=1/50{
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
forval i=1/50{
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
*GRU11HD
use "$ccc_in/module 601/2018.dta", clear

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
gen one_sum = one_sum_05 + one_sum_601
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
*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

gen diff_gru11hd = gru11hd - two_sum - one_sum

keep conglome vivienda hogar diff* 

*Merge with rest of check data
merge 1:1 conglome vivienda hogar using "Trash/check.dta", nogen

*Save in file
save Trash/check, replace





************************************Module 612**********************************
*SG42
//Not working but might just be moot point anyhow
/*
use "$ccc_in/module 612/2018.dta", clear

//Keep only pertinent data
keep if p612n <= 7
//Add all vars which should be used
gen sg42_sum = 0
replace sg42_sum = i612g if p612a == 1 & i612g > 0 & i612g != . & p612 == 1 & p612b == 1

//Collapse
collapse (sum) sg42_sum,by(conglome vivienda hogar)

*Merge 
merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta", nogen

keep conglome vivienda hogar sg42_sum sg42
gen diff = sg42  - sg42_sum
sum diff
*/ 


/*Code to add sumaria vars that fit into single categories
SINGLE COMPONENTS (Need to be summed): GRU71HD1 (NT) , GRU71HD2 (NT), GRU91HD1 (NT) , GRU111HD1 (NT), GRU121HD3 (NT), GRU121HD4 (NC), GRU91HD3 (T), (NT)GRU121HD2, GRU41HD1(NT), GRU101HD (NT)
GRU51HD1 (NT),  (ALL NT) G05HD + G05HD1 + G05HD2 + G05HD3 + G05HD4 + G05HD5 + G05HD6, GRU111HD2 (NT),  GRU61HD (NT) GRU91HD1 (NT)
*/
use "$ccc_in/sumaria-2018-12g.dta", clear
gen one_sum = gru91hd3  
gen two_sum = gru71hd1 + gru71hd2 + gru91hd1 + gru111hd1 + gru121hd3 + gru121hd2 + gru101hd + gru51hd1 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + gru111hd2 + gru61hd  
gen three_sum = sg42 + sg422 + ga03hd + sg421 


//Keep only relevant variables
keep conglome vivienda hogar one_sum two_sum three_sum  

*Append 
append using "Trash/temp_sums.dta"

*Save
save Trash/temp_sums,replace


//Finally check everything
use "Trash/temp_sums.dta", clear

preserve
collapse (sum) one_sum two_sum three_sum four_sum five_sum,by(conglome vivienda hogar)

merge 1:1 conglome vivienda hogar using "$ccc_in/sumaria-2018-12g.dta"
keep if _merge == 3

gen basic_sum = gru91hd3 + sg421 + gru71hd1 + gru71hd2 + gru91hd1 + gru111hd1 + gru121hd3 + gru121hd2 + gru41hd1 + gru101hd + gru51hd1 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + gru111hd2 + gru61hd + sg42 + sg422 + gru121hd4 + g07hd1 +g07hd2 + sg23 + sg25 + gru111hd + gru21hd + gru21hd1 + gru31hd + gru41hd + gru51hd + gru71hd + gru81hd +gru91hd + gru121hd + gru11hd

gen new_sum =  g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + g07hd1 + g07hd2 + sg23 + sg25 + gru11hd + gru111hd + gru111hd2 + gru21hd + gru21hd1 + gru31hd + gru41hd + gru41hd1 + gru51hd + gru51hd1 + gru61hd + gru71hd + gru71hd1 + gru71hd2 + gru81hd + gru91hd + gru91hd1 + gru101hd + gru111hd1 + gru121hd + gru121hd2 + gru121hd3 + sg42 + sg421 + sg422 + gru91hd3


/*equiv to:
Want:  GASHOG1D =
G05HD + G05HD1 + G05HD2 + G05HD3 + G05HD4 + G05HD5 + G05HD6 + G07HD1 + 
G07HD2 + SG23 + SG25 + GRU11HD + GRU111HD + GRU111HD2 + GRU21HD + 
GRU21HD1 + GRU31HD + GRU41HD + GRU41HD1 + GRU51HD + GRU51HD1 + 
GRU61HD + GRU71HD + GRU71HD1 + GRU71HD2 + GRU81HD + GRU91HD + 
GRU91HD1 + GRU101HD + GRU111HD1 + GRU121HD + GRU121HD2 + GRU121HD3 +
GRU121HD4 + GRU91HD3 + SG42 + SG421 + SG422
*/


gen tot_sum = one_sum + two_sum + three_sum +four_sum + five_sum

gen diff = gashog1d - tot_sum

sum diff 


//Drop hhold with mistake in sg25
drop if conglome =="005616"&vivienda =="002"&hogar =="11"

sum diff 

keep conglome vivienda hogar one_sum two_sum three_sum four_sum five_sum tot_sum gashog1d factor07

gen wt_sum_one = factor07*one_sum
gen wt_sum_two = factor07*two_sum
gen wt_sum_three = factor07*three_sum
gen wt_sum_four = factor07*four_sum
gen wt_sum_five = factor07*five_sum

gen wt_sum_gashod = factor07*gashog1d

gen diff = wt_sum_gashod - wt_sum_one - wt_sum_two - wt_sum_three - wt_sum_four - wt_sum_five
sum diff

egen sum_one = sum(wt_sum_one)
egen sum_two = sum(wt_sum_two)
egen sum_three = sum(wt_sum_three)
egen sum_four = sum(wt_sum_four)
egen sum_five = sum(wt_sum_five)

egen sum_gashog = sum(wt_sum_gashod)

mat sums = [(sum_one[1]+sum_five[1])/sum_gashog[1],sum_two[1]/sum_gashog[1],sum_three[1]/sum_gashog[1],sum_four[1]/sum_gashog[1]]

mat list sums

save Trash/final_2018_sums, replace

/*
gen calc_sum = gru71hd1 + gru71hd2 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23+sg25+gru11hd+gru111hd+gru111hd2+gru21hd+gru21hd1+gru31hd+gru41hd+gru41hd1+gru51hd+gru51hd1+gru61hd+gru71hd+gru71hd1+gru71hd2+gru81hd+gru91hd+gru91hd1+gru101hd+gru111hd1+gru121hd+gru121hd2+gru121hd3+gru121hd4+gru91hd3+sg42+sg421+sg422

gen basic_sum = gru91hd3 + sg421 + gru71hd1 + gru71hd2 + gru91hd1 + gru111hd1 + gru121hd3 + gru121hd2 + gru41hd1 + gru101hd + gru51hd1 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + gru111hd2 + gru61hd + gru91hd + sg42 + sg422 + gru121hd4

Things I feel good about
GRU71HD1 (NT) , GRU71HD2 (NT), GRU91HD1 (NT) , GRU111HD1 (NT), GRU121HD3 (NT), GRU121HD4 (NC), GRU91HD3 (T), (NT)GRU121HD2, GRU41HD1(NT), GRU101HD (NT)
GRU51HD1 (NT),  (ALL NT) G05HD + G05HD1 + G05HD2 + G05HD3 + G05HD4 + G05HD5 + G05HD6, GRU111HD2 (NT),  GRU61HD (NT) GRU91HD1 (NT)

Diff: sg23+sg25+gru11hd+gru111hd+gru111hd2+gru21hd+gru21hd1+gru31hd+gru41hd+gru41hd1+gru51hd+gru51hd1+gru61hd+gru71hd+gru71hd1+gru71hd2+gru81hd+gru91hd+gru91hd1+gru101hd+gru111hd1+gru121hd+gru121hd2+gru121hd3+gru121hd4+gru91hd3+sg42+sg421+sg422

merge 1:1 conglome vivienda hogar using "C:\Users\g1ysl01\Documents\Arce_consumption\Peruvian Data\Raw_Data\sumaria-2018-12g.dta", nogen


gen calc_sum = gru71hd1 + gru71hd2 + g05hd + g05hd1 + g05hd2 +g05hd3 + g05hd4 + g05hd5 + g05hd6 + sg23+sg25+gru111hd+gru111hd2+gru21hd+gru21hd1+gru31hd+gru41hd+gru41hd1+gru51hd+gru51hd1+gru61hd+gru71hd+gru71hd1+gru71hd2+gru81hd+gru91hd+gru91hd1+gru101hd+gru111hd1+gru121hd+gru121hd2+gru121hd3+gru121hd4+gru91hd3+sg42+sg421+sg422



