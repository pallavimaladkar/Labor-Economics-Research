global origin "~/Dropbox/ECON580-2023DB"	
cd "~/Dropbox/ECON 580 Group"

*Pallavi Maladkar

capture log close
log using "580_Project_Pallavi_Silpitha_Kevin", replace

use "~/Dropbox/ECON 580 Group/ECON580_cps_covid2.dta", clear





*******************************************************************************
*                            CLEANING VARIABLES
*******************************************************************************


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
recode uhrsworkt 997=.
sum uhrsworkt, d





*******************************************************************************
*                            SUMMARY STATISTICS
*******************************************************************************

asdoc sum Pst earnweek haschild5 uhrsworkt nchild essenocc female married, label

asdoc tab ethnicity

asdoc tab edattain

asdoc tab Pst




*******************************************************************************
*                                   MODELS
*******************************************************************************
global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"
sum $Z

// preliminary models
reg earnweek haschild5 $Z, robust
outreg2 using model.doc, replace addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Basic Model)

reg earnweek haschild5##female haschild5##married $Z, robust
outreg2 using model.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(idk Model)



// DID
reg earnweek i.Pst $Z, robust
outreg2 using DID.doc, replace addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(DID Model)



// triple differences
reg earnweek i.Pst##haschild5 $Z, robust
outreg2 using DID.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Triple Differences Model)



// group balancing
global D "nchild i.ethnicity essenocc i.edattain"

probit haschild5 $D i.statefip if Pst==2 	// note no time FEs
predict pscore 													
gen ipw=1/(1-pscore) if haschild5==0
replace ipw=1/pscore if haschild5==1
label var pscore "Propensity score"
label var ipw "Inverse Propensity Weight"


ssc install psmatch2
ssc install ttable2
ssc install asdoc

pstest $D if Pst==2, treat(haschild5) raw
outreg2 using pvals.doc, replace
// ttable2 $D if Pst==2, by(haschild5)	
ttable2 nchild essenocc if Pst==2, by(haschild5)
// asdoc pstest $D if Pst==2, replace treat(haschild5) raw


// Using IPW, calculate adjusted group differences and test if these differences are statistically significant
// foreach v in $D {
// 	qui reg `v' haschild5 if Pst==2 [pw=ipw]
// // 	outreg2 using summary.xls, append ctitle(`v'_IPW) bdec(3) nocons
// 	outreg2 using IPW.doc, append ctitle(`v'_IPW) bdec(3) nocons
// }

reg earnweek i.Pst##haschild5 $Z, robust
outreg2 using DID_ipw.doc, replace cttop(Without IPW) addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label

reg earnweek i.Pst##i.haschild5 $Z if Pst==2 [pw=ipw], robust
outreg2 using DID_ipw.doc, append cttop(With IPW) bdec(3) nocons addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label













*******************************************************************************
*                        INDIVIDUAL PROJECT QUESTION
*******************************************************************************






// ***** MALE VS FEMALE *****

// FEMALE PARENTS

global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"
sum $Z
reg earnweek i.Pst $Z if female == 1, robust
outreg2 using DID_FvM.doc, replace addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Female, DID Model)


// triple differences
reg earnweek i.Pst##haschild5 $Z if female == 1, robust
outreg2 using DID_FvM.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Female, Triple Differences Model)




// MALE PARENTS

global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"
sum $Z
reg earnweek i.Pst $Z if female == 0, robust
outreg2 using DID_FvM.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Male, DID Model)


// triple differences
reg earnweek i.Pst##haschild5 $Z if married == 0, robust
outreg2 using DID_FvM.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Male, Triple Differences Model)









// // SINGLE VS MARRIED PARENTS
//
//
// // DID
// global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"
// sum $Z
// reg earnweek i.Pst $Z if married == 0, robust
// outreg2 using DID_single.doc, replace addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(DID Model)
//
//
// // triple differences
// reg earnweek i.Pst##haschild5 $Z if married == 0, robust
// outreg2 using DID_single.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Triple Differences Model)
//
//
//
//
// // MARRIED PARENTS
//
// global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"
// sum $Z
// reg earnweek i.Pst $Z if married == 1, robust
// outreg2 using DID_married.doc, replace addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(DID Model)
//
//
// // triple differences
// reg earnweek i.Pst##haschild5 $Z if married == 1, robust
// outreg2 using DID_married.doc, append addtext(State FE, Yes, Month FE, Yes) drop(i.statefip i.timeline) label ctitle(Triple Differences Model)







*******************************************************************************
*                               VISUALIZATIONS
*******************************************************************************


// for all
reg earnweek i.Pst##i.haschild5 $Z i.statefip i.month, robust
margins, at(Pst=(0 1 2) haschild5=(0 1))   /*predicted Prob(f.Unemp=1) by group before and after the policy*/
marginsplot, ytitle("Predicted Weekly Earnings") title("Predicted Weekly Earnings by Policy Stage and Child Presence") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) label(1 "Does not have a child under 5, Closed/No Policy") ///
label(2 "Does not have a child under 5, Restricted") ///
label(3 "Does not have a child under 5, Reopened") ///
label(4 "Has a child under the age of 5, Closed/No Policy") ///
label(5 "Has a child under the age of 5, Restricted") ///
label(6 "Has a child under the age of 5, Reopened"))




