

set matsize 2000
use ../data/workfile_china_preperiod, clear
rename yr year
keep d_sh_empl_mfg  czone year timepwt48
rename timepwt48 weights
keep if year < 1990
tempfile tmp
save `tmp'

/*** AKM ADH Data **/
insheet using "../data/ADHdata_AKM.csv", clear
gen year = 1990 + (t2=="TRUE")*10
drop t2

/*** BHJ SHARES **/
merge 1:m czone year using ../data/Lshares.dta, gen(merge_shares)
/*** BHJ SHOCKS **/
merge m:1 sic87dd year using "../data/shocks.dta", gen(merge_shocks)

rename ind_share share_emp_ind_bhj_
gen z_ = share_emp_ind_bhj_ * g
rename g g_
drop g_emp_ind-g_importsUSA
reshape wide share_emp_ind_bhj_ g z_, i(czone year) j(sic87dd)
egen z = rowtotal(z_*)


append using  `tmp'


local controls reg_* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource l_shind_manuf_cbp
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

sort czone division
by czone: replace division = division[1]


tab division, gen(reg_)
drop reg_1
tab year, gen(t_)
drop t_1

drop if czone == .

foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource l_shind_manuf_cbp {
	gen fixed_`val'b = `val' if year == 1990
	egen fixed_`val' = max(fixed_`val'b), by(czone)
	forvalues t = 1970(10)2000 {
		gen t`t'_f_`val' = 100*(year == `t') * fixed_`val'
		}
	}


foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  {
	regress `y' t*_f_`val' reg_* t_2 t_3 t_4         [aweight = `weight'], cluster(czone)
	nlcom (100*(1+_b[t1970_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])*(1+_b[t2000_f_`val']))
	mat V = r(V)
	mat V = vecdiag(V)
	mat b = r(b)
	
	preserve
	regsave, ci
	keep if regexm(var, "f_`val'")
	split var, parse("_")
	replace var1 = subinstr(var1, "t", "", .)
	destring var1, replace
	rename var1 year
	set obs 5
	replace year=1960 if year == .
	sort year	
	gen index = 100
	gen index_upper = .
	gen index_lower = .
	replace index= b[1,1] if year == 1970
	replace index_upper = index + 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index_lower = index - 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index= index[_n-1]*(1+coef) if year == 1980
	replace index_upper = index + 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index_lower = index - 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index= index[_n-1]*(1+coef) if year == 1990
	replace index_upper = index + 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index_lower = index - 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index= index[_n-1]*(1+coef) if year == 2000
	replace index_upper = index + 1.96 * (sqrt(V[1,4])) if year == 2000
	replace index_lower = index - 1.96 * (sqrt(V[1,4])) if year == 2000
	replace year = year + 10
	replace year = 2007 if year == 2010
	twoway (scatter coef year, color(dblue) yline(0, lcolor(black))) (rcap ci_upper ci_lower year, color(dblue)) if year > 1970 ,  legend(off) name(`val'_nocont, replace) xtitle("") xlabel(1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_delta1980.pdf", replace
	twoway (scatter index year, color(dblue) yline(100, lcolor(black))) (rcap index_upper index_lower year, color(dblue)) ,  legend(off) name(`val'_index, replace) xtitle("") xlabel(1970 1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_index1980.pdf", replace	
	restore
}	


drop fixed_*
drop t*_f_*

foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource l_shind_manuf_cbp {
	gen fixed_`val'b = `val' if year == 2000
	egen fixed_`val' = max(fixed_`val'b), by(czone)
	forvalues t = 1970(10)2000 {
		gen t`t'_f_`val' = 100*(year == `t') * fixed_`val'
		}
	}


foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  {
	regress `y' t*_f_`val' reg_* t_2 t_3 t_4         [aweight = `weight'], cluster(czone)
	nlcom (100*(1+_b[t1970_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])*(1+_b[t2000_f_`val']))
	mat V = r(V)
	mat V = vecdiag(V)
	mat b = r(b)
	
	preserve
	regsave, ci
	keep if regexm(var, "f_`val'")
	split var, parse("_")
	replace var1 = subinstr(var1, "t", "", .)
	destring var1, replace
	rename var1 year
	set obs 5
	replace year=1960 if year == .
	sort year	
	gen index = 100
	gen index_upper = .
	gen index_lower = .
	replace index= b[1,1] if year == 1970
	replace index_upper = index + 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index_lower = index - 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index= index[_n-1]*(1+coef) if year == 1980
	replace index_upper = index + 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index_lower = index - 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index= index[_n-1]*(1+coef) if year == 1990
	replace index_upper = index + 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index_lower = index - 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index= index[_n-1]*(1+coef) if year == 2000
	replace index_upper = index + 1.96 * (sqrt(V[1,4])) if year == 2000
	replace index_lower = index - 1.96 * (sqrt(V[1,4])) if year == 2000
	replace year = year + 10
	replace year = 2007 if year == 2010
	twoway (scatter coef year, color(dblue) yline(0, lcolor(black))) (rcap ci_upper ci_lower year, color(dblue)) if year > 1970 ,  legend(off) name(`val'_nocont, replace) xtitle("") xlabel(1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_delta1990.pdf", replace
	twoway (scatter index year, color(dblue) yline(100, lcolor(black))) (rcap index_upper index_lower year, color(dblue)) ,  legend(off) name(`val'_index, replace) xtitle("") xlabel(1970 1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_index1990.pdf", replace	
	restore
}	

drop fixed_*
drop t*_f_*

foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource l_shind_manuf_cbp {
	gen fixed_`val'b = `val' if year == 2000
	egen fixed_`val' = max(fixed_`val'b), by(czone)
	forvalues t = 1970(10)2000 {
		gen t`t'_f_`val' = 100*(year == `t') * fixed_`val'
		}
	}


foreach val in z `ind_stub'3571 `ind_stub'3944 `ind_stub'3651 `ind_stub'3661 `ind_stub'3577  {
	regress `y' t*_f_`val' reg_* t_2 t_3 t_4         [aweight = `weight'], cluster(czone)
	nlcom (100*(1+_b[t1970_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])) ///
	 ( 100*(1+_b[t1970_f_`val'])*(1+_b[t1980_f_`val'])*(1+_b[t1990_f_`val'])*(1+_b[t2000_f_`val']))
	mat V = r(V)
	mat V = vecdiag(V)
	mat b = r(b)
	
	preserve
	regsave, ci
	keep if regexm(var, "f_`val'")
	split var, parse("_")
	replace var1 = subinstr(var1, "t", "", .)
	destring var1, replace
	rename var1 year
	set obs 5
	replace year=1960 if year == .
	sort year	
	gen index = 100
	gen index_upper = .
	gen index_lower = .
	replace index= b[1,1] if year == 1970
	replace index_upper = index + 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index_lower = index - 1.96 * (sqrt(V[1,1])) if year == 1970
	replace index= index[_n-1]*(1+coef) if year == 1980
	replace index_upper = index + 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index_lower = index - 1.96 * (sqrt(V[1,2])) if year == 1980
	replace index= index[_n-1]*(1+coef) if year == 1990
	replace index_upper = index + 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index_lower = index - 1.96 * (sqrt(V[1,3])) if year == 1990
	replace index= index[_n-1]*(1+coef) if year == 2000
	replace index_upper = index + 1.96 * (sqrt(V[1,4])) if year == 2000
	replace index_lower = index - 1.96 * (sqrt(V[1,4])) if year == 2000
	replace year = year + 10
	replace year = 2007 if year == 2010
	twoway (scatter coef year, color(dblue) yline(0, lcolor(black))) (rcap ci_upper ci_lower year, color(dblue)) if year > 1970 ,  legend(off) name(`val'_nocont, replace) xtitle("") xlabel(1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_delta1990.pdf", replace
	twoway (scatter index year, color(dblue) yline(100, lcolor(black))) (rcap index_upper index_lower year, color(dblue)) ,  legend(off) name(`val'_index, replace) xtitle("") xlabel(1970 1980 1990 2000 2007)
	graph export "../results/`val'_pre_trends_index1990.pdf", replace	
	restore
}	

