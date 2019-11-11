
global data_path "../results/temp/"
clear all
discard
set seed 12345
use ../data/input_card, clear

* Export destination for plots.
global export_path "../results"

* Note: "ind" here stands for "industry" and not "independent". 
local ind_stub shric

foreach ind_var of varlist `ind_stub'* {
	replace `ind_var' = `ind_var' * 100
	}



local controls logsize80 logsize90 coll80 coll90 ires80 nres80 mfg80 mfg90
local weight count90

local y resgap2
local x relshs
local z hsiv


/***************************************/
/* Pre-trends for HS equivalent workers */ 
/***************************************/					
/* Do regressions using Bartik instrument */
* 1980 
regress resgap802 `controls' hsiv [aweight = count90], robust
display(e(df_m))
parmest, saving("$data_path/hs_bartik_80", replace) 

preserve
use $data_path/hs_bartik_80, clear
keep if parm == "hsiv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1980
save $data_path/hs_bartik_80, replace
restore

* 1990
regress resgap902 `controls' hsiv [aweight = count90], robust
parmest, saving("$data_path/hs_bartik_90", replace) 

preserve
use $data_path/hs_bartik_90, clear
keep if parm == "hsiv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1990
save $data_path/hs_bartik_90, replace
restore

* 2000
regress resgap2 `controls' hsiv [aweight = count90], robust
parmest, saving("$data_path/hs_bartik_2000", replace) 

preserve
use $data_path/hs_bartik_2000, clear
keep if parm == "hsiv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 2000
save $data_path/hs_bartik_2000, replace
restore

preserve
clear 
append using $data_path/hs_bartik_80 $data_path/hs_bartik_90 $data_path/hs_bartik_2000
save $data_path/hs_pretrend_bartik, replace
restore

/* Do regressions using initial imm share as instrument */
local top5_countries 1 5 2 6 31 

foreach country of local top5_countries{
/* Reduced form regressions for country 1. All shares are fixed in 1980. */
* 1980
regress resgap802 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/hs_ic`country'_yr1", replace)

preserve
use $data_path/hs_ic`country'_yr1, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1980
save $data_path/hs_ic`country'_yr1, replace
restore

* 1990
regress resgap902 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/hs_ic`country'_yr2", replace)

preserve
use $data_path/hs_ic`country'_yr2, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1990
save $data_path/hs_ic`country'_yr2, replace
restore


* 2000
regress resgap2 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/hs_ic`country'_yr3", replace)

preserve
use $data_path/hs_ic`country'_yr3, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 2000
save $data_path/hs_ic`country'_yr3, replace
restore

preserve
clear
append using $data_path/hs_ic`country'_yr1 $data_path/hs_ic`country'_yr2 $data_path/hs_ic`country'_yr3
save $data_path/hs_pretrend_ic`country', replace
restore
}

/* Plots */
preserve
clear 
use $data_path/hs_pretrend_ic1
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("hs_mexico") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_mexico.pdf, replace
restore

preserve
clear 
use $data_path/hs_pretrend_ic5
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("hs_elsalvador") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_elsalvador.pdf, replace
restore


preserve
clear 
use $data_path/hs_pretrend_ic2
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy)  ///
	name("hs_philippines") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_philippines.pdf, replace
restore

preserve
clear 
use $data_path/hs_pretrend_ic6
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("hs_china") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_china.pdf, replace
restore

preserve
clear 
use $data_path/hs_pretrend_ic31
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("hs_westeurope") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_westeurope.pdf, replace
restore

preserve
clear 
use $data_path/hs_pretrend_bartik
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("hs_aggregate") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_hs_aggregate.pdf, replace
restore

/********************************************/
/* Pre-trends for College equivalent workers */ 
/********************************************/
/* Do regressions using Bartik instrument */
* 1980
regress resgap802 `controls' colliv [aweight = count90], robust
display(e(df_m))
parmest, saving("$data_path/coll_bartik_80", replace) 

preserve
use $data_path/coll_bartik_80, clear
keep if parm == "colliv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1980
save $data_path/coll_bartik_80, replace
restore

* 1990
regress resgap902 `controls' colliv [aweight = count90], robust
parmest, saving("$data_path/coll_bartik_90", replace) 

preserve
use $data_path/coll_bartik_90, clear
keep if parm == "colliv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1990
save $data_path/coll_bartik_90, replace
restore

* 2000
regress resgap2 `controls' colliv [aweight = count90], robust
parmest, saving("$data_path/coll_bartik_2000", replace) 

preserve
use $data_path/coll_bartik_2000, clear
keep if parm == "colliv"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 2000
save $data_path/coll_bartik_2000, replace
restore

preserve
clear 
append using $data_path/coll_bartik_80 $data_path/coll_bartik_90 $data_path/coll_bartik_2000
save $data_path/coll_pretrend_bartik, replace
restore

/* Do regressions using initial imm share as instrument */
local top5_countries 2 1 6 31 7

foreach country of local top5_countries{
/* Reduced form regressions for country 1. All shares are fixed in 1980. */
* 1980
regress resgap804 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/coll_ic`country'_yr1", replace)

preserve
use $data_path/coll_ic`country'_yr1, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1980
save $data_path/coll_ic`country'_yr1, replace
restore

* 1990
regress resgap904 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/coll_ic`country'_yr2", replace)

preserve
use $data_path/coll_ic`country'_yr2, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 1990
save $data_path/coll_ic`country'_yr2, replace
restore


* 2000
regress resgap4 `controls' shric`country' [aweight = count90], robust
parmest, saving("$data_path/coll_ic`country'_yr3", replace)

preserve
use $data_path/coll_ic`country'_yr3, clear
keep if parm == "shric`country'"
gen low = estimate - 1.96 * stderr /* t-stat with 9 dof and 5% ci*/
gen high = estimate + 1.96 * stderr
gen yr = 2000
save $data_path/coll_ic`country'_yr3, replace
restore

preserve
clear
append using $data_path/coll_ic`country'_yr1 $data_path/coll_ic`country'_yr2 $data_path/coll_ic`country'_yr3
save $data_path/coll_pretrend_ic`country', replace
restore
}

/* Plots */
preserve
clear 
use $data_path/coll_pretrend_ic2
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("coll_philippines") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_philippines.pdf, replace
restore

preserve
clear 
use $data_path/coll_pretrend_ic1
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("coll_mexico") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_mexico.pdf, replace
restore

preserve
clear 
use $data_path/coll_pretrend_ic6
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("coll_china") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_china.pdf, replace
restore

preserve
clear 
use $data_path/coll_pretrend_ic31
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(-50000(10000)0, nogrid) mcolor(navy) /// 
	name("coll_westeurope") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_westeurope.pdf, replace
restore

preserve
clear 
use $data_path/coll_pretrend_ic7
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) mcolor(navy) ///
	legend(off) ylabel(, nogrid)  ///
	name("coll_cuba") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_cuba.pdf, replace
restore

preserve
clear 
use $data_path/coll_pretrend_bartik
tsset yr
twoway rcap high low yr || scatter estimate yr, ///
	ytitle("") ylabel(, angle(horizontal)) yline(0, lcolor(black))  ///
	xtitle("") xlabel(1980(10)2000) ///
	legend(off) ylabel(, nogrid) mcolor(navy) ///
	name("coll_aggregate") graphregion(color(white)) 
graph export $export_path/immigrant_pretrends_college_aggregate.pdf, replace
restore
