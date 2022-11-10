******************************************************************
*** SOEP Statistics
*** Create p_data
******************************************************************

clear all
set more off
capture log close

* Install soeptools
net install soeptools, replace from(http://ddionrails.github.io/soeptools/)

*** Define paths

global data "\\hume\rdc-prod\distribution\soep-core\soep.v37\eu\Stata\"
global save "\\hume\soep-transfer\Statistics\"

* Load and merge datasets
use pid hid syear netto pop corigin phrf sex migback syear sampreg gebjahr germborn migback using ${data}ppathl.dta, clear

merge 1:1 pid syear using ${data}pl.dta, nogen keep (master match) /// 
          keepusing (plb0036_h plb0037_h plb0050 plb0195_h plb0196_h plb0197 plb0218 plb0219 plb0241_v2 plb0158 pld0043 /// 
		pld0044 pld0045 pld0047 ple0004 ple0005 ple0006 ple0007 ple0008 ple0009 ple0011  /// 
		ple0012 ple0013 ple0014 ple0015 ple0016 ple0017 ple0018 ple0019 ple0020 ple0021  /// 
		ple0022 ple0024 ple0040 ple0041 ple0044_h ple0053 ple0055 ple0081_h  /// 
		ple0097 ple0098_v5 ple0128_h ple0162 plh0012_h plh0032 plh0033 plh0034  /// 
		plh0035 plh0036 plh0037 plh0038 plh0039 plh0040 plh0042 /// 
		plh0105 plh0106 plh0107 plh0108 plh0109 plh0110 plh0111 plh0112 plh0162  /// 
		plh0164 plh0171 plh0172 plh0173 plh0174 plh0175 plh0176 plh0177 plh0178   ///
		plh0179 plh0180 plh0181 plh0182 plh0183 plh0184 plh0185 plh0186 plh0187 plh0188  /// 
		plh0189 plh0190 plh0191 plh0192 plh0193 plh0194 plh0195 plh0196 plh0204_h   /// 
		plh0206i01 plh0206i02 plh0206i03 plh0206i04 plh0206i05 plh0206i06 plh0212 plh0213 /// 
		plh0214 plh0215 plh0216 plh0217 plh0218 plh0219 plh0220 plh0221 plh0222 plh0223  ///
		plh0224 plh0225 plh0226 plh0258_h pli0059 pli0080 pli0081 pli0082 pli0083 pli0089 pli0091_h   /// 
		pli0092_h pli0093_h pli0095_h pli0096_h pli0097_h pli0098_h pli0165  /// 
		plj0014_v3 plj0046 plj0047 plj0587 plj0588 plj0589  ///
		  )

merge 1:1 pid syear using ${data}pgen.dta, nogen keep (master match)  keepusing ( ///
		pgcasmin pgemplst  pgfamstd pgisced97 pglabgro pglabnet pgnation pgoeffd pgtatzeit ///
		pgvebzeit pgpsbil pgstib pglfs pgoeffd pgisco88 pgisco08) 

merge 1:1 pid syear using ${data}pequiv.dta, nogen keep (master match) keepusing (m11104 d11101 /// 
		d11106 d11107 d11109 e11102 e11103 h11101 i11101 i11102 i11103 i11106 ///
		i11107 m11125 m11126 y11101)
		
merge m:1 hid syear using ${data}hgen.dta, nogen keep (1 3) keepusing (hgi1hinc)

merge m:1 hid syear using ${data}hpathl.dta, nogen keep(1 3) keepusing(hhrf)

merge m:1 hid syear using ${data}hbrutto.dta, nogen keep (1 3) keepusing (bula_h hhgr regtyp)


*** Define Population
* Keep observations with valid interview
drop if netto>19

* Keep observations with weighting factor
drop if phrf==0

* keep only private households
keep if inlist(pop,1,2)


*** Edit variables
* recode health variables
recode ple0011 ple0012 ple0013 ple0014 ple0015 ple0016 ple0017 ple0018 ple0019 ple0020 ple0021 ple0022 ple0024 ple0044_h  (-2 = 2)
recode plb0196_h (2 = .) if inlist(syear, 1984, 2001)
recode pgfamstd (6 8= 2) (7 = 1)

* Party affiliation
gen party=plh0012_h
recode party (-5 -4 -1 9 10 11 12 14 15 16 17 18 19 20 21 22 23 24 25 26 30 31=.) (-2 = 0) (1 = 1) (2/3 13=2) (4=3) (5=4) (6=5) (7=6) (27=7) (8=8)

* Missings to systemmissings NA
mvdecode _all, mv(-1/-8)

* Bildungsniveau: Zusammenfassung von pgcasmin
gen bildungsniveau=pgcasmin
recode bildungsniveau (0/1 = 1) (2/3=2) (4/5=3) (6/7=4) (8/9=5)

* Federal States
recode bula_h (10 = 7) // Saarland to Rheinland-Pfalz/Saarland

* age groups
gen age= syear-gebjahr if gebjahr>=0

* Keep adult observations
drop if age==.
drop if age<=16

* Age groups
gen age_gr=age
recode age_gr (17/29=1) (30/45=2) (46/65=3) (66/max=4)

* years in job
gen years_injob =  syear - plb0036_h if syear >= plb0036_h & (age >= (syear - plb0036_h))

* Befristung
recode plb0037_h (3 4 = .)
 
* Employment status
gen erwst=pgemplst
recode erwst (3 4 = 6) 

* bmi Index
gen bmi = round(ple0007/(ple0006/100)^2)

* Delete observations for 1984 to get consistent data: active sports, help with friends, clubs, parties
foreach var of varlist  pli0092_h pli0095_h pli0096_h pli0097_h pli0098_h {
	recode `var' (6 7 8 =.) if syear==1984
}

*** Big Five Personality Traits
* Recode negative Traits
foreach var of varlist  plh0218 plh0223 plh0214 plh0226 {
	gen `var'_new = `var'
	recode `var'_new (1=7) (2=6) (3=5) (4=4) (5=3) (6=2) (7=1)
}

egen neur = rowmean(plh0216 plh0221 plh0226_new)
egen open = rowmean(plh0215 plh0220 plh0225)
egen extr = rowmean(plh0213 plh0219 plh0223_new) 
egen agre = rowmean(plh0214_new plh0217 plh0224)
egen conc = rowmean(plh0212 plh0218_new plh0222)


*** Einkommen
* OECD Nettoäquivalenzeinkommen
gen oecdweight = 1 + (hhgr - h11101 - 1)*0.5 + (h11101*0.3)
gen hinc_eq = hgi1hinc/oecdweight

* Einkommen in Quintilen (1= einkommensschwächstes Quintil, 5=einkommensstärkstes Quintil)
sumdist hinc_eq [w=round(hhrf)], n(5) qgp(quintil_oecd)


*** Inkonsistenzen in Daten bereinigen
recode plh0183 (-8/10 = .) if syear==2012 // Lebenszufriedenheit in 5 Jahren 2012, geringe Fallzahl
recode plh0105 plh0106 plh0107 plh0108 plh0109 plh0110 plh0111 plh0112 (-8/4 = .) if syear==2010 // Wichtigkeitsvariablen, Werte für 2010 geringe Fallzahlen
recode plh0181 (-8/10 = .) if syear==2012 | syear==2013 // Zufriedenheit Freundes- / Bekanntenkreis
recode plb0218 (-8/5 = .) if syear==2010 | syear==2012 // Arbeit am Samstag
recode plb0219 (-8/5 = .) if syear==2010 | syear==2012 // Arbeit am Sonntag

* drop variables
drop netto age plh0012_h gebjahr pgpsbil pgemplst plb0036_h plh0226 plh0226_new plh0223 plh0223_new plh0214 plh0214_new /// 
     plh0216 plh0221 plh0215 plh0220 plh0225 plh0213 plh0219 plh0214_new plh0217 plh0224 plh0218 ///
	 plh0212 plh0218_new plh0222 d11106 d11107 h11101 pop gebjahr plh0258_h pglfs ///
	 pgemplst pgstib pgisco88 pgisco08 pgoeffd pgisced97 pgcasmin pgpsbil hhgr ///
	 d11101 hid i11101 i11102 i11103 i11106 i11107 pgnation plj0014_v3 oecdweight hgi1hinc hinc_eq

* save dataset
save ${save}data\preparation\p_pre-data.dta, replace


***
* Leerdatensatz erstellen + meta data mergen

use ${save}data\preparation\p_pre-data.dta, clear
global meta ${save}metadata\p\


*** Label dataset: Create empty dataset with labels
soepinitdta, mdpath(${meta}) /// 
			 study(soep-core) /// 
			 version(v37) /// 
			 verbose

save ${save}data\preparation\p_data_lab.dta, replace

append using ${save}data\preparation\p_pre-data.dta
qui compress

save ${save}data\p_statistics.dta, replace
