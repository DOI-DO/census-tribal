# E. Silverman and A. Miller, Office of Policy Analysis, Department of Interior, August 2025
# Last update: 14-Apr-2026

Reference data tables for federally recognized American Indian and Alaska Native entities. 

These tables use the list of federally recognized Indian entities published in the Federal Register Notice (FRN).
As of the creation of these files, the most recent update of the FRN list occurred on 2026-01-30 (FRN20260130)
There are 577 federally recognized entities listed in the FRN20260130. This is an increase of one entity from the previous FRN20241211.
The Lumbee Tribe of North Carolina was added due to the passage of the Lumbee Fairness Act in Jan 2025, which ammended the Lumbee Act of 1956.

*NOTE* FRN20260130 includes two cases where two entities appear to be reported both alone and together:

"Native Village of Venetie Tribal Government (Arctic Village and Village of Venetie)" neid_mid = VENTGV
"Pribilof Islands Aleut Communities of St. Paul & St. George Islands (St. George Island and Saint Paul Island)" neid_mid = PRBLFC

The combined and constituent entries represent unique entities with their own unique codes for race/ethnicity and unique Native entity identifiers but share Census geographies. 

*NOTE* FRN20260130 also includes two entities that are made up of constituent entities not specified in the FRN:

"Central Council of the Tlingit & Haida Indian Tribes" neid_mid = TLNGHD, which includes of 16 FRN entities
ANGOON,"Angoon Community Association"
CHLKAT,"Chilkat Indian Village (Klukwan)"
CLKOOT,"Chilkoot Indian Association (Haines)"
CRAIGT,"Craig Tribal Association"
HDABRG,"Hydaburg Cooperative Association"
HOONAH,"Hoonah Indian Association"
KASAAN,"Organized Village of Kasaan"
KLAWCK,"Klawock Cooperative Association"
KTCHKN,"Ketchikan Indian Community"
MTLKTL,"Metlakatla Indian Community, Annette Island Reserve"
PTRSBG,"Petersburg Indian Association"
SAXMAN,"Organized Village of Saxman"
SITKAT,"Sitka Tribe of Alaska"
VLKAKE,"Organized Village of Kake"
WRNGLL,"Wrangell Cooperative Association"
YKTTLN,"Yakutat Tlingit Tribe"

"Inupiat Community of the Arctic Slope" neid_mid = INPTAS, which includes of 8 FRN entities
INPTBW,"Native Village of Barrow Inupiat Traditional Government"
ANKTVK,"Village of Anaktuvuk Pass"
ATQSUK,"Native Village of Atqasuk"
KKTOVK,"Kaktovik Village (aka Barter Island)"
NUIQST,"Native Village of Nuiqsut (aka Nooiksut)"
PNTHPE,"Native Village of Point Hope"
PNTLAY,"Native Village of Point Lay"
WAINWT,"Village of Wainwright"

################################################################
**File 1: census-tribal_ANVSA_ANRC.csv**

This file has one row for 221 Alaska Native Village Census geographies.
Census geographies come from the 2020 Census AIANNH list.
Note: this file does not include Annette Island Reserve 0110, the only reservation in Alaska.

The file provides the key to mapping between Census geographies and the 12 Alaska Native Regional Corporations.
The file includes four ANVSAs that we have not mapped to an FRN entity: Canyon Village (6257), Port Alsworth (7263), Lake Minchumina (6850), and Uyak (7705). 
 
- AIANNHCE = 4 digit integer; Census AIANNH area geography code.
- AIANNHNS = 8 digit integer; national standards code for geography; first digit is 0 in all cases.
- aiannh_geoname = var string; tribal or other name for geography.
- AIANNH_geoname_full = var string; AIANNH_geoname with census type abbreviation (e.g., ANVSA).
- FIPS = 5 digit integer; Alaska Native Regional Corporation FIPS code; include leading 0s in some cases.
- ANRCNS = 8 digit integer; national standards code for geography; first digit is 0 in all cases.
- GEOIDFQ = alpha numeric 16 character GeoID; "2300000US02" prefixed to ANRC_FIPS code.
- ANCSA_region = var string; short name of Alaska Native Claims Settlement Act region.
- ANCSA_region_long = var string; longer name of Alaska Native Claims Settlement Act region.

This is a many-to-one file with many Census ANVSAs associated with a single ANCSA_region.

################################################################
**File 2: census-tribal_CICDEntityID_FRNName.csv**

This file contains the FRN list of federally recognized Native entities linked to the CICD Native Connector id codes.
CICD codes found at https://www.minneapolisfed.org/indiancountry/resources/public-indian-country-datasets

