# Create Master Reference table with decennial 2020 iteration numbers
# and ACS population group codes ....
#
# 5-May-2026 E Silverman
#
# These groups are defined by the races codes
# The available tables that relate population group codes to race codes 
# are the key to cross referencing the various population/iteration codes

# Note: createPopulationGrps_ReferenceTable2.R pulls population group codes from 
# the Census API for decennial census population group tables for DDHCA/B, 
# matches those to the table here, edits the unmatched codes to extract AIAN codes.
# This process identified 406 codes missing from the product created here. 
# Do not have race code match for these missing codes.

# Note: there are two cases for race matches
# (1) one race code for a "population group" and 
# (2) population group represents multiple race codes

# A few notes about case (2):
# 1. Race code ranges may include unassigned race codes (and may devolve to a single code)
# 2. The decennial census and ACS may report/use different multiple race groups
# 3. There are MORE multi-race population groups for ACS
# 4. The ACS reports AIAN alone, AIAN in combination, which includes non-US race codes
# .... 2020 decennial does not have a iteration code for this super-group (5000:6999).
# 5. Both decennial 2020 and ACS report US AI as "American Indian" (5500:6499)
# 6. American Indian + Alaska Native should sum to U.S. race codes
# NOTE: Population Groups from 2020 DDHCA list "American Indian tribal grouping alone"
# and "Alaska Native tribal grouping alone" (also "or in any combination") match
# to ACS codes that do not include "tribal grouping" (4Z9, 5Z9, 7A1, 9Z2)
# these are the only descriptiveName mis-matches for matching codes in the two reference tables.
# 7. The decennial census reports "unspecified" AI under iteration code 5500
# and "unspecified" AN under iteration codes 5010 and 5011. These are not 
# totals, but should be included in the AIAN totals

# ACS Population Group Code x Race Code from 2017-21 AIANT Population Groups
# tab in: SPt-AIANT_Documentation_2017-2021.xlsx
# Found here: https://www.census.gov/programs-surveys/acs/data/race-aian.html

# The table is located on the AIANT Population Groups TAB
# Population Group Code corresponds to the CHARITER code from the 2010 decennial
# it is made up of 3 characters (alpha-numeric) 

# CHARITER = Characteristic Iteration code, also called "iteration code" or
# "iteration group code"

# These values changed in the 2020 decennial and different codes are needed
# to extract data from that api

### This code creates a data frame ACS_groups:
# ACScode = 3 alpha-numeric character code
# inAIANT2021 = Yes/No data included in 2021 AIAN special tables
# name_ACS = descriptive name associated with code, may be "alone" or "alone & in combination"
# raceCodes = character string with list of 4 digit AIAN race codes associated with ACScode
# rep = number of values spanned by raceCodes
# rep2 = same as rep unless raceCodes were NOT expanded to drop invalid codes, then rep2 = 1 (6 cases)
# codeList = raceCodes expanded to ONLY valid AIAN codes and stored as comma separated character string
# NOTE: 6 cases with rep > 1 and rep2 = 1 are not expanded and codeList = raceCodes
# group = 0,1,2 where 0 = single race code, 1 = multiple race codes, 2 = raceCodes list range but devolves to single valid race code
# ... for ACS 176 multi-race code cases; 155 "devolve to 1 race code" cases
# combo = 0,1 where 0 = "alone" and 1 = "alone or in combination" (more "in combination" codes)

### This code creates a data frame dec2020_iterations:
# iterNum2020 = 4 digit numeric iteration code
# name_2020 = descriptive name associated with code, may be "alone" or "alone & in combination"
# raceCodes = character string with list of 4 digit AIAN race codes associated with ACScode
# rep = number of values spanned by raceCodes
# rep2 = same as rep unless raceCodes were NOT expanded to drop invalid codes, then rep2 = 1 (8 cases)
# codeList = raceCodes expanded to ONLY valid AIAN codes and stored as comma separated character string
# NOTE: 8 cases with rep > 1 and rep2 = 1 are not expanded and codeList = raceCodes
# two cases (2248, 3450) are "Tribal responses, not elsewhere classified" and are a list of only invalid race codes
# two cases AIAN alone and "alone or in combination" do not have 2020 iteration codes (5000:6999 group, 006 and 009 in ACS)
# group = 0,1,2 where 0 = single race code, 1 = multiple race codes, 2 = raceCodes list range but devolves to single valid race code
# ... for dec2020 12 multi-race code cases (but includes "not specified" cases for AI and AN); 1 "devolve to 1 race code" case
# combo = 0,1 where 0 = "alone" and 1 = "alone or in combination" (equal number)

# output table binds these two tables, drops flag for AIANT 2021 tables and rep codes:
# popCode = char, ACS or Decennial 2020 population group or iteration number code (ACScode, iterNum2020)
# descriptiveName = char, descriptive population group name (name_ACS, name_2020)
# raceCodeList_census = char, the race code, codes, or code range reported by Census as defining the pop group (raceCodes)
# raceCodeList_edited = char, the valid race codes, expanded (codeList, see above)
# popGrp_category = 0,1,2 where 1 = multiple race codes and 0,2 both are one code (group, see above)
# inCombo = 0,1 to indicate "alone" or "alone or in combination" (combo)
# 

