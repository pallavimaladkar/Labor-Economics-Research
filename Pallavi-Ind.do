global origin  "~/Dropbox/ECON580-2023DB" 		
cd "~/Dropbox/ECON 580 Group"

*************************************************************
*		Child care reopening and parents' labor supply
*************************************************************

/*
// Shorten file size
use "~/Dropbox/CPS-shared/ECON580_cps_covid", clear

keep if female==1 & year==2020

label define childage 0 "Age 0-1" 1 "Age 2-5" 2 "Age 6-17" 3 "No children 18+"
recode yngch 0/1=0 2/5=1 6/17=2 18/100=3 99=., gen(childage)
replace childage=3 if nchild==0
label values childage childage
label var childage "Child's age categories"

gen group=0 if childage==0 | childage==3
replace group=1 if childage==1
label define group 0 "Control group" 1 "Treated: Age 2-5"
label values group group
label var group "Child's age categories"

save "~/Dropbox/ECON580-2023DB/ECON580_cps_covid2", replace
*/

use "~/Dropbox/ECON 580 Group/ECON580_cps_covid2new", clear






*******************************************************************************
*                            CLEANING VARIABLES
*******************************************************************************


tab childage group, mis


codebook ccc_closure

gen Pst = ccc_closure
recode Pst  1=0 2=1 3=2
label define Pstlabel 0 "No policy or CCC closed" 1 "CCC restricted" 2 "Post-policy"
label values Pst Pstlabel
// 0 = no policy or closed
// 1 = restricted
// 2 = reopened

clonevar timeline = month
replace timeline = timeline + 12 if year == 2021

// earnweek
sum earnweek, d
_pctile earnweek, p(0.5 99.5)
return list
replace earnweek =. if earnweek<r(r1) | earnweek>r(r2)
sum earnweek, d

// uhrsworkt
sum uhrsworkt, d
recode uhrsworkt 997=. // 0=.
sum uhrsworkt, d




*************************************************************
	*** Triple difference
*************************************************************
	
	
// global Z "c.age##c.age i.race hispan i.educ married diffany"
// global FE "i.statefip i.date"
// reg employed i.ccc_closure##group $Z $FE, robust

global Z "nchild i.ethnicity essenocc i.edattain"
global FE "i.statefip i.timeline"
reg employed i.Pst##group $Z $FE, robust


*************************************************************
	*** Multinomial logit
*************************************************************

// HOURS WORKED - CATEGORICAL

// here is an example of how to create a categorical variable with hours
gen hourcat=1 if employed==0
replace hourcat=2 if employed==1 & uhrsworkt<36
replace hourcat=3 if employed==1 & uhrsworkt>35 & uhrsworkt<.
label define hourcat 1 "Not working" 2 "Working part-time" 3 "Working full-time"
label values hourcat hourcat
label var hourcat "Categories of hours of work"
tab hourcat
asdoc tab hourcat
asdoc tab uhrsworkt

gen s=1 if month>4



// WITH Pst

mlogit hourcat i.Pst##group $Z $FE if s==1, base(1)
outreg2 using mlogit.doc, replace bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label

// predict outcomes and visualize estimation results
margins i.Pst#group, predict(outcome(2)) 
marginsplot, xdimension(Pst) ytitle("probability") title("Working part-time") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig1, replace)

margins i.Pst#group, predict(outcome(3)) 
marginsplot, xdimension(Pst) ytitle("probability") title("Working full-time") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig2, replace)

graph combine fig1 fig2, graphregion(fcolor(white)) ysize(4) xsize(8) name(mlogit, replace)




// WITH CCC_CLOSURE

mlogit hourcat i.ccc_closure##group $Z $FE if s==1, base(1)
outreg2 using mlogit.doc, replace bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label

// predict outcomes and visualize estimation results
margins i.ccc_closure#group, predict(outcome(2)) 
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Working part-time") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig1, replace)

