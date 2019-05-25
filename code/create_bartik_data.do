

********************************************************************************
* #0 Program Setup
********************************************************************************
version 14
clear all
set linesize 80
set more off
set matsize 8000

local delta = 10																//Time period delta, set as 10 years
local geographies = "czone"												//Set geographies to use (puma, statefip, or both)
local geo = "czone"
local switch = "CZone"

global main = "../data"

********************************************************************************
* #1 Generate Basic Variables, Pool ACS for 2010
********************************************************************************
use "${main}/raw/IPUMS_data", clear												//Main dataset downloaded from IPUMS
drop ind																		//This is a time-inconsistent industry code we no longer use
merge 1:1 year serial pernum using "${main}/raw/IPUMS_ind1990", nogen assert(3) //Merge on ind1990 variable (3-digit, time-consistent), downloaded separately

merge 1:1 year serial pernum using "${main}/raw/IPUMS_geo", nogen keep(3) keepusing(county countyfips cntygp98 puma)

merge 1:1 year serial pernum using "${main}/raw/IPUMS_bpl", nogen keep(3) keepusing(bpl)

ren ind1990 ind3																//This ind1990 variable is the 3-digit industry variable we use
replace year = 2010 if inlist(year, 2009,2011)									//Pool 2009-2011 ACS samples to form single 2010 sample
keep if mod(year,10)==0															//Keep only 1980, 1990, 2000, and 2010 samples
replace perwt = perwt/3 if year==2010											//Divide person weights in 2010 by 3 to account for pooling
replace hhwt = hhwt/3 if year==2010												//Divide household weights in 2010 by 3 to account for pooling
*Maya added 8/17/2017
ren puma real_puma																//Consistent puma variable
label var real_puma "Real Puma (puma)"
ren conspuma puma																//Consistent puma variable
label var puma "Consistent Puma (conspuma)"
gen full_time = (uhrswork >= 30) if empstat==1 & !missing(uhrswork) 			//Full-time individuals defined as employed and work 30+ hrs/week
label var full_time "Share Employed and Usual Hrs Worked >=30"
/*There are some full-time individuals coded as N/As in 1980 only. We believe these
	are active duty military, and group the active duty military industries 
	(940-960) under this single N/A code (0) to ensure consistency across time 
	periods*/
assert ind3!=0 if full_time==1 & year>1980										//No full-time N/A's after 1980 (once military industry codes are added)
assert !inrange(ind3,940,960) if full_time==1 & year==1980						//No full-time military in 1980
replace ind3 = 0 if inrange(ind3,940,960)								//Replace 1990+ military codes with 1980 N/A code

gen cz_match = statefip*1000 + cntygp98 if year == 1980
replace cz_match = statefip*10000 + real_puma if year != 1980

preserve
*append in all of the commuting zone crosswalks (varies by year)
use "${main}/raw/cw_ctygrp1980_czone_corr", clear
gen year = 1980
append using "${main}/raw/cw_puma1990_czone"
replace year = 1990 if year == .
append using "${main}/raw/cw_puma2000_czone"
replace year = 2000 if year == .
append using "${main}/raw/cw_puma2000_czone"
replace year = 2010 if year == .

egen unique_identifier = rownonmiss(ctygrp1980 puma1990 puma2000)
assert unique_identifier == 1
egen cz_match = rowtotal(ctygrp1980 puma1990 puma2000)

keep afactor czone year cz_match
tempfile cz_xwalk
save `cz_xwalk'
restore

joinby cz_match year using `cz_xwalk', unmatched(master)	

rename afactor cz_wt
label var cz_wt "Commuting Zone Weight"

gen perwt_cz = perwt * cz_wt
gen hhwt_cz = hhwt * cz_wt 
label var cz_wt "Person * Commuting Zone Weight"
label var cz_wt "Household * Commuting Zone Weight"

