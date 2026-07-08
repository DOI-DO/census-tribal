# Create Census race-ethnicity reference table for:
# 1. 2020 Census codes
# 2. Proposed 2030 codes

# E. Silverman May 2026

# This file reads in the 2020 code list and the proposed 2030 codes for AIAN, 
# subsets to US tribal entities, and reformats by replacing "-" with ":" for ranges

library(readxl)

# ### 2020 races code list ############
# Save file to census-tribal_RaceEthCod_Description.csv
race_codes_url <- "https://www2.census.gov/programs-surveys/decennial/2020/technical-documentation/complete-tech-docs/detailed-demographic-and-housing-characteristics-file-b/2020-hispanic-origin-and-race-code-list.xlsx"

race_codes_xlsx <- file.path("data","2020-hispanic-origin-and-race-code-list.xlsx")

download.file(race_codes_url, destfile = race_codes_xlsx, mode = "wb")

race_codes <- read_excel(race_codes_xlsx)
names(race_codes) <- c('race', "code")

# remove blank rows
# replace "-" with ":"
# subset to codes btwn 5000 and 6499 (US AIAN)
race_codes <- race_codes %>% filter(!is.na(race) & !is.na(code)) %>%
  mutate(code = str_replace(code,"-",":")) %>%
  mutate(startCode = as.numeric(str_sub(code, 1, 4))) %>%
  mutate(endCode = as.numeric(str_sub(code, nchar(code)-3, nchar(code)))) %>%
  filter(endCode > 4999 & startCode < 6500) %>%
  select(-startCode, - endCode)

### 2030 proposed code list #################
# Save file to census-tribal_RaceEthCod_Description_2030.csv
race_codes2030_url <- "https://www2.census.gov/programs-surveys/demo/2030-race-and-or-ethnicity-code-list/race-ethnicity-code-list.xlsx"
race_codes2030_xlsx <- file.path("data","race-ethnicity-code-list.xlsx")


download.file(race_codes2030_url, destfile = race_codes2030_xlsx, mode = "wb")

race_codes2030 <- read_excel(race_codes2030_xlsx, sheet = "AIAN")
names(race_codes2030) <- c("code", "race")

# remove blank rows
# replace "-" with ":"
# subset to codes btwn 5000 and 6499 (US AIAN)
race_codes2030 <- race_codes2030 %>% filter(!is.na(race)) %>%
  mutate(code = str_replace(code,"-",":")) %>%
  mutate(startCode = as.numeric(str_sub(code, 1, 4))) %>%
  mutate(endCode = as.numeric(str_sub(code, nchar(code)-3, nchar(code)))) %>%
  filter(endCode > 4999 & startCode < 6500) %>%
  select(-startCode, - endCode)


test <- full_join(race_codes, 
                  race_codes2030 %>% 
                    group_by(code) %>%
                    mutate(index = row_number()) %>%
                    ungroup() %>%
                    filter(index == 1), 
                  by = ("code" = "code"))