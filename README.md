

# Summary

This code replicates the figures and tables from Goldsmith-Pinkham,
Sorkin and Swift (2019). The main file for rerunning the code can be
run using master.do. The individual do-files are outlined below. The
do-files use finalized datasets, which are constructed from various
data sources, outlined below. 

* The canonical Bartik analysis (BAR) is replicated using data from
  IPUMS and uses cross-walks generously provided by David Dorn on his
  [website](https://www.ddorn.net/data.htm).
  
* The China shock analysis (ADH) is replicated using a combination of data sources:
	* the replication file from Autor, Dorn and Hanson (2013),
	* data generously provided by Borusyak, Hull and Jaravel (2019),
	* and data generously provided by  Adao, Kolesar and Morales (2019).
	
* The Card immigration analysis (CARD) is replicated using replication code provided by David Card from Card (2009) and data from ICPSR
	
# Code process

The `master.do` file executes the following code:

1. `do make_BAR_table.do` constructs Table 3 from the paper and uses `input_BAR2.dta`, the finalized Bartik analysis file. [NOTE: This code is slow due to bootstrapping.]
2. `make_rotemberg_summary_BAR.do` constructs Table 1, Figure 1, and Appendix Figure A1. It uses `input_BAR2.dta`, the finalized Bartik analysis file.
3. `make_char_table_BAR.do` constructs Table 2. It uses `input_BAR2.dta`, the finalized Bartik analysis file.
4. `do make_ADH_table.do` constructs Table 6 from the paper and uses `ADHdata_AKM.csv`, `Lshares.dta` and `shocks.dta`. [NOTE: This code is slow due to bootstrapping.]
5. `make_rotemberg_summary_ADH.do` constructs Table 4, Figure 3 and Appendix Figure A2. It uses uses `ADHdata_AKM.csv`, `Lshares.dta` and `shocks.dta`. 
6. `make_pretrends_ADH.do` makes Figure 2 and Appendix Figure A4. It uses `workfile_china_preperiod.dta`, `ADHdata_AKM.csv`, `Lshares.dta` and `shocks.dta`. 
6. `make_char_table_ADH.do` constructs Table 5. It uses uses `ADHdata_AKM.csv`, `Lshares.dta` and `shocks.dta`. 
7. `make_CARD_table_hs.do` and `make_CARD_table_college.do` make Table 9. They use `input_card.dta`.
8. `make_rotemberg_summary_CARD_hs.do` and `make_rotemberg_summary_CARD_college.do` make Table 7, Figure 6 and Appendix Figure A3. They use `input_card.dta`.
9. `make_char_table_CARD.do` makes Table 8. It uses `input_card.dta`.
10. `make_pretrends_CARD.do` makes Figures 4 and 5. It uses `input_card.dta`.


# Data construction for canonical Bartik

IPUMS data cannot be posted. However, the following steps below allow researchers to recreate `input_BAR2.dta` themselves.

The file is created using two do-files:

1. `create_bartik_data.do`, which creates `Characteristics_CZone.dta` and  `shares_long_ind3_czone.dta`, and takes nine inputs:	
	1. `IPUMS_data.dta`
	2. `IPUMS_ind1990.dta`
	2. `IPUMS_geo.dta`
	4. `IPUMS_bpl.dta`
	5. `cw_ctygrp1980_czone_corr.dta`
	6. `cw_puma1990_czone.dta`
	7. `cw_puma2000_czone.dta`
	8. `czone_list.dta`
2. `make_input_bar.do`, which creates `input_BAR2.dta` and takes two inputs:
	1. `Characteristics_CZone.dta`
	2. `shares_long_ind3_czone.dta`


These files are described in further detail below:

## `IPUMS_data.dta`

Our large base dataset downloaded from IPUMS here:
https://usa.ipums.org/usa/data.shtml Note that of the 2009-2011 ACS
samples were pooled to form the 2010 sample.

### Samples: 

1. 1980 5% state; 
2. 1990 5%; 
3. 2000 5%; 
4. 2009 ACS; 2010 ACS; 2011 ACS

### Variables: 

`year; datanum; serial; hhwt; statefip; conspuma; 
cpuma0010; gq; ownershp; ownershpd; mortgage; mortgag2; rent; rentgrs;
hhincome; foodstmp; valueh; nfams; nsubfam; ncouples; nmothers;
nfathers; multgen; multgend; pernum; perwt; famsize; nchild; nchlt5;
famunit; eldch; relate; related; sex; age; marst; birthyr; race;
raced; hispan; hispand; ancestr1; ancestr1d; ancestr2; ancestr2d;
citizen; yrsusa2; speakeng; racesing; racesingd; school; educ; educd;
gradeatt; gradeattd; schltype; empstat; empstatd; labforce; occ; ind;
classwkr ; classwkrd; wkswork2; uhrswork; wrklstwk; absent; looking;
availble; wrkrecal; workedyr; inctot; ftotinc: incwage; incbus00;
incss; incwelfr; incinvst; incretir; incsupp; incother; incearn;
poverty; occscore; sei; hwsei; presgl; prent; erscor90; edscor90;
npboss90; migrate5; migrate5d; migrate1; migrate1d; migplac5;
migplac1; movedin; vetstat; vetstatd; pwstate2; trantime`

## `IPUMS_ind1990.dta`

An additional dataset of 1990 standardized industries to merge onto
the main dataset, again downloaded here:
https://usa.ipums.org/usa/data.shtml Note
that in the ACS samples, 2009-2011 were pooled to form the 2010
sample. Merging with the main dataset occurred by matching
year-serial-pernum.

### Samples: 

1. 1980 5% state; 
2. 1990 5%; 
3. 2000 5%; 
4. 2009 ACS; 2010 ACS; 2011 ACS

### Variables:

`year; datanum; serial; hhwt; gq; pernum; perwt; ind1990`

### `IPUMS_geo.dta`

An additional dataset of geographies to merge onto
the main dataset, again downloaded here:
https://usa.ipums.org/usa/data.shtml

### Samples: 

1. 1980 5% state; 
2. 1990 5%; 
3. 2000 5%; 
4. 2009 ACS; 2010 ACS; 2011 ACS


### Variables:

`year; datanum; serial; hhwt; gq; pernum; perwt; county; countyfips; cntygp98; puma`


### `IPUMS_bpl.dta`

An additional dataset of birthplace to merge onto
the main dataset, again downloaded here:
https://usa.ipums.org/usa/data.shtml

### Samples: 

1. 1980 5% state; 
2. 1990 5%; 
3. 2000 5%; 
4. 2009 ACS; 2010 ACS; 2011 ACS


### Variables:

`year; datanum; serial; hhwt; gq; pernum; perwt; bpl`


# Data construction for Card (2009)

TO BE FILLED IN