*keeping only mainland CZs
merge m:1 czone using "${main}/raw/czone_list.dta", keep(3) nogen
unique czone
local test = r(sum)
assert `test' == 722
save "${main}/raw/raw_bartik", replace

use "${main}/raw/raw_bartik", clear
	
****************************************************************************
* #2 Generate Characteristic Variables to Collapse (Don't Need to Separate by Geography)
****************************************************************************
*******Household Variables
*^These variables are reported at the household level and need to be weighted accordingly when collapsing

gen mtg = inlist(mortgage,2,3,4) if !missing(mortgage)							//Mortgage indicator
label var mtg "Share hhold with a mortgage"

gen mtg2 = inlist(mortgag2,2,3,4,5) if !missing(mortgag2)						//Secondary mortgage indicator
label var mtg2 "Share hhold with a secondary mortgage"

gen ownership = ownershp==1 if  !missing(ownershp) 								//0 is n/a, 1 is owned, 2 is rented
label var ownership "Share hhold which own their home"

gen foodstamp = foodstmp==2 if !missing(foodstmp) 								//0 is n/a, 1 is no, 2 is yes
label var foodstamp "Share hhold on foodstamps"

local hh_vars mtg mtg2 ownership foodstamp rent hhincome valueh					//List of hhold level variables 				

******Individual Variables
*^These variables are reported at the individual level and need to be weighted accordingly when collapsing
gen male = sex==1 if !missing(sex) 												//1 is male, 2 is female
label var male "Male"

gen married = inlist(marst,1,2) if !missing(marst)								//Married, spouse present or absent
label var married "Married"

*Generate indicators for race
gen race_white = racesing==1 if !missing(racesing)
label var race_white "White"
gen race_black = racesing==2 if !missing(racesing)
label var race_black "Black"
gen race_namerican = racesing==3 if !missing(racesing)
label var race_namerican "Native American"
gen race_asian = racesing==4 if !missing(racesing)
label var race_asian "Asian"
gen race_other = racesing==5 if !missing(racesing)
label var race_other "Other Race"
gen hispanic = inlist(hispan,1,2,3,4) if hispan!=9 & !missing(hispan)
label var hispanic "Hispanic"

gen native_born = citizen==0 if !missing(citizen)								//Universe of this variable is foreign-born persons, so N/As are native born
label var native_born "Native Born"

gen yrs_us_lt10 = inlist(yrsusa2,1,2) if !missing(yrsusa2)
label var yrs_us_lt10 "Share Foreign-Born and Living in the US <=10 Years"

*Generate Educational Attainment Variables
gen educ_lt12 = inlist(educ,0,1,2,3,4,5) if !missing(educ)
label var educ_lt12 "$<$12th Grade"

gen educ_hs = educ==6 if !missing(educ)
label var educ_hs "12th Grade Only"

gen educ_coll_lt4yrs = inlist(educ,7,8,9) if !missing(educ)
label var educ_coll_lt4yrs "College $<$4 Years"

gen educ_coll_4yrs = educ==10 if !missing(educ)
label var educ_coll_4yrs "College 4 Years Only"

gen educ_coll_more = educ==11 if !missing(educ)
label var educ_coll_more "College 5+ Years"

gen educ_coll = educ_coll_lt4yrs + educ_coll_4yrs + educ_coll_more
label var educ_coll "Some College"

*Generate Employment and Labor Force Variables
gen employed = empstat==1 if inlist(empstat,1,2) 								//Indicator for employed if either employed or unemployed
label var employed "Share Employed"

gen in_lf = labforce==1  if !missing(labforce) 									//Indicator for in labor force, N/As (code 0) are 
label var in_lf "Share in Labor Force"

*Generate Migration Indicators, excluding N/As and missing
gen migr5_same_house = inlist(migrate5,1) if !missing(migrate5) & !inlist(migrate5,0,9) //Living in the same house as 5 years ago
label var migr5_same_house "5-Year Same House"

gen migr5_same_state = inlist(migrate5,1,2) if !missing(migrate5) & !inlist(migrate5,0,9) //Living in the same state as 5 years ago
label var migr5_same_state "5-Year Same State"

gen migr1_same_house = inlist(migrate1,1) if !missing(migrate1) & !inlist(migrate1,0,9) //Living in the same house as 1 year ago
label var migr1_same_house "1-Year Same House"

gen migr1_same_state = inlist(migrate1,1,2) if !missing(migrate1) & !inlist(migrate1,0,9) //Living in the same house as 1 year ago
label var migr1_same_state "1-Year Same State"

gen veteran = vetstat==2 if !missing(vetstat) & !inlist(vetstat,0,9)			//Exclude missing code (9) and N/As (code 0)
label var veteran "Veteran"

*Recode Income/Value Variables
recode inctot ftotinc incwage incss incwelfr incearn valueh (9999999 = .)		//Replace N/A code as missing for income variables
recode ftotinc incwage (999998 = .)												//Additional missing code is present for some income variables
*Note that some of these income variables are top-coded, with top-codes changing over time (inconsistent)

recode sei hwsei (0 = .)														//Recode N/As as missing

*Label some remaining variables
label var nchild "\# of Children"
label var nchlt5 "\# of Children $<$5"
label var age "Age" 
label var inctot "Total Income"
label var ftotinc "Total Family Income"
label var incwage "Wage Income"
label var incss "Social Security Income"
label var incwelfr "Welfare Income"
label var incearn "Earned Income"
label var sei "Socio-Economic Index"
label var hwsei "Socio-Economic Index v2"

local per_vars male married race_white race_black race_namerican race_asian race_other hispanic  ///
	native_born yrs_us_lt10 educ_lt12 educ_hs educ_coll_lt4yrs educ_coll_4yrs educ_coll_more ///
	educ_coll employed in_lf full_time migr5_same_house migr5_same_state migr1_same_house ///
	migr1_same_state veteran famsize nchild nchlt5 age uhrswork inctot ftotinc incwage ///
	incss incwelfr incearn sei hwsei //List of individual level variables

*Store variable labels to add back on after collapse
foreach var of varlist `hh_vars' `per_vars' perwt hhwt perwt_cz hhwt_cz {
	local `var': var label `var'
}

