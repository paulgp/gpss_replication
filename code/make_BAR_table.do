
set rmsg on
clear all
set matsize 1000
set seed 12345
*set trace on
*set tracedepth 2
discard

use ../data/input_BAR2, clear

local controls male race_white native_born educ_hs educ_coll veteran nchild 
local weight pop1980

local y wage_ch
local x emp_ch
local z z2

local ind_stub init_sh_ind_
local growth_stub nat_empl_ind_

local time_var year
local cluster_var czone

qui tab year2, gen(year_)
drop year_1
qui tab czone, gen(czone_)
drop czone_1

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
egen z3 = rowtotal(b_*)
drop b_*

drop t2000_init_sh_ind_932 t1990_init_sh_ind_932



local controls t*_init_male t*_init_race_white t*_init_native_born t*_init_educ_hs t*_init_educ_coll t*_init_veteran t*_init_nchild year_*

drop if czone == .

foreach year in 1980 {
	foreach ind_var of varlist `ind_stub'* {
		capture drop t`year'_`ind_var' 
		}
}

set matsize 4000
global controls `controls'
global y `y'
global x `x'
global z `z'
global ind_stub `ind_stub'
global growth_stub `growth_stub'
global weight `weight'
tsset, clear

capture program drop test_and_compare
program define test_and_compare, rclass
	btsls, z(z2) x($x) y($y) controls(czone_* year_*) ktype("tsls") weight_var($weight)
	local b_bar_lo_2sls_1 = r(beta)
	return scalar b_bar_lo_2sls_1 = `b_bar_lo_2sls_1'
	btsls, z(z2) x($x) y($y) controls($controls czone_*) ktype("tsls") weight_var($weight)
	local b_bar_lo_2sls_2 = r(beta)
	return scalar b_bar_lo_2sls_2 = `b_bar_lo_2sls_2'
	return scalar diff_bar_lo_2sls = `b_bar_lo_2sls_1' - `b_bar_lo_2sls_2'
	btsls, z(z3) x($x) y($y) controls(czone_* year_*) ktype("tsls") weight_var($weight)
	local b_bar_2sls_1 = r(beta)
	return scalar b_bar_2sls_1 = `b_bar_2sls_1'
	btsls, z(z3) x($x) y($y) controls($controls czone_*) ktype("tsls") weight_var($weight)
	local b_bar_2sls_2 = r(beta)
	return scalar b_bar_2sls_2 = `b_bar_2sls_2'
	return scalar diff_bar_2sls = `b_bar_2sls_1' - `b_bar_2sls_2'
	btsls, z("`1'") x($x) y($y) controls(czone_* year_*) ktype("tsls") weight_var($weight)
	local b_sh_2sls_1 = r(beta)
	return scalar b_sh_2sls_1 = `b_sh_2sls_1'
	btsls, z("`1'") x($x) y($y) controls(czone_* $controls) ktype("tsls") weight_var($weight)
	local b_sh_2sls_2 = r(beta)
	return scalar b_sh_2sls_2 = `b_sh_2sls_2'
	return scalar diff_sh_2sls = `b_sh_2sls_1' - `b_sh_2sls_2'
	btsls, z("`1'") x($x) y($y) controls(czone_* year_*) ktype("mbtsls") weight_var($weight)
	local b_sh_mbtsls_1 = r(beta)
	return scalar b_sh_mbtsls_1 = `b_sh_mbtsls_1'
	btsls, z("`1'") x($x) y($y) controls(czone_* $controls) ktype("mbtsls") weight_var($weight)
	local b_sh_mbtsls_2 = r(beta)
	return scalar b_sh_mbtsls_2 = `b_sh_mbtsls_2'
	return scalar diff_sh_mbtsls = `b_sh_mbtsls_1' - `b_sh_mbtsls_2'
end

capture program drop liml_bootstrap
program define  liml_bootstrap, rclass
	reghdfe  $y  ($x =  t*_init_sh_ind_*) [aw=$weight], absorb( i.czone i.year) estimator(liml) old
	local b_1 = _b[$x]
	reghdfe  $y $controls ($x =  t*_init_sh_ind_*) [aw=$weight], absorb( i.czone) estimator(liml) old
	local b_2 = _b[$x]
	return scalar b_1 = `b_1'
	return scalar b_2 = `b_2'
	return scalar diff = `b_1' - `b_2'