Entities are repeated when the published name string changes, even in a minor way, along with the date the name was published.
This file is currently benchmarked to the FRN notice from 2024-12-11.
Alternatives are included if they were different in the previous FRN from 2024-12-11 or changed/added in the 2026-01-30 FRN.
There were three entity name changes in between Dec and Jan 2024.
There were ten entity name changes between Dec 2024 and Jan 2026 and one addition in Jan 2026.

- neid_prefix = 4 character string, caps; CICD code indicates if the entity is a Federally recognized tribe (TRBF) or Alaskan Native Village (AKNF).
- neid_mid = 6 character string; CICD code to identify each entity on the FRN list.
- FRN_NameAsPublished = var string; Tribal or village name as published in the Federal Register Notice. Similar to CICD variable fedreg_namefull.
- FRN_Date = MO/DA/YYYY date; date of FRN associated with FRN_NameAsPublished. Currently three dates: 12/11/2024 (benchmark), 1/8/2024, and 1/30/2026. 

File has 590 records: 576 from the 2024-12-11 FRN and 3 name changes from the 2024-01-08 FRN, 10 changes in 2026-01-30 and one addition in 2026-01-30.

Due to date changes, file is one-to-many (neid_mid to FRN_NameAsPublished).

################################################################
**File 3: census-tribal_FRNCICDEntity_CensusGeography.csv**

This file has one row for each FRN 2026-01-30 entity x Census geography relationship.
Census geographies come from the 2020 Census AIANNH list.
There is one addition to this list since 2024: AIANNHCE = 3695 Shawnee Trust Land.
The file provides the key to mapping between Census geographies and the FRN20260130 list.

- neid_prefix = 4 character string, caps; unique CICD code indicates if the entity is a federally recognized tribe (TRBF) or Alaskan Native Village (AKNF).
- neid_mid = 6 character string; CICD code to identify each entity on the FRN list.
match = var string, lower case; code to indicate how match was made. 
- AIANNH_geoname_full = var string; Census AIAN geography name.
- STATES = var string, caps, deliminator is ~; list of state abbrevitions that intersect with the geography, e.g. "AZ~CA" for Arizona and California.
- AIANNHCE = 4 digit integer; Census AIANNH area geography code.
- AIANNHNS = 8 digit integer; national standards code for geography; first digit is 0 in all cases.

This is a many-to-many file: FRN entity can be associated with multiple Census geographies, and vice-versa.
There are 15 entities without associated geographies.

Match field values are: 
- nd = name match and location in directory match; 
- n = name only match; 
- d = directory location only match; 
- nod = name over directory match; 
- r = research.
- none = no geography associated with FRN entity.

All cases besides 'nd' were researched in an effort to confirm the match.
'nod' are cases where the leader's address is not located in an associated tribal geography.
'none' also includes one case with a entry in the directory: Native Village of Kanatak KANATK; this village is in the Bristol Bay Native Association and has a P.O. Box mailing address in the Knik ANVSA.

There are 522 FRN entities associated with a single geography. This includes the 15 entities without associated geographies (geography = NA).
There are 42 FRN entities associated with two geographies. This includes neid_mid = PRBLFC and VENTGV, the two combined entities that are also listed by individual village in the FRN.
An additional 13 have 3-16 associated geographies.

There are 583 unique Census geographies associated with an FRN entity. 
521 are associated with one FRN entity.
52 are associated with two entities.
An additional 9 are associated with 3-4 entities. One is associated with 7 entities (Kiowa-Comanche-Apache-Ft Sill Apache/Caddo-Wichita-Delaware joint-use OTSA).

################################################################
**File 4 census-tribal_FRNEntityID_CensusRaceEthCode.csv**

This file has one row for each of the 577 entities listed in the 2026-01-30 FRN.
The file provides the key to mapping between Census race/ethnicity codes and the FRN20260130 list.

- neid_prefix = 4 character string, caps; CICD code indicates if the entity is a Federally recognized tribe (TRBF) or Alaskan Native Village (AKNF).
- neid_mid = 6 character string; CICD code to identify each entity on the FRN list.
- Census_RaceEthCode = four digit integer; Census race and ethnicity code.

This is a one-to-one file: each FRN entity has a unique Census r/e code.

################################################################
**File 5: census-tribal_RaceEthCode_Description.csv**
This file is a subset of the complete Census list of race and ethnicity codes. 
We have subset the list to only the codes that match to FRN20260130 entities. There are 2792 rows.
Downloaded from: https://www2.census.gov/programs-surveys/decennial/2020/technical-documentation/complete-tech-docs/detailed-demographic-and-housing-characteristics-file-a/

- Census_RaceEthCode = 4 digit integer; Census race/ethnicity code.
- Census_Description = var string, all caps; name or description associated with Census race/ethnicity code.

This is a one-to-many file (Code to Description). There are 577 unique Census r/e codes and there are multiple descriptions for many of these.
Only 14 codes have one description. 55 codes have 10 or more descriptions.

################################################################





