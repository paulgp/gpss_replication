

clear all
discard
set seed 12345
use ../data/input_card, clear

local controls logsize80 logsize90 coll80 coll90 ires80 nres80 mfg80 mfg90
local weight count90

local y resgap4
local x relscoll
local z colliv

local ind_stub shric
local growth_stub coll_imm_ic

local time_var year
local cluster_var rmsa


set matsize 4000
global controls `controls'
global y `y'
global x `x'
global z `z'
global ind_stub `ind_stub'
global growth_stub `growth_stub'
global weight `weight'
tsset, clear


foreach var of varlist `ind_stub'* {
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		}
	tempvar temp
	qui gen `temp' = `var' * `growth_stub'`ind'
	qui regress `x' `temp' `controls' [aweight=`weight'], cluster(rmsa)
	local pi_`ind' = _b[`temp']
	qui test `temp'
	local F_`ind' = r(F)
	qui regress `y' `temp' `controls' [aweight=`weight'], cluster(rmsa)
	local gamma_`ind' = _b[`temp']
	drop `temp'
	}

*local top5_countries 2 1 6 31 7
foreach var of varlist `ind_stub'2 `ind_stub'1 `ind_stub'6 `ind_stub'31 `ind_stub'7 {
	if regexm("`var'", "`ind_stub'(.*)") {
		local ind = regexs(1) 
		}
	tempvar temp
	qui gen `temp' = `var' * `growth_stub'`ind'
	ch_weak, p(.05) beta_range(-0.5(.005)0.5)   y(`y') x(`x') z(`temp') weight(`weight') controls(`controls') cluster(rmsa)
	disp r(beta_min) ,  r(beta_max)
	local ci_min_`ind' =string( r(beta_min), "%9.3f")
	local ci_max_`ind' = string( r(beta_max), "%9.3f")
	disp "`ind', `beta_`ind'', `t_`ind'', [`ci_min_`ind'', `ci_max_`ind'']"
	drop `temp'
	}


preserve
keep `ind_stub'* rmsa `weight'
reshape long `ind_stub', i(rmsa) j(ind)
gen `ind_stub'pop = `ind_stub'*`weight'
collapse (sd) `ind_stub'sd = `ind_stub' (rawsum) `ind_stub'pop `weight' [aweight = `weight'], by(ind)
tempfile tmp
save `tmp'
restore

bartik_weight, z(`ind_stub'*)    weightstub(`growth_stub'*) x(`x') y(`y') controls(`controls'  ) weight_var(`weight')

mat beta = r(beta)
mat alpha = r(alpha)
mat gamma = r(gam)
mat pi = r(pi)
mat G = r(G)
qui desc `ind_stub'*, varlist
local varlist = r(varlist)



clear
svmat beta
svmat alpha
svmat gamma
svmat pi
svmat G

gen ind = ""
*gen year = ""
local t = 1
foreach var in `varlist' {
	if regexm("`var'", "`ind_stub'(.*)") {
		qui replace ind = regexs(1) if _n == `t'
		}
	local t = `t' + 1
	}

/** Calculate Panel C: Variation across years in alpha **/
/* total alpha1 if year == "1990" */
/* mat b = e(b) */
/* local sum_1990_alpha = string(b[1,1], "%9.3f") */
/* total alpha1 if year == "2000" */
/* mat b = e(b) */
/* local sum_2000_alpha = string(b[1,1], "%9.3f") */

/* sum alpha1 if year == "1990" */
/* local mean_1990_alpha = string(r(mean), "%9.3f") */
/* sum alpha1 if year == "2000" */
/* local mean_2000_alpha = string(r(mean), "%9.3f") */