library(readxl)
library(tidyverse)

#### Read in tables: ACS codes, Race codes, decennial 2020 iteration numbers: #############

# 1. ACS AIAN codes from special tables 2017-2021
ACS_codes_url <- "https://www2.census.gov/programs-surveys/acs/tech_docs/race_ethnicity_aian/2021/SPT-AIANT_Documentation_2017-2021.xlsx"

ACS_codes_xlsx <- file.path("data","SPT-AIANT_Documentation_2017-2021.xlsx")

download.file(ACS_codes_url, destfile = ACS_codes_xlsx, mode = "wb")

ACS_PopGrps <- read_excel(ACS_codes_xlsx, sheet = "AIANT Population Groups", skip = 3)
names(ACS_PopGrps) <- c("ACScode", "inAIANT2021", "name_ACS","raceCodes")

# 2. 2020 races code list:
race_codes_url <- "https://www2.census.gov/programs-surveys/decennial/2020/technical-documentation/complete-tech-docs/detailed-demographic-and-housing-characteristics-file-b/2020-hispanic-origin-and-race-code-list.xlsx"

race_codes_xlsx <- file.path("data","2020-hispanic-origin-and-race-code-list.xlsx")

download.file(race_codes_url, destfile = race_codes_xlsx, mode = "wb")

race_codes <- read_excel(race_codes_xlsx)
names(race_codes) <- c('race', "code")

# 3. 2020 iteration codes v. race codes:
dec2020_iterations_url <- "https://www2.census.gov/programs-surveys/decennial/2020/technical-documentation/complete-tech-docs/detailed-demographic-and-housing-characteristics-file-b/2020-census-hispanic-origin-and-race-iterations-list.xlsx"

dec2020_iterations_xlsx <- file.path("data","2020-census-hispanic-origin-and-race-iterations-list.xlsx")

download.file(dec2020_iterations_url, destfile = dec2020_iterations_xlsx, mode = "wb")

dec2020_iterations <- read_excel(dec2020_iterations_xlsx)
names(dec2020_iterations) <- c("iterNum2020","name_2020","raceCodes")
# Need to remove some non-data rows (36 and last 3 rows):
dec2020_iterations <- dec2020_iterations %>% filter(!(is.na(raceCodes) | str_sub(raceCodes, 1, 4) == "Race"))


######### Edit race code table to remove grouped categories ########

race_codes <- race_codes %>% filter(!is.na(race)) %>%
  filter(!str_detect(code, "-")) %>%
  mutate(code = as.numeric(code)) %>%
  filter(code > 4999 & code < 6500)


########## Prepare ACS table for merging ###############

ACS_PopGrps <- ACS_PopGrps %>%  # drop codes after "&" = "in combo" part ....
                  mutate(raceCodes = str_trim(str_extract(raceCodes, "^[^&]+"))) %>%
                  mutate(checkRaceCode = as.numeric(str_sub(raceCodes, 1, 4))) %>%
                  filter(checkRaceCode < 6500)

# Calculate number of duplicate rows for each race code in the category,
# create "rep2" to avoid duplicating "super" groups
ACS_PopGrps <- ACS_PopGrps %>% mutate(rep = ifelse(nchar(raceCodes) > 4,
                                                   (as.numeric(str_sub(raceCodes, 6, 10)) - 
                                                     checkRaceCode + 1),
                                                   1)
                                      ) %>%
                              mutate(rep = ifelse((checkRaceCode + rep) > 6499, 
                                                  (6499 - checkRaceCode + 1),
                                                  rep)) %>%
                              mutate(rep2 = ifelse(rep > 489, 1, rep))


# duplicate rows by # of reps, except super groups!:
ACS_PopGrps <- ACS_PopGrps[rep(seq_len(nrow(ACS_PopGrps)), times = ACS_PopGrps$rep2),]
#
ACS_PopGrps <- ACS_PopGrps %>% group_by(ACScode, inAIANT2021, name_ACS, raceCodes, checkRaceCode, rep, rep2) %>%
          mutate(index = row_number() - 1) %>%
          ungroup %>%
          mutate(raceCode2 = checkRaceCode + index) %>%
          select(ACScode, inAIANT2021, name_ACS, raceCodes, code = raceCode2, rep, rep2)

# join to race codes to remove un-assigned race codes
# There are 18 cases with race codes and no entry in the ACS SPT table
# Six are generic: 5000, 5001, 5010, 5011, 5500 and 6460 Tribal response, Not Elsewhere Classified
ACS_PopGrps <- left_join(ACS_PopGrps, race_codes %>% filter(code > 4999)) %>% 
  filter(!is.na(race)) # super group initial code maps to a race in all cases