/*We temporarily break out of "if gen_chars" here because we want to loop over
	geographies regardless of whether or not we are regenerating characteristics*/

****************************************************************************
* #3 Collapse Geographic Characteristic Data (State vs. Puma) X (Household vs. Individual) X (18+, 18+ in LF, 18+ Full-Time)
****************************************************************************
local geo = "czone"
local switch = "CZone"

foreach type in "hh" "per" {													//Collapse household and individual variables separately, weighting appropriately
	foreach restr2 in "" "& inlist(empstat,1,2)" "& full_time==1" {					//Create 3 samples, either all 18+, 18+ in LF, or 18+ full-time employed
		preserve																		//Preserve full dataset
		drop if missing(`geo')															//Drop if no locational data
		collapse (mean) ``type'_vars' (rawsum) `type'wt `type'wt_cz [aw=`type'wt_cz] if age>=18 `restr2', by(`geo' year)	//Collapse
		local file_nm = "`type'" + cond("`restr2'"=="","_all", ///
		  cond("`restr2'"=="& inlist(empstat,1,2)","_lf", ///
		  cond("`restr2'"=="& full_time==1","_ft","_error")))
		tempfile `file_nm'
		save ``file_nm''																//Save collapsed version as temp file, we'll merge within geography together in next step
		restore																			//Return to full dataset to collapse again
		}
	}


****************************************************************************
* #4 Combine Collapsed Characteristic Files within a Geography (Across Samples)
****************************************************************************
preserve																		//Preserve full dataset
use `hh_all', clear																//Start with "all" (18+) household collapsed data
merge 1:1 year `geo' using `per_all', nogen										//Merge on all individual data
foreach var of varlist `hh_vars' `per_vars' perwt hhwt perwt_cz hhwt_cz {
	ren `var' `var'_all 														//Specify sample considered as suffix
	label var `var'_all "``var'' (All 18+)"										//Label as precollapsed label (saved above) plus sample description
	}

merge 1:1 year `geo' using `hh_ft', nogen										//Merge on household full-time data
merge 1:1 year `geo' using `per_ft', nogen										//Merge on individual full-time data
foreach var of varlist `hh_vars' `per_vars' perwt hhwt perwt_cz hhwt_cz {
	ren `var' `var'_ft															//Specify sample considered as suffix
	label var `var'_ft "``var''"												//Label as precollapsed label (saved above), full-time sample is usually the default
	}

merge 1:1 year `geo' using `hh_lf', nogen										//Merge on household labor-force data
merge 1:1 year `geo' using `per_lf', nogen										//Merge on individual labor-force data
foreach var of varlist `hh_vars' `per_vars' perwt hhwt perwt_cz hhwt_cz {
	ren `var' `var'_lf															//Specify sample considered as suffix
	label var `var'_lf "``var'' (All 18+ and in LF)"							//Label as precollapsed label (saved above) plus sample description
	}

***Save Characteristics Dataset
sort `geo' year
tsset `geo' year, delta(`delta')
order `geo' year, first
note: Created by bar01_collapse_chars_shares.do / TS
compress
datasignature set, reset

save "${main}/raw/Characteristics_CZone", replace							//Final characteristics dataset saved

restore																			//Return to full dataset

****************************************************************************
* #5 Collapse to Long Version of Industry Shares (State vs. Puma) X (1, 2, or 3 digit industry)
****************************************************************************
local  ind_digits = 3
preserve																		//Preserve full dataset
drop if missing(`geo')															//Drop if no locational data
egen double `geo'_ind`ind_digits' = group(`geo' ind`ind_digits')				//Location-Industry groupings

collapse (sum)  indwt = perwt_cz (firstnm) `geo' ind`ind_digits' if age>=18 & full_time==1, by(`geo'_ind`ind_digits' year) //Collapse to summed weights by Industry-Location-Year, using only 18+ full-time individuals
egen `geo'wt = total(indwt), by(year `geo')								//Location-Year totals (across industries)
gen sh_ind_ = indwt/`geo'wt										//Share of employment in an industry by Location-Year
egen natindwt = total(indwt), by(year ind`ind_digits')							//Industry-Year totals (across locations)

sort `geo'_ind`ind_digits' year
tsset `geo'_ind`ind_digits' year, delta(10)

replace natindwt = natindwt - indwt 	
gen nat_empl_ind_ = ((F.natindwt-natindwt)/natindwt)/(10)
//Save long version of industry shares, to recover after constructing bartik instruments
save "${main}/raw/shares_long_ind`ind_digits'_`geo'", replace	

restore
