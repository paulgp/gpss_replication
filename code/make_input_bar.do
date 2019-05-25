* Create Input file to Used Rotemberg Weights ado

set more off
clear all
set matsize 10000

global home "../data"

*these locals shouldn't change unless you want spec to change
local controls = "male race_white native_born educ_hs educ_coll veteran nchild"
local controls_1980 = "male_1980 race_white_1980 native_born_1980 educ_hs_1980 educ_coll_1980 veteran_1980 nchild_1980"

*create national industry share
*create 1980 population to weight the mean
use "${home}/raw/Characteristics_CZone", clear							
collapse (sum) pop1980=perwt_cz_lf if year==1980, by(czone)
egen tot_pop = total(pop1980)
replace pop1980 = pop1980 / tot_pop
drop tot_pop
tempfile czone_pop
save `czone_pop'

*cleaning controls file
use "${home}/raw/Characteristics_CZone", clear	
gen emp_ch = ((F.perwt_cz_ft - perwt_cz_ft)/perwt_cz_ft)/10								
label var emp_ch "$\Delta$ Emp"
gen wage_ch = ((F.incwage_lf - incwage_lf)/incwage_lf)/10								
label var wage_ch "$\Delta$ Wage"

drop *_all *_lf employed_ft incwage_ft
ren *_ft *
	
*standardize controls ONLY
foreach var of varlist `controls' {
	qui summ `var'					 			//Store variance
	replace `var' = `var'/r(sd)						//Standardize to have variance 1
	}

*create 1980 version to use in model 
foreach var of varlist `controls' {
	bys czone (year): gen `var'_1980 = `var'[1] if year[1]==1980
	label var `var'_1980 `"`: var label `var''"'
	}


*manually create interaction terms
local controls_1980_full "" 
forval t = 1990(10)2000 {
	foreach var of varlist `controls_1980' {
		gen `var'_`t' = `var' * (year == `t')
		local controls_1980_full `controls_1980_full' `var'_`t'
		}
	}

di "`controls_1980'"

gen year2 = year		//Duplicate of year, to include as interaction with only 2000 and 2010 levels with controls
label val year2 YEAR
tempfile chars
save `chars'

*merge in shares
use "${home}/raw/shares_long_ind3_czone", clear

gen natindwt2 = natindwt + indwt 	//reverse the "Leave-Out"
drop nat_empl_ind_
gen nat_empl_ind_lo_ = ((F.natindwt-natindwt)/natindwt)/(10)
gen nat_empl_ind_ = ((F.natindwt2-natindwt2)/natindwt2)/(10)

keep nat_empl_ind_ nat_empl_ind_lo_ sh_ind_ year czone ind3
reshape wide nat_empl_ind_ nat_empl_ind_lo_ sh_ind_ , i(year czone) j(ind3)
tsset czone year, delta(10)

merge 1:1 czone year using `chars', assert(3) nogen
merge m:1 czone using `czone_pop', keep(1 3) nogen


foreach x of varlist sh_ind_* {
	replace `x' = 0 if `x' == .
	}


foreach x of varlist nat_empl_ind_* nat_empl_ind_lo_* {
	egen _`x' = mean(`x'), by(year)
	replace `x' = _`x' if `x' == . & _`x' != .
	replace `x' = 0 if `x' == . & _`x' == .	
	drop _`x'
	}


bys czone (year): drop if year[1]!=1980	
foreach var of varlist sh_ind_* {
	bys czone (year): gen yr1980_`var' = `var'[1] if year[1]==1980		
	}


foreach x of varlist sh_ind_* {
	if regexm("`x'", "^sh_ind_(.*)$") {
		local tail_stub "`=regexs(1)'"
		}
	gen test_`tail_stub' = yr1980_sh_ind_`tail_stub' * (nat_empl_ind_lo_`tail_stub' )
	qui sum yr1980_sh_ind_`tail_stub'
	if r(mean) == 0 {
		drop yr1980_sh_ind_`tail_stub'
		}
	}

egen z2 = rowtotal(test_*)
drop test_*
discard
keep if year!=2010
save "${home}/input_BAR2", replace
