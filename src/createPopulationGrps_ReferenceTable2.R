# This code edits the popgroup.json files that area available on the Census API
# for the DDHCA/B 2020 Decennial Census
# This appears to be a comprehensive list of population and iteration codes.
# Want to compare to table created from ACS and decennial 2020 files sourced in
# createPopulationGrps_ReferenceTable.R to determine there are other AIAN codes (Yes).

# May-2026 E Silvermann

# Note: have to do much of this editing by viewing the table, as have
# no mapping between these codes and race codes.

# output is a data frame popGrps_json_AIAN with 3574 rows, 406 do not have matches
# to the ACS/Decennial outTable produced by createPopulationGrps_ReferenceTable.R

library(tidyverse)
library(httr)
library(jsonlite)

popGrps2020.ddhca <- content(GET(paste0("https://api.census.gov/data/2020/dec/ddhca/variables/POPGROUP.json?key=",my_census_key)))
popGrps2020.ddhcb <- content(GET(paste0("https://api.census.gov/data/2020/dec/ddhcb/variables/POPGROUP.json?key=",my_census_key)))

# Note: ddhcb appears to include two additional codes 4055-56 for "Latin American Indian" alone or in combo

popGrps_json <- stack(popGrps2020.ddhca$values) %>% 
  mutate(code = row.names(popGrps_json)) %>% select(-ind)

# There are 4 kinds of codes: 4 digit; 3 digit; 3 alpha-numeric, letter 2nd; 3 alpha-numeric, letter 3rd
# Will code these f = four, t = three #s, t2 = three, 2nd letter, and t3 = three, 3rd letter
popGrps_json  <- popGrps_json  %>% mutate(codeType = ifelse(nchar(code) == 4, "f","t"),
                        hasLetters = str_detect(code, "[A-Za-z]"),
                        Letter3rd = str_detect(str_sub(code, 3, 3), "[A-Za-z]"),
                        Letter2nd = str_detect(str_sub(code, 2, 2), "[A-Za-z]")) %>%
          mutate(codeType = ifelse(codeType == "t" & Letter2nd,
                                   "t2",
                                   ifelse(codeType == "t" & Letter3rd,
                                          "t3", codeType)))
# order for easier review:
popGrps_json  <- arrange(popGrps_json , codeType, code)

# flag duplicate names (i.e., values field with more than 1 code, expected b/c of differnt code types):
popGrps_json <- popGrps_json %>% group_by(values) %>% mutate(n = n(), match_id = cur_group_id()) %>% ungroup()

# join to already created population group reference table (based on decennial 2020 and ACS SPT xlsx files)
# we are checking if there are additional codes we should know about
# match = 1 or NA ... there are 3168 matches
# there are 2375 that do not match (NOTE: popGrps_json includes non AIAN groups)
popGrps_json <- left_join(popGrps_json, 
                          outTable %>% 
                            filter(!is.na(popCode)) %>% 
                            mutate(match = 1) %>% 
                            select(code = popCode, match, descriptiveName))

# we only want to look at unmatched codes
popGrps.unmatched <- popGrps_json %>% filter(is.na(match))

# NOTE: there are 164 cases (195 rows) where one or more duplicate pop group names (values) dropped (code matched)
nrow(distinct(popGrps.unmatched %>% group_by(match_id) %>% mutate(n2 = n()) %>% filter(n != n2), match_id))

# there are no four number codes for AIAN in unmatched set, drop all f-type codes
popGrps.unmatched <- popGrps.unmatched %>% filter(codeType != "f")
# t2 appear to be AIAN codes, 6** look to be Canadian, Caribbean, Mexican, Central, South American
# drop t2 codes beginning with 6, leaves 62:
popGrps.unmatched <-  popGrps.unmatched %>% filter(!(codeType == "t2" & str_sub(code, 1, 1) == "6")) 

# one odd exception left to reomove ... Chamorro are coded 9Z8 and 9Z9:
popGrps.unmatched <- popGrps.unmatched %>% filter(!str_detect(values, "Chamorro"))

# filtering remaining from "t" and "t3" codes are more complicated ... create a filter index for the t codes:
popGrps.unmatched <- popGrps.unmatched %>%
mutate(codeNum = ifelse(codeType == "t", as.numeric(code), 0)) %>%
mutate(filter_t = ifelse(
  (codeType == 't' &
     ((codeNum > 0 & codeNum <= 193 & str_detect(values, "American Indian|Alaska")) |
      (codeNum > 193 & codeNum < 300 & !str_detect(values, "Central American|South American|Latin American|Mexican American|Spanish American|Canadian|French")) |
      (codeNum %in% c(455,456,468,469,493,588)))
), T, F)) %>%
filter(filter_t | codeNum == 0)

# t3 codes appear to be all US AIAN except generics for other Indigenous people
# remove these and list should be complete: Canadian, Mexican, central and South American, etc. generics:

# end with 406 unmatched population groups
popGrps.unmatched <- popGrps.unmatched %>% 
  filter(!str_detect(values, "Canadian|Central American|French|Mexican|Siberian|South American|Spanish"))

# join unmatched table to original set of matches, format for output
popGrps_json_AIAN <- bind_rows(popGrps_json %>% 
                                 filter(!is.na(match)) %>%
                                 mutate(match = "yes") %>%
                                 select(values, code, codeType, match),
                               popGrps.unmatched %>%
                                 mutate(match = "no") %>%
                                 select(values, code, codeType, match)
                                 ) %>% 
                      mutate(values = str_trim(values)) %>%
                      select(popCode = code, descriptiveName = values, codeType, match)

# Add fields to identify codes with the same values (descriptive name):
popGrps_json_AIAN <- popGrps_json_AIAN %>% group_by(descriptiveName) %>% 
  mutate(n_name= n(), name_id = cur_group_id()) %>% ungroup()
     