clear
clear matrix
set more off


use ../data/input_card.dta

local controls logsize80 coll80 nres80 ires80 mfg80

/*
foreach var in `controls'{
	summ `var'
	replace `var' = `var'/r(sd)
	summ `var'
	disp("One done")
}
*/

foreach x of varlist `controls' {
	replace `x' = `x' / 10000000
	}

eststo m1: reg shric1 `controls' [aweight = round(count90)]
est store m1, title(Mexico)

eststo m2: reg shric2 `controls' [aweight = round(count90)]
est store m2, title(Philippines)

eststo m3: reg shric5 `controls' [aweight = round(count90)]
est store m3, title(El Salvador)

eststo m4: reg shric6 `controls' [aweight = round(count90)]
est store m4, title(China)

eststo m5: reg shric7 `controls' [aweight = round(count90)]
est store m5, title(Cuba)

eststo m6: reg shric31 `controls' [aweight = round(count90)]
est store m6, title(West Europe & others)


foreach x of varlist `controls' {
	replace `x' = `x' * 10000000
	}

eststo m7: reg hsiv `controls'  [aweight = round(count90)]
est store m7, title(Bartik - High School)

eststo m8: reg colliv `controls'  [aweight = round(count90)]
est store m8, title(Bartik - College)


esttab using ../results/card_characteristics.tex, 	drop(_cons) b(3) not se replace nostar booktabs ///
	stats(pop_weight r2 N , fmt(0 2 0) labels("Population Weighted" `"$ R^2$"' "N")) label ///
	nonumbers compress collabels(none) nogaps									//Write regression output to LaTeX
