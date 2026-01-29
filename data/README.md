# E. Silverman and A. Miller, Office of Policy Analysis, Department of Interior, August 2025
# Last update: 29-Jan-2026

Reference data tables for Federally recognized American Indian and Alaska Native entities. 

These tables use the list of federally recognized entities published in the Federal Register Notice (FRN).
As of the creation of these files, the most recent update of the FRN list occurred on 2024-12-11 (FRN20241211)
There are 576 federally recognized entities listed in the FRN20241211.
This includes two cases where two entities are reported both alone and together:
"Native Village of Venetie Tribal Government (Arctic Village and Village of Venetie)" id_temp = 542
"Pribilof Islands Aleut Communities of St. Paul & St. George Islands (Saint George Island and Saint Paul Island)" id_temp = 377 

################################################################
**File 1: census-tribal_ANVSA_ANRC.csv**
This file has one row for 223 Census geographies in Alaska.
Census geographies come from the 2020 Census AIANNH list.
The file provides the key to mapping between Census geographies and the 12 Alaska Native Regional Corporations.
The file includes four ANVSAs that do not map to an FRN entity: Canyon Village (6257), Port Alsworth (7263), Lake Minchumina (6850), and Uyak (7705). 

AIANNHC = 4 digits integer; Census AIANNH area geography code.
AIANNHNS = 8 digit integer; national standards code for geography.
AIANNH_Geoname = var string; tribal or other name for geography.
AIANNH_Geoname_Full = var string; AIANNH_Geoname with census type abbreviation (e.g., ANVSA).
ANRC_FIPS = 5 digit integer; Alaska Native Regional Corporation FIPS code.
ANRCNS = 8 digit integer; national standards code for geography.
GEOIDFQ = alpha numeric 16 character GeoID; "2300000US02" prefixed to ANRC_FIPS code.
ANCSA_Region = var string; short name of Alaska Native Claims Settlement Act region.
ANCSA_Region_Full = var string; longer name of Alaska Native Claims Settlement Act region.

This is a many-to-one file with many Census ANVSAs associated with a single ANCSA_region.

################################################################
**File 2: census-tribal_RaceEthCode_Description.csv**
This file is a subset of the complete Census list of race and ethnicity codes. 
We have subset the list to only the codes that match to FRN entities.
**NOTE:** This file has entries and unique codes for the four Alaskan villages with combined FRN entries, and also for the combined entities:
Native Village of Venetie Tribal Government (5090), Arctic Village (5091), Village of Venetie (5092).
Pribilof Islands Aleut Communities of St. Paul & St. George Islands (5174), St. George Island (5175), St. Paul Island (5176).

Census_RaceEthCode = four digit integer; Census race and ethnicity code.
Census_Description = var string, all caps; name or description associated with Census race/ethnicity code.

This is a one-to-many file (Code to Description). There are 576 unique Census r/e codes and there are multiple names for many of these.

################################################################
**File 3: census-tribal_CICDEntityID_ANRCID.csv**
This file is a subset of the FRN list to only Alaska Native Villages with associated membership in an Alaskan Native Regional Corporation.

File is not included until CICD codes are published.  

################################################################
**File 4: census-tribal_tempEntityID_FRNName.csv**
This file contains the FRN list of Native entities and a numeric stand (index from 1-576) in for the associated CICD unique identifier.
CICD has 572 codes, but id_temp runs to 576 as we have added four codes for Arctic Village, Village of Venetie, St. George Island, and St. Paul Island.
Entities are repeated when the published name string changes, along with the date the name was published.
This file is currently benchmarked to the latest FRN notice from 2024-12-11 with alternative names included if they were different in the previous FRN from 2024-01-08.
There were three entities with name changes in Dec 2024.

id_AK (replaces CICD id_prefix) = 4 character string, caps; code indicates if the entity is a Federally recognized tribe (TR48) or Alaskan Native Village (AKNV).
id_temp = integer between 1-576 to identify an entity on the FRN list (to be replaced by CICD unique entity ID = id_mid).
FRN_NameAsPublished = var string; Tribal or village name as published in the Federal Register Notice.
FRN_Date = YYYY-MO-DA date; date of FRN associated with FRN_NameAsPublished. Currently two dates: 2024-12-11 and 2024-01-08. 

File has 579 records: 576 from the 2024-12-11 FRN and 3 name changes from the 2024-01-08 FRN.