# create new field "codeList" character string with common separated valid race codes for the group
# also group = 1/0 to indicate if "raceCodes" has > 1 code ... bc some groups in raceCodes devolve to
# only one valide race category
ACS_PopGrps <- ACS_PopGrps %>% group_by(ACScode, inAIANT2021, name_ACS, raceCodes, rep, rep2) %>% 
  summarize(codeList = paste(code, collapse = ",")) %>%
  ungroup() %>%
  mutate(codeList = ifelse(rep > 489, raceCodes, codeList)) %>%
  mutate(group = ifelse(rep == 1, 0, 1))

# separately flag Census "group" codes that map to only one valid race category
ACS_PopGrps <- ACS_PopGrps %>% mutate(group = ifelse((group == 1 & nchar(codeList) == 4),
                                                     2, group))

# flag "in combination", 671 alone, 717 in combination
ACS_PopGrps <- ACS_PopGrps %>% mutate(combo = ifelse(str_detect(name_ACS, "combination"), 1, 0))

########## Edit Decennial 2020 census table for merging ########

# There are 10 cases that represent a range of race codes

# AIAN alone not specified (2560), 
# AIAN alone or in any combo not specified (3762)

# Alaska Native alone (1360), AK Native alone not specified (1629)
# American Indian alone (1631), American Indian alone not specified (4053)

# AK Native alone or in combo (2562), alone or in combo not specified (2831)
# American Indian alone or in any combo (2833), American Indian alone or in any combo not specified (4054)

# NOTE: AIAN includes codes 6500-6999 
# but "American Indian" does NOT (this is codes 5500-6499)
# "not specified" is code 5500
# "Tribal response ... not elsewhere classified" are listed btwn 5509-5992
# These are unassigned codes.

# Thus, adding American Indian alone + Alaska Native alone should give only U.S. tribal responses

dec2020_iterations <- dec2020_iterations %>% 
                        mutate(startCode = as.numeric(str_sub(raceCodes, 1, 4)),
                               endCode = as.numeric(str_sub(raceCodes, nchar(raceCodes)-3, nchar(raceCodes)))) %>%
                        filter(startCode > 4999 & startCode < 6500) %>%
                        mutate(name_2020 = str_replace(name_2020, "[*]", "")) %>%
                        mutate(rep = endCode - startCode + 1) %>%
                        mutate(rep2 = ifelse(rep > 489, 1, rep))

# duplicate rows by # of reps, except super groups!:
dec2020_iterations <- dec2020_iterations[rep(seq_len(nrow(dec2020_iterations)), times = dec2020_iterations$rep2),]

#
dec2020_iterations <- dec2020_iterations %>% group_by(iterNum2020, name_2020, raceCodes, startCode, endCode, rep, rep2) %>%
  mutate(index = row_number() - 1) %>%
  ungroup %>%
  mutate(code = startCode + index) %>%
  select(iterNum2020, name_2020, raceCodes, code, rep, rep2)

# join to race codes to remove un-assigned race codes
# There are 36 cases with NA for race, but 2 are the "Tribal responses alone" so keep (rep = 991)
dec2020_iterations <- left_join(dec2020_iterations, race_codes %>% filter(code > 4999)) %>% 
  filter(!((rep < 490) & is.na(race))) # super group initial code maps to a race in all cases

# create new field "codeList" character string with common separated valid race codes for the group
# also group = 1/0 to indicate if "raceCodes" has > 1 code ... bc some groups in raceCodes devolve to
# only one valid race category
dec2020_iterations <- dec2020_iterations %>% group_by(iterNum2020, name_2020, raceCodes, rep, rep2) %>% 
  summarize(codeList = paste(code, collapse = ",")) %>%
  ungroup() %>%
  mutate(codeList = ifelse(rep > 489, raceCodes, codeList)) %>%
  mutate(group = ifelse(rep == 1, 0, 1))

# separately flag Census "group" codes that map to only one valid race category, 1 case = 2 rows
dec2020_iterations <- dec2020_iterations %>% mutate(group = ifelse((group == 1 & nchar(codeList) == 4),
                                                                   2, group))

# flag "in combination"" and drop "American Indian and Alaska Native" (-A and -AoIC) 
# ... these have NA codes and are present in ACS code list 
# this results in 890 alone, 890 in combination
dec2020_iterations <- dec2020_iterations %>% mutate(combo = ifelse(str_detect(name_2020, "combination"), 1, 0)) %>%
  filter(!is.na(iterNum2020))

###### Merge tables to create a single tidy version table #####
# create single data frame for AIAN groups with ACS and decennial 2020 codes:
# data from has 3168 unique codes

outTable <- bind_rows(
  ACS_PopGrps %>% select(popCode = ACScode, 
                         descriptiveName = name_ACS,
                         raceCodeList_census = raceCodes,
                         raceCodeList_edited = codeList,
                         popGrp_category = group,
                         inCombo = combo),
  dec2020_iterations %>% select(popCode = iterNum2020, 
                         descriptiveName = name_2020,
                         raceCodeList_census = raceCodes,
                         raceCodeList_edited = codeList,
                         popGrp_category = group,
                         inCombo = combo)
)