margins i.ccc_closure#group, predict(outcome(3)) 
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Working full-time") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig2, replace)

graph combine fig1 fig2, graphregion(fcolor(white)) ysize(4) xsize(8) name(mlogit, replace)




// // TELEWORKING - CATEGORICAL
//
// // explore variables used in constructing the categorical variable
// tab employed covidtelew, mis
// tab month covidtelew		// teleworking is available in months 5-12
// gen s=1 if month>4
//
// // create categorical variable
// gen telewstat=1 if employed==0 & month>4
// replace telewstat=2 if employed==1 & covidtelew==0
// replace telewstat=3 if employed==1 & covidtelew==1
// label define telewstat 1 "Not working" 2 "Working in person" 3 "Working remotely"
// label values telewstat telewstat
// label var telewstat "Teleworking status"
//
// // examine constructed categorical variable
// tab telewstat if s==1, mis
// bys telewstat: sum $Z
//
// // estimate mlogit
// mlogit telewstat i.ccc_closure##group $Z $FE if s==1, base(1)
// outreg2 using mlogit.xls, replace bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label
//
// // predict outcomes and visualize estimation results
// margins i.ccc_closure#group, predict(outcome(2)) 
// marginsplot, xdimension(ccc_closure) ytitle("probability") title("Working in person") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig1, replace)
//
// margins i.ccc_closure#group, predict(outcome(3)) 
// marginsplot, xdimension(ccc_closure) ytitle("probability") title("Working remotely") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig2, replace)
//
// graph combine fig1 fig2, graphregion(fcolor(white)) ysize(4) xsize(8) name(mlogit, replace)





*************************************************************
	***  Heckprobit
*************************************************************
	
use "~/Dropbox/ECON 580 Group/ECON580_cps_covid2new", clear
gen stateid= statefip 
merge m:1 stateid using "$origin/USstate_combined_data.dta", keep(1 3) nogen keepusing(com*)
gen s=1 if month>4

// Outcome variables
note: Heckman requires one continuous outcome partially observed and one binary outcome fully observed; e.g., hours and employment
note: Heckprobit requires one binary outcome partially observed and one binary outcome fully observed, e.g., teleworking and employment

// Examine outcomes
tab employed covidtelew
tab employed covidtelew, mis

sum uhrsworkt, d
recode uhrsworkt 997=. 999=. // 0=.
sum uhrsworkt, d

// Check variables
// global Z "c.age##c.age i.race hispan i.educ married diffany"  // must be observed for all
global Z "nchild i.ethnicity essenocc i.edattain"
global FE "i.region i.date"					// replace state FEs with region FEs
global R "married schlcoll diffphys diffany"			  // must be observed for all
bys employed: sum $Z $R ccc_closure group

// estimate heckrpobit
heckprobit uhrsworkt i.ccc_closure##group $Z $FE if s==1, select(employed=i.ccc_closure##group $R $Z $FE) vce(robust)
outreg2 using heckprobit.doc, replace cttop(Heckprobit) bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label

// predict outcomes and visualize estimation results
margins i.ccc_closure#group, predict(pmargin) 
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Hours worked") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig5, replace)

margins i.ccc_closure#group, predict(psel)
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Employment") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig6, replace)

graph combine fig5 fig6, graphregion(fcolor(white)) ysize(4) xsize(8) name(heckprobit, replace)









*************************************************************
	*** Bivariate probit - requires 2 binary outcomes
*************************************************************

// create two binary outcomes
tab covidtelew // already created

gen fulltime=0 if employed==1 & uhrsworkt<36
replace fulltime=1 if employed==1 & uhrsworkt>35 & uhrsworkt<.
tab covidtelew fulltime
bys covidtelew fulltime: sum $Z