destring ind, replace
*destring year, replace
merge 1:1 ind using `tmp'
gen beta2 = alpha1 * beta1
gen indshare2 = alpha1 * (`ind_stub'pop / `weight')
gen indshare_sd2 = alpha1 * `ind_stub'sd
gen G2 = alpha1 * G1
collapse (sum) alpha1 beta2 indshare2 indshare_sd2 G2 (mean) G1 , by(ind)
gen agg_beta = beta2 / alpha1
gen agg_indshare = indshare2 / alpha1
gen agg_indshare_sd = indshare_sd2 / alpha1
gen agg_g = G2 / alpha1
preserve
insheet using ../data/country_ids.csv,comma clear names
rename country ind_name
replace ind_name = proper(ind_name)
tempfile tmp_name
save `tmp_name'
restore
merge 1:1 ind using `tmp_name'
keep if _merge == 3
*gen ind_name = subinstr(description, "Not Elsewhere Classified", "NEC", .)
*replace ind_name = subinstr(ind_name, ", Except Dolls and Bicycles", "", .)

gsort -alpha1

/***
ind	alpha1	beta2	beta1	agg_beta
3571	.1826005	-.1130861	-.6087478	-.6193091
3944	.1375558	-.0173997	-.0609449	-.1264918
3651	.0853901	.0148397	.770126	.1737877
3661	.0662476	-.0208716	-.5065653	-.3150544
3577	.0601904	-.0182433	-.4240822	-.3030925
***/



capture file close fh
file open fh  using "../results/rotemberg_summary_card_college.tex", write replace
file write fh "\toprule" _n

/** Panel A: Negative and Positive Weights **/
capture total alpha1 if alpha1 > 0
mat b = e(b)
local sum_pos_alpha = string(b[1,1], "%9.3f")
capture total alpha1 if alpha1 < 0
mat b = e(b)
local sum_neg_alpha = string(b[1,1], "%9.3f")

sum alpha1 if alpha1 > 0
local mean_pos_alpha = string(r(mean), "%9.3f")
sum alpha1 if alpha1 < 0
local mean_neg_alpha = string(r(mean), "%9.3f")

local share_pos_alpha = string(abs(`sum_pos_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")
local share_neg_alpha = string(abs(`sum_neg_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")


/** Panel B: Correlations of Industry Aggregates **/
gen F = .
gen agg_pi = .
gen agg_gamma = .
levelsof ind, local(industries)
foreach ind in `industries' {
	capture replace F = `F_`ind'' if ind == `ind'
	capture replace agg_pi = `pi_`ind'' if ind == `ind'
	capture replace agg_gamma = `gamma_`ind'' if ind == `ind'		
	}
corr alpha1 agg_g agg_beta F agg_indshare_sd
mat corr = r(C)
forvalues i =1/5 {
	forvalues j = `i'/5 {
		local c_`i'_`j' = string(corr[`i',`j'], "%9.3f")
		}
	}

/** Panel  D: Top 5 Rotemberg Weight Inudstries **/
*local top5_countries 2 1 6 31 7
foreach ind in 2 1 6 31 7 {
	qui sum alpha1 if ind == `ind'
   local alpha_`ind' = string(r(mean), "%9.3f")
	qui sum agg_g if ind == `ind'	
	local g_`ind' = string(r(mean), "%9.3f")
	qui sum agg_beta if ind == `ind'	
	local beta_`ind' = string(r(mean), "%9.3f")
	qui sum agg_indshare if ind == `ind'	
	local share_`ind' = string(r(mean)*100, "%9.3f")
	tempvar temp
	qui gen `temp' = ind == `ind'
	gsort -`temp'
	local ind_name_`ind' = ind_name[1]
	drop `temp'
	}


/** Over ID Figures **/
gen omega = alpha1*agg_beta
total omega
mat b = e(b)
local b = b[1,1]

gen label_var = ind 
gen beta_lab = string(agg_beta, "%9.3f")


gen abs_alpha = abs(alpha1) 
gen positive_weight = alpha1 > 0
gen agg_beta_pos = agg_beta if positive_weight == 1
gen agg_beta_neg = agg_beta if positive_weight == 0
twoway (scatter agg_beta_pos agg_beta_neg F if F >= 5 [aweight=abs_alpha ], msymbol(Oh Dh) ), legend(label(1 "Positive Weights") label( 2 "Negative Weights")) yline(`b', lcolor(black) lpattern(dash)) xtitle("First stage F-statistic")  ytitle("{&beta}{subscript:k} estimate")
graph export "../results/overid_CARD_college.pdf", replace

gsort -alpha1
twoway (scatter F alpha1 if _n <= 5, mcolor(dblue) mlabel(ind_name  ) msize(0.5) mlabsize(2) ) (scatter F alpha1 if _n > 5, mcolor(dblue) msize(0.5) ), name(a, replace) xtitle("Rotemberg weight") ytitle("First stage F-statistic") yline(10, lcolor(black) lpattern(dash)) legend(off)
graph export "../results/F_vs_rotemberg_weight_CARD_college.pdf", replace


/** Panel E: Weighted Betas by alpha weights **/
gen agg_beta_weight = agg_beta * alpha1

collapse (sum) agg_beta_weight alpha1 (mean)  agg_beta, by(positive_weight)
egen total_agg_beta = total(agg_beta_weight)
gen share = agg_beta_weight / total_agg_beta
gsort -positive_weight
local agg_beta_pos = string(agg_beta_weight[1], "%9.3f")
local agg_beta_neg = string(agg_beta_weight[2], "%9.3f")
local agg_beta_pos2 = string(agg_beta[1], "%9.3f")
local agg_beta_neg2 = string(agg_beta[2], "%9.3f")
local agg_beta_pos_share = string(share[1], "%9.3f")
local agg_beta_neg_share = string(share[2], "%9.3f")

/*** Write final table **/
/** Panel A **/
file write fh "\multicolumn{3}{l}{\textbf{Panel A: Negative and positive weights}}\\" _n
file write fh  " & Sum & Mean & Share \\  \cmidrule(lr){2-4}" _n
file write fh  "Negative & `sum_neg_alpha' & `mean_neg_alpha' & `share_neg_alpha' \\" _n
file write fh  "Positive & `sum_pos_alpha' & `mean_pos_alpha' & `share_pos_alpha' \\" _n

/** Panel B **/
file write fh "\multicolumn{5}{l}{\textbf{Panel B: Correlations of Industry Aggregates} }\\" _n
file write fh  " &$\alpha_k$ & \$g_{k}$ & $\beta_k$ & \$F_{k}$ & Var(\$z_k$) \\" _n
file write fh  "\cmidrule(lr){2-6} " _n
file write fh " & \\" _n
file write fh " $\alpha_k$             & 1\\" _n
file write fh " \$g_{k}$                &   `c_1_2'  & 1\\" _n
file write fh " $\beta_{k}$             &   `c_1_3'  & `c_2_3'    &1\\" _n
file write fh " \$F_{k}$                &   `c_1_4'  & `c_2_4'    &  `c_3_4'  & 1\\" _n
file write fh " Var(\$z_{k}$)           &   `c_1_5'  & `c_2_5'    &  `c_3_5'  &  `c_4_5'   &1\\" _n

/** Panel C **/
file write fh "\multicolumn{5}{l}{\textbf{Panel C: Variation across years in $\alpha_{k}$}}\\" _n
file write fh  " & Sum & Mean \\  \cmidrule(lr){2-3}" _n
file write fh  "1990 & `sum_1990_alpha' & `mean_1990_alpha' \\" _n
file write fh  "2000 & `sum_2000_alpha' & `mean_2000_alpha' \\" _n

/** Panel D **/
file write fh "\multicolumn{5}{l}{\textbf{Panel D: Top 5 Rotemberg weight industries} }\\" _n
file write fh  " & $\hat{\alpha}_{k}$ & \$g_{k}$ & $\hat{\beta}_{k}$ & 95 \% CI  \\ \cmidrule(lr){2-6}" _n
foreach ind in 2 1 6 31 7 {
	if `ci_min_`ind'' != -1 & `ci_max_`ind'' != 1 {
		file write fh  "`ind_name_`ind'' & `alpha_`ind'' & `g_`ind'' & `beta_`ind'' & (`ci_min_`ind'',`ci_max_`ind'') \\ " _n
		}
	else  {
		file write fh  "`ind_name_`ind'' & `alpha_`ind'' & `g_`ind'' & `beta_`ind'' & \multicolumn{1}{c}{N/A}   \\ " _n
		}
	}

/** Panel E **/
file write fh "\multicolumn{5}{l}{\textbf{Panel E: Estimates of $\beta_{k}$ for positive and negative weights} }\\" _n
file write fh  " & $\alpha$-weighted Sum & Share of overall $\beta$ & Mean  \\ \cmidrule(lr){2-3}" _n
file write fh  " Negative & `agg_beta_neg' & `agg_beta_neg_share' &`agg_beta_neg2' \\" _n
file write fh  " Positive & `agg_beta_pos' & `agg_beta_pos_share' & `agg_beta_pos2' \\" _n
file write fh  "\bottomrule" _n
file close fh


