



clear all
set matsize 1000

global data_path "../data/"
use $data_path/input_BAR2, clear

local controls male race_white native_born educ_hs educ_coll veteran nchild
local weight pop1980

local y wage_ch
local x emp_ch

local ind_stub init_sh_ind_
local growth_stub nat_empl_ind_

local time_var year
local cluster_var czone

qui tab year2, gen(year_)
drop year_1

levelsof `time_var', local(years)

/* Construct initial industry shares  and controls */
sort czone year
foreach ind_var of varlist sh_ind_* {
	gen `ind_var'_1980b = `ind_var' if year == 1980
	by czone (year): gen init_`ind_var' = `ind_var'_1980b[1]
	drop `ind_var'_1980b
	qui sum init_`ind_var'
	if r(mean) == 0 {
		drop init_`ind_var'
		if regexm("`ind_var'", "`ind_stub'(.*)") {
			local ind_num = regexs(1)
			}
		}
	qui sum `ind_var'
	if r(mean) == 0 {
		drop init_`ind_var'
		if regexm("`ind_var'", "`ind_stub'(.*)") {
			local ind_num = regexs(1)
			*drop nat_empl_ind_`ind_num'
			}
		}
	
	}

foreach var of varlist init_sh_ind_* {
	if regexm("`var'", "init_sh_ind_(.*)") {
		local ind = regexs(1) 
		gen nat1980_empl_ind_`ind' = nat_empl_ind_`ind'
		}
	}

sort czone year
foreach control of varlist `controls' {
	gen `control'_1980b = `control' if year == 1980
	by czone (year): gen init_`control' = `control'_1980b[1]
	drop `control'_1980b
}

local ind_stub init_sh_ind_
local controls init_male init_race_white init_native_born init_educ_hs init_educ_coll init_veteran init_nchild
local growth_stub nat1980_empl_ind_
egen mean_growth = rowmean(nat1980_empl_ind_*)
foreach growth of varlist `growth_stub'* {
	qui replace `growth' = `growth' - mean_growth
	}
drop mean_growth

foreach year in `years' {
	foreach ind_var of varlist `ind_stub'* {
		gen t`year'_`ind_var' = `ind_var' * (year == `year')
		}
	foreach var of varlist nat1980_empl_ind_* {
		gen t`year'_`var'b = `var' if year == `year'
		egen t`year'_`var' = max(t`year'_`var'b), by(czone)
		drop t`year'_`var'b
		replace t`year'_`var' = 0 if t`year'_`var' == .
		}
	foreach ind_var of varlist `controls' {
		if `year' != 1980 {
			gen t`year'_`ind_var' = `ind_var' * (year == `year')
			}
		}
	}

qui desc t*_`growth_stub'*, varlist full
disp wordcount(r(varlist))
qui desc t*_`ind_stub'*, varlist
disp wordcount(r(varlist))


foreach ind_var of varlist `ind_stub'* {
	if regexm("`ind_var'", "`ind_stub'(.*)") {
		local ind_num = regexs(1)
		replace `growth_stub'`ind_num' = 0 if `growth_stub'`ind_num' == .
		gen b_`ind_num' = `ind_var' * `growth_stub'`ind_num'
		}
	}
drop z2
egen z2 = rowtotal(b_*)
drop b_*


local controls t*_init_male t*_init_race_white t*_init_native_born t*_init_educ_hs t*_init_educ_coll t*_init_veteran t*_init_nchild year_*


drop if czone == .


label var `ind_stub'42 "Oil and Gas Extraction"
label var `ind_stub'351 "Motor Vehicles"
label var `ind_stub'0 "Other"
label var `ind_stub'362 "Guided Missiles"
label var `ind_stub'270 "Blast furnaces"
label var z2 "Bartik (1980 shares)"


label var init_male "Male"
label var init_race_white "White"
label var init_native_born "Native Born"
label var init_educ_hs "12th Grade Only"
label var init_educ_coll "Some College"
label var init_veteran "Veteran"
label var init_nchild "\# of Children"




eststo clear
preserve
foreach var of varlist `ind_stub'42 `ind_stub'351 `ind_stub'0 `ind_stub'362 `ind_stub'270 z2 {
	replace `var' = `var' *100 if "`var'" != "`z'"
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		}
	eststo: reg `var' init_male init_race_white init_native_born init_educ_hs init_educ_coll init_veteran init_nchild [aweight=`weight'] if year == 1980 , cluster(czone)
	estadd local pop_weight = "Yes"	
	}
restore

esttab using ../results/bar_characteristics.tex, 	drop(_cons) b(3) not se replace nostar booktabs ///
	stats(pop_weight r2 N , fmt(0 2 0) labels("Population Weighted" `"$ R^2$"' "N")) label ///
	nonumbers compress collabels(none) nogaps									//Write regression output to LaTeX




