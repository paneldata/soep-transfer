******************************************************************
*** SOEP Statistics
*** Create h_data
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
use hid syear hhrf hhrf1 sampreg hsample hpop using ${data}hpathl.dta, clear

merge m:1 hid syear using ${data}hgen.dta, nogen keep(1 3) keepusing (hgelectr hgeqpgar ///
		hgeqpinsul hgeqpmglass hgeqpsol hgeqpter hgheat hghinc hgi1hinc hgowner hgrent ///
		hgroom hgsize hgtyp1hh hgelectrinfo hgheatinfo hgutilinfo hgtyp1hh hgtyp2hh)
merge m:1 hid syear using ${data}hl.dta, nogen keep(1 3) keepusing (hlc0043 hlc0052 ///
		hlc0061_h hlc0080_h hlc0083_h hlc0119_h hlc0178 hlc0180 hlc0182 hlf0036 hlf0071_h ///
		hlf0151 hlf0178_h hlf0180 hlf0186 hlf0188  hlf0192 hlf0197 hlf0261 hlf0291 hlf0436_h ///
		hlf0633 hlf0613 hlf0631 hlf0632 hlf0084 hlf0090_h hlf0091_h hlf0435_h ///
		hlf0001_h hlf0019_h hlf0021_h hlf0094)
merge m:1 hid syear using ${data}hbrutto.dta, nogen keep(1 3) keepusing (bula_h hhgr regtyp)


* Define population
keep if inlist(hpop,1,2)
drop if hhrf == 0
drop if hgowner == 5


*** Edit variables
recode bula_h (10 = 7) // Saarland to Rheinland-Pfalz/Saarland

*Missings to systemmissings NA
mvdecode _all, mv(-1/-8)

* Eigentümer / Mieter
gen eigentum=hgowner
recode eigentum (1=1) (2 3 4 = 2)

* Haushaltstyp
gen hhtyp=hgtyp1hh
recode hhtyp (4 5 6=4) (7 8 =5)

*** Gemeinsame Strom-, Heiz- und Umlagekostenvariablen generieren:

* Stromkosten für Mieter: hgelectr, für Eigentümer: hlf0084 (Frage an alle, aber nur Eigentümer in Variable enthalten) 
gen strom=hgelectr
replace strom=hlf0084/12 if strom==.
recode strom(.=0) if hgelectrinfo==3

* Heiz- und Warmwasserkosten für Mieter: hgfheat, für Eigentümer: hlf0090_h (Frage an alle, aber nur Eigentümer in Variable enthalten) 
gen heizen=hgheat
replace heizen=hlf0090_h/12 if heizen==.
recode heizen (.=0) if hgheatinfo==3

* Umlagekosten für Mieter: hgutil, für Eigentümer: hlf0091_h (Frage an alle, aber nur Eigentümer in Variable enthalten) 
gen umlage=hgutil
replace umlage=hlf0091_h/12 if umlage==.
recode umlage(.=0) if hgutilinfo==3

* Ausgaben für Lebensmittel
gen essen=hlf0436_h
replace essen=hlf0435_h*13/3 if essen==.

* Beurteilung Belastung durch Wohnkosten für Mieter und Eigentümer zusammenfassen: hlf0632 hlf0633
gen wohnk = hlf0632 
replace wohnk=hlf0633 if wohnk==.

* Datenharmonisierung
recode strom (0/690 = .) if syear==2015 // Stromkosten Info für Eigentümer fehlt 2015
recode heizen (0/800 = .) if syear==2015 // Heizkostn Info für Eigentümer fehlt 2015

* drop variables
drop	hpop hgi1hinc hgelectrinfo hgutilinfo hgheatinfo hgelectr ///
		hgheat hgtyp1hh hgtyp2hh hlc0043 hlf0084 hlf0090_h hlf0091_h hlf0435_h hlf0436_h ///
		hghinc hsample hgowner 

* save dataset
save ${save}data\preparation\h_pre-data.dta, replace


*** Leerdatensatz erstellen
use ${save}data\preparation\h_pre-data.dta, clear

global meta ${save}metadata\h\


** Label dataset
* Create empty dataset with labels
soepinitdta, mdpath(${meta}) /// 
			 study(soep-core) /// 
			 version(v37) /// 
			 verbose
		 
save ${save}data\preparation\h_data_lab.dta, replace
append using ${save}data\preparation\h_pre-data.dta

qui compress

save ${save}\data\h_statistics.dta, replace
