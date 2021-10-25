log using italy_reg_results,replace

use "C:\Users\g1ysl01\Documents\Arce_consumption\italy.dta" 

rename anno year
rename eta age
rename ncomp hhold_size
rename sesso gender
rename ireg region 

gen age_sqr = age^2
gen hhold_size_sqr = hhold_size^2
gen ln_inc = ln(income)
gen ln_consump = ln(consump)

reg ln_inc age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year 
predict resid_inc, residuals
gen resid_income_actual = e^(resid_inc)

reg ln_consump age age_sqr i.gender i.educ hhold_size hhold_size_sqr i.region i.educ#year i.gender#year year 
predict resid_consump, residuals
gen resid_consump_actual = e^(resid_consump)

save "C:\Users\g1ysl01\Documents\Arce_consumption\italy_final.dta",replace