// for women

reg earnweek i.Pst##i.haschild5 $Z i.statefip i.month if female == 1, robust
margins, at(Pst=(0 1 2) haschild5=(0 1))   /*predicted Prob(f.Unemp=1) by group before and after the policy*/
marginsplot, ytitle("Predicted Weekly Earnings") title("Predicted Weekly Earnings by Policy Stage for Women") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) label(1 "Does not have a child under 5, Closed/No Policy") ///
label(2 "Does not have a child under 5, Restricted") ///
label(3 "Does not have a child under 5, Reopened") ///
label(4 "Has a child under the age of 5, Closed/No Policy") ///
label(5 "Has a child under the age of 5, Restricted") ///
label(6 "Has a child under the age of 5, Reopened"))


// for men

reg earnweek i.Pst##i.haschild5 $Z i.statefip i.month if female == 0, robust
margins, at(Pst=(0 1 2) haschild5=(0 1))   /*predicted Prob(f.Unemp=1) by group before and after the policy*/
marginsplot, ytitle("Predicted Weekly Earnings") title("Predicted Weekly Earnings by Policy Stage for Men") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) label(1 "Does not have a child under 5, Closed/No Policy") ///
label(2 "Does not have a child under 5, Restricted") ///
label(3 "Does not have a child under 5, Reopened") ///
label(4 "Has a child under the age of 5, Closed/No Policy") ///
label(5 "Has a child under the age of 5, Restricted") ///
label(6 "Has a child under the age of 5, Reopened"))







*******************************************************************************
*                         ADVANCED MODELS - INDIVIDUAL
*******************************************************************************



// ******* TOBIT MODEL *******

global Z "nchild i.ethnicity essenocc i.edattain i.statefip i.timeline"

// FEMALE PARENTS

// normal regression
// reg uhrsworkt i.Pst##haschild5 $Z if female == 1, robust
// outreg2 using tobit_mw.doc, replace bdec(3) cttop(Regression, Women) nocons addtext(State FE, Yes, Week FE, Yes) drop(i.statefip i.timeline) label

// tobit model
tobit uhrsworkt i.Pst##haschild5 $Z if female == 1, ll(0) vce(robust)
outreg2 using tobit_mw.doc, replace bdec(3) cttop(Tobit, Women) nocons addtext(State FE, Yes, Week FE, Yes) drop(i.statefip i.timeline) label

margins, at(Pst=(0 1 2) haschild5=(0 1))   /*predicted Prob(f.Unemp=1) by group before and after the policy*/
marginsplot, ytitle("Predicted Hours Worked") title("Predicted Hours Worked by Policy Stage for Women") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) label(1 "Does not have a child under 5, Closed/No Policy") ///
label(2 "Does not have a child under 5, Restricted") ///
label(3 "Does not have a child under 5, Reopened") ///
label(4 "Has a child under the age of 5, Closed/No Policy") ///
label(5 "Has a child under the age of 5, Restricted") ///
label(6 "Has a child under the age of 5, Reopened"))


// MALE PARENTS

// normal regression
// reg uhrsworkt i.Pst##haschild5 $Z if female == 0, robust

// tobit model
tobit uhrsworkt i.Pst##haschild5 $Z if female == 0, ll(0) vce(robust)
outreg2 using tobit_mw.doc, append bdec(3) cttop(Tobit, Men) nocons addtext(State FE, Yes, Week FE, Yes) drop(i.statefip i.timeline) label

margins, at(Pst=(0 1 2) haschild5=(0 1))   /*predicted Prob(f.Unemp=1) by group before and after the policy*/
marginsplot, ytitle("Predicted Hours Worked") title("Predicted Hours Worked by Policy Stage for Men") graphregion(fcolor(white)) ciopts(lwidth(vthin)) legend(region(color(white)) label(1 "Does not have a child under 5, Closed/No Policy") ///
label(2 "Does not have a child under 5, Restricted") ///
label(3 "Does not have a child under 5, Reopened") ///
label(4 "Has a child under the age of 5, Closed/No Policy") ///
label(5 "Has a child under the age of 5, Restricted") ///
label(6 "Has a child under the age of 5, Reopened"))




// ******* HECKMAN MODEL *******

// Exclusion Variables that supposedly affect the participation equation, but not the outcome variable
global R "married schlcoll diffphys diffany"
// if person is married
// if person is currently in school
// physical difficulty
// any difficulty

// FEMALE

heckman uhrsworkt i.Pst##haschild5 $Z if female == 1, select(employed=$R $Z) twostep
outreg2 using heckman_mw.doc, replace ctitle(2step, Women) bdec(3) nocons addtext(State FE, Yes, Week FE, Yes) drop(i.statefip i.timeline) label


// MALE
heckman uhrsworkt i.Pst##haschild5 $Z if female == 0, select(employed=$R $Z) twostep
outreg2 using heckman_mw.doc, replace ctitle(2step, Men) bdec(3) nocons addtext(State FE, Yes, Week FE, Yes) drop(i.statefip i.timeline) label


log close
translate 580_Project_Pallavi_Silpitha_Kevin.smcl 580_Project_Pallavi_Silpitha_Kevin.pdf




