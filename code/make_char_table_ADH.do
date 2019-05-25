


global our_adh_data "../data"
global our_adh_data2 "../data"
global akm_adh_data "../data"
global bhj_adh_data "../data"
set matsize 2000


/*** AKM ADH Data **/
insheet using "$akm_adh_data/ADHdata_AKM.csv", clear
gen year = 1990 + (t2=="TRUE")*10
drop t2

/*** BHJ SHARES **/
merge 1:m czone year using $bhj_adh_data/Lshares.dta, gen(merge_shares)
/*** BHJ SHOCKS **/
merge m:1 sic87dd year using "$bhj_adh_data/shocks.dta", gen(merge_shocks)

rename ind_share share_emp_ind_bhj_
gen z_ = share_emp_ind_bhj_ * g
rename g g_
drop g_emp_ind-g_importsUSA
reshape wide share_emp_ind_bhj_ g z_, i(czone year) j(sic87dd)
egen z = rowtotal(z_*)


local controls reg_* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource l_shind_manuf_cbp t2
local weight weight

local y d_sh_empl_mfg 
local x shock
local z z


local ind_stub share_emp_ind_bhj_
local growth_stub g_

local time_var year
local cluster_var czone

levelsof `time_var', local(years)

/** g_2141 and g_3761 = 0 for all years **/
drop g_2141 `ind_stub'2141
drop g_3761 `ind_stub'3761

forvalues t = 1990(10)2000 {
	foreach var of varlist `ind_stub'* {
		gen t`t'_`var' = (year == `t') * `var'
		}
	foreach var of varlist `growth_stub'* {
		gen t`t'_`var'b = `var' if year == `t'
		egen t`t'_`var' = max(t`t'_`var'b), by(czone)
		drop t`t'_`var'b
		}
	}

tab division, gen(reg_)
drop reg_1
tab year, gen(t)
drop t1

drop if czone == .

label var `ind_stub'3571 "Electronic Computers"
label var `ind_stub'3944 "Games, Toys, and Children’s Vehicles"
label var `ind_stub'3651 "Household Audio and Video Equipment"
label var `ind_stub'3661 "Telephone and Telegraph Apparatus"
label var `ind_stub'3577 "Computer Peripheral Equipment, NEC"
label var `z' "China to other"
	
label var l_shind_manuf_cbp 	"Share Empl in Manufacturing"
label var l_sh_popedu_c		"Share College Educated"
label var l_sh_popfborn		"Share Foreign Born"
label var l_sh_empl_f		"Share Empl of Women"
label var  l_sh_routine33	"Share Empl in Routine"
label var l_task_outsource 	"Avg Offshorability"




eststo clear
preserve
foreach var of varlist `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577 `z' {
	replace `var' = `var' *100 if "`var'" != "`z'"
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		}
	eststo: reg `var' l_shind_manuf_cbp l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource [aweight=`weight'], cluster(czone)
	estadd local pop_weight = "Yes"	
	}
restore

esttab using ../results/adh_characteristics.tex, 	drop(_cons) b(3) not se replace nostar booktabs ///
	stats(pop_weight r2 N , fmt(0 2 0) labels("Population Weighted" `"$ R^2$"' "N")) label ///
	nonumbers compress collabels(none) nogaps									//Write regression output to LaTeX


*esttab `dependent_var'* using "${maya_home}/Tables/Balance_Tables/`dependent_var'/Balance_Tables_`dependent_var'_`switch'_ind`ind_digits'_`inst'.tex", ///