end

capture program drop test_and_compare_chao
program define test_and_compare_chao, rclass
	overid_chao, z(`1') x($x) y($y) controls(czone_* year_*)  weight_var($weight)
	local b_1 = r(delta)
	return scalar b_1 = `b_1'
	overid_chao, z(`1') x($x) y($y) controls($controls czone_*)  weight_var($weight)
	local b_2 = r(delta)
	return scalar b_2 = `b_2'
	return scalar diff = `b_1' - `b_2'
end

local n = 200

estimates clear
qui reg `y' `x' czone_* year_* [aweight=`weight'], cluster(czone)
local b1_ols = string(_b[`x'], "%12.2f")
local se1_ols = "(" + string(_se[`x'], "%12.2f") + ")"
qui reg `y' `x' czone_* year_* [aweight=`weight']
estimates store ols1

qui reg `y' `x' czone_* `controls' [aweight=`weight'], cluster(czone)
local b2_ols = string(_b[`x'], "%12.2f")
local se2_ols = "(" +  string(_se[`x'], "%12.2f") + ")"
qui reg `y' `x' czone_* `controls' [aweight=`weight']
estimates store ols2

suest ols1 ols2, cluster(czone)
test [ols1_mean]`x'=[ols2_mean]`x'
local p_ols = "[" + string(r(p), "%12.2f") + "]"


ivregress 2sls  `y'  `controls' czone_*   (`x'= t1990_init_sh_ind_* t2000_init_sh_ind_*  )  [aweight=`weight'], vce(robust)
local insts = e(insts)
local cont = e(exogr)
local insts2 ""

/*** Consruct varlist of independent regressors **/
foreach var in `insts' {
	if ~regexm("`cont'", "`var'") & ~regexm("`var'", "o.") & "t2000_init_sh_ind_932" != "`var'"  & "t1990_init_sh_ind_932" != "`var'" {
		local insts2 "`insts2' `var'"
		}
	}
estat overid, forceweights
global insts2 "`insts2'"

local J_2sls = string(r(score), "%12.2f")
local Jp_2sls = "[" + string(r(p_score), "%12.2f") + "]"


test_and_compare "`insts2'"
return list
local b1_bartik = string(r(b_bar_2sls_1), "%12.2f")
local b2_bartik = string(r(b_bar_2sls_2), "%12.2f")
local b1_bartik_lo = string(r(b_bar_lo_2sls_1), "%12.2f")
local b2_bartik_lo = string(r(b_bar_lo_2sls_2), "%12.2f")
local b1_2sls = string(r(b_sh_2sls_1), "%12.2f")
local b2_2sls = string(r(b_sh_2sls_2), "%12.2f")
local b1_mbtsls = string(r(b_sh_mbtsls_1), "%12.2f")
local b2_mbtsls = string(r(b_sh_mbtsls_2), "%12.2f")


bootstrap b1_bartik = r(b_bar_2sls_1) b2_bartik = r(b_bar_2sls_2) diff_bartik = r(diff_bar_2sls) ///
  b1_bartik_lo = r(b_bar_lo_2sls_1) b2_bartik_lo= r(b_bar_lo_2sls_2) ///
  diff_bartik_lo = r(diff_bar_lo_2sls) ///
  b1_2sls = r(b_sh_2sls_1) b2_2sls = r(b_sh_2sls_2) diff_2sls = r(diff_sh_2sls) ///
  b1_mbtsls = r(b_sh_mbtsls_1)   b2_mbtsls = r(b_sh_mbtsls_2) diff_mbtsls = r(diff_sh_mbtsls), ///  
  cluster(czone) reps(`n'): test_and_compare  "`insts2'"
mat pval = r(table)
local se1_bartik = "[" + string(pval[2,1], "%12.2f") + "]"
local se2_bartik = "[" + string(pval[2,2], "%12.2f") + "]"
local p_bartik = "[" + string(pval[4,3], "%12.2f") + "]"
local se1_bartik_lo = "[" + string(pval[2,3], "%12.2f") + "]"
local se2_bartik_lo = "[" + string(pval[2,4], "%12.2f") + "]"
local p_bartik_lo = "[" + string(pval[4,6], "%12.2f") + "]"
local se1_2sls = "[" + string(pval[2,7], "%12.2f") + "]"
local se2_2sls = "[" + string(pval[2,8], "%12.2f") + "]"
local p_2sls = "[" + string(pval[4,9], "%12.2f") + "]"
local se1_mbtsls = "[" + string(pval[2,10], "%12.2f") + "]"
local se2_mbtsls = "[" + string(pval[2,11], "%12.2f") + "]"
local p_mbtsls = "[" + string(pval[4,12], "%12.2f") + "]"


qui ivregress liml `y'  (`x' =  `insts2') czone_* year_* [aw=`weight'], cluster(czone)
local b1_liml = string(_b[`x'], "%12.2f")
local se1_liml = "(" + string(_se[`x'], "%12.2f") + ")"
qui ivregress liml `y'  (`x' =  `insts2') `controls' czone_* [aw=`weight'], cluster(czone)
local b2_liml = string(_b[`x'], "%12.2f")
local se2_liml = "(" + string(_se[`x'], "%12.2f") + ")"
local N = e(N)
local K = wordcount(e(insts)) - wordcount(e(exogr))
local L = wordcount(e(exogr))
local kappa = e(kappa) - 1
local J_liml  = (`N' - `K' - `L') * (`kappa' - 1)
local alpha_L =  `L' / `N'
local alpha_K =  `K' / `N'
local crit = normal(sqrt((1 - `alpha_L') / ( 1- `alpha_K' - `alpha_L'))*invnorm(0.95)) 
disp chi2(`J_liml', `K'-1)
local Jp_liml = "[" + string(`=chi2(`J_liml', `K'-1)', "%12.2f") + "]"

bootstrap b1_liml = r(b_1) b2_liml = r(b_2) diff_liml = r(diff), cluster(czone) reps(`n'): liml_bootstrap
mat pval = r(table)
local p_liml = "[" + string(pval[4,3], "%12.2f") + "]"

capture bootstrap b1_hful = r(b_1) b2_hful = r(b_2) diff_hful = r(diff), cluster(czone) reps(`n'): test_and_compare_chao "`insts2'"
mat b = e(b)
mat V = vecdiag(e(V))
local b1_hful = string(b[1,1], "%12.2f")
local b2_hful = string(b[1,2], "%12.2f")
local se1_hful = "(" + string(sqrt(V[1,1]), "%12.2f") + ")"
local se2_hful = "(" + string(sqrt(V[1,2]), "%12.2f") + ")"
mat pval = r(table)
local p_hful = "[" + string(pval[4,3], "%12.2f") + "]"

capture overid_chao, z("`insts2'") x($x) y($y) controls($controls czone_*)  weight_var($weight)
local J_hful = string(r(T), "%12.2f")
local Jp_hful = "[" + string(r(p), "%12.2f") + "]"

capture file close fh
capture erase "../results/bar_results.tex"
file open fh using "../results/bar_results.tex", write replace

file write fh "OLS & `b1_ols' & `b2_ols' & `p_ols' & \\" _n
file write fh "    & `se1_ols'& `se2_ols'&         & \\" _n
file write fh "2SLS (Leave-Out Bartik) & `b1_bartik_lo' & `b2_bartik_lo' & `p_bartik_lo' & \\" _n
file write fh "    & `se1_bartik_lo' & `se2_bartik_lo' &         & \\" _n
file write fh "2SLS (Bartik) & `b1_bartik' & `b2_bartik' & `p_bartik' & \\" _n
file write fh "    & `se1_bartik' & `se2_bartik' &         & \\" _n
file write fh "2SLS & `b1_2sls' & `b2_2sls' & `p_2sls' & `J_2sls' \\" _n
file write fh "    & `se1_2sls'& `se2_2sls'&         & `Jp_2sls' \\" _n
file write fh "MBTSLS & `b1_mbtsls' & `b2_mbtsls' & `p_mbtsls' & \\" _n
file write fh "    & `se1_mbtsls'& `se2_mbtsls'&         & \\" _n
file write fh "LIML & `b1_liml' & `b2_liml' & `p_liml' & `J_liml'\\" _n
file write fh "    & `se1_liml'& `se2_liml'&         & `Jp_liml' \\" _n
file write fh "HFUL & `b1_hful' & `b2_hful' & `p_hful' & `J_hful' \\" _n
file write fh "    & `se1_hful'& `se2_hful'&         &  `Jp_hful' \\" _n

file close fh