// estimate biprobit
biprobit (covidtelew i.ccc_closure##group $Z $FE) (fulltime i.ccc_closure##group $Z $FE) if s==1, vce(robust)
outreg2 using biprobit.xls, append cttop(Biprobit) bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label

// predict outcomes and visualize estimation results
margins i.ccc_closure#group, predict(pmarg1) 
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Teleworking") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig3, replace)

margins i.ccc_closure#group, predict(pmarg2)
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Working full-time") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig4, replace)

graph combine fig3 fig4, graphregion(fcolor(white)) ysize(4) xsize(8) name(biprobit, replace)


*************************************************************
	***  Heckprobit
*************************************************************
	
use "~/Dropbox/ECON580-2023DB/ECON580_cps_covid2", clear
gen stateid= statefip 
merge m:1 stateid using "$origin/USstate_combined_data.dta", keep(1 3) nogen keepusing(com*)
gen s=1 if month>4

// Outcome variables
note: Heckman requires one continuous outcome partially observed and one binary outcome fully observed; e.g., hours and employment
note: Heckprobit requires one binary outcome partially observed and one binary outcome fully observed, e.g., teleworking and employment

// Examine outcomes
tab employed covidtelew
tab employed covidtelew, mis

// Check variables
global Z "c.age##c.age i.race hispan i.educ married diffany"  // must be observed for all
global FE "i.region i.date"					// replace state FEs with region FEs
global R "com_pubtrans com_traffic"			  				  // must be observed for all
bys employed: sum $Z $R ccc_closure group

// estimate heckrpobit
heckprobit covidtelew i.ccc_closure##group $Z $FE if s==1, select(employed=i.ccc_closure##group $R $Z $FE) vce(robust)
outreg2 using heckprobit.xls, replace cttop(Heckprobit) bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop($FE) label

// predict outcomes and visualize estimation results
margins i.ccc_closure#group, predict(pmargin) 
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Teleworking") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig5, replace)

margins i.ccc_closure#group, predict(psel)
marginsplot, xdimension(ccc_closure) ytitle("probability") title("Employment") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) pos(6) row(1)) name(fig6, replace)

graph combine fig5 fig6, graphregion(fcolor(white)) ysize(4) xsize(8) name(heckprobit, replace)


*************************************************************
	***  Mediating model
*************************************************************

* Day care re-opening -> hours -> earnings

use "~/Dropbox/ECON 580 Group/ECON580_cps_covid2", clear


gen Pst = ccc_closure
recode Pst  1=0 2=1 3=2
label define Pstlabel 0 "No policy or CCC closed" 1 "CCC restricted" 2 "Post-policy"
label values Pst Pstlabel
// 0 = no policy or closed
// 1 = restricted
// 2 = reopened

clonevar timeline = month
replace timeline = timeline + 12 if year == 2021

// earnweek
sum earnweek, d
_pctile earnweek, p(0.5 99.5)
return list
replace earnweek =. if earnweek<r(r1) | earnweek>r(r2)
sum earnweek, d


// check variables
recode ahrsworkt 996/999=., gen(hours)
sum hours, d
sum earnweek, d
gen s=1 if earnweek<. & hours<.
gen lnearnweek=ln(earnweek)

reg hours i.Pst##group $Z $FE if s==1
est store hours
reg lnearnweek hours i.Pst##group $Z $FE if s==1
est store earn
suest hours earn, vce(robust)

// // direct and indirect effects of marital status on earnings
// nlcom 	(direct: [earn_mean]married) ///
// 		(indirect: [earn_mean]hours*[hours_mean]married) ///
// 		(total: [earn_mean]married+[earn_mean]hours*[hours_mean]married)

// direct and indirect effects of day care center closing on earnings
nlcom 	(direct: [earn_mean]1.Pst#1.group) ///
		(indirect: [earn_mean]hours*[hours_mean]1.Pst#1.group) ///
		(total: [earn_mean]1.Pst#1.group+[earn_mean]hours*[hours_mean]1.Pst#1.group)
		
		
		