Due to date changes, file is one-to-many (id_mid to NameAsPublished).

NOTE: Both the Jan and Dec 2024 FRN have 576 entities listed, as the consitutent villages for the Village of Venetie and the Pribilof Islands are listed separately and together.
CICD has relegated the individual villages to sub-entity status and they do not have unique id_mid codes. We have created 6 character codes for these four FRN entities.
################################################################
**File 5: census-tribal_CICDEntityID_SubEntityID.csv**

File is not included until CICD codes are published.  

################################################################
**File 6: census-tribal_FRNtempEntity_CensusGeography.csv**
This file has one row for each FRN 2024-12-11 entity x Census geography relationship.
Census geographies come from the 2020 Census AIANNH list.
The file provides the key to mapping between Census geographies and the FRN20241211 list.

id_AK (replaces CICD id_prefix) = 4 character string, caps; code indicates if the entity is a Federally recognized tribe (TR48) or Alaskan Native Village (AKNV).
id_temp = integer between 1-576 to identify an entity on the FRN list (to be replaced by CICD unique entity ID = id_mid).
match = var string, lower case; code to indicate how match was made. 
FRN_NameAsPublished = var string includes special characters; Federally recognized entity name as written in Federal Register Notice 2024-12-11.
AIANNH_Geoname_Full = var string; AIANNH_Geoname with census type abbreviation (e.g., ANVSA).
STATES = var string, caps, deliminator is ~; list of state abbrevitions that intersect with the geography, e.g. "AZ~CA" for Arizona and California.
AIANNHC = 4 digits integer; Census AIANNH area geography code.
AIANNHNS = 8 digit integer; national standards code for geography.

This is a many-to-many file: FRN entity can be associated with multiple Census geographies, and vice-versa.
There are 15 entities without associated geographies.

Match field values are: 
nd = name match and location in directory match; 
n = name only match; 
d = directory location only match; 
nod = name over directory match; 
r = research.
none = no geography associated with FRN entity.

All cases besides 'nd' were researched in an effort to confirm the match.
'nod' are cases where the leader's address is not located in an associated tribal geography.

There are 523 FRN entities associated with a single geography. This includes the 15 entities without associated geographies (geography = NA).
There are 42 FRN entities associated with two geographies. This includes id_temp = 377 and 542, the two combined entities that are also listed by individual village in the FRN.
An additional 11 have 3-8 associated geographies.

There are 582 unique Census geographies associated with an FRN entity. 
542 are associated with one FRN entity.
30 are associated with two entities.
An additional 9 are associated with 3-4 entities. One is associated with 7 entities (Kiowa-Comanche-Apache-Ft Sill Apache/Caddo-Wichita-Delaware joint-use OTSA).
################################################################
**File 7 census-tribal_FRNName_CensusRaceEthCode.csv**
This file has one row for each of the 576 entities listed in the 2024-12-11 FRN.
The file provides the key to mapping between Census race/ethnicity codes and the FRN20241211 list.

id_AK (replaces CICD id_prefix) = 4 character string, caps; code indicates if the entity is a Federally recognized tribe (TR48) or Alaskan Native Village (AKNV).
id_temp = integer between 1-576 to identify an entity on the FRN list (to be replaced by CICD unique entity ID = id_mid).
FRN_NameAsPublished = var string includes special characters; Federally recognized entity name as written in Federal Register Notice 2024-12-11.
Census_RaceEthCode = four digit integer; Census race and ethnicity code.

This is a one-to-one file: each FRN entity has a unique Census r/e code.

################################################################
**File 8: census-tribal_FRNName_CensusANCSARegion.csv**
This file has one row for each of the 228 Federally recognized entities in Alaska.
Artic Village, Village of Venetie, St. George, and Saint Paul are included alone and in combination, as in the FRN 2024-12-11.
The file provides the key to mapping between these entities and the 12 Alaska Native Corporations.

FRN_NameAsPublished = var string includes special characters; Federally recognized entity name as written in Federal Register Notice 2024-12-11.
ANCSA_Region = var string; twelve values are the short names of the 12 Alaska Native Claims Settlement Act regions.
ANRC_FIPS = 5 digit integer; Alaska Native Regional Corporation FIPS code.

This is a many-to-one file, as multiple FRN_NameAsPublished are associated with each ANCSA_region.

