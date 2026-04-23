# This function pulls Decennial Census data for user specified tables
# for AIAN geographies (or other user specified geographies).

# See https://www.census.gov/data/developers/data-sets/decennial-census.html
# for explanation of tables, variables, and geographies available.

# E Silverman, DOI 23-April-2026

# NOTE!!
# Prior to running, source the tidycensus package and
# set the API key: census_api_key("MY KEY HERE").
# Include, "install = T" if you want to skip adding the key at every session.
# 
# Should be used together with the **view_tables_decennial.fn** function.
# This function assist in identifying the tables and variables available for
# each of the 2020 decennial products.


get_table_decennial.fn <- function(year = 2020, 
                                   sumfile = "dhc",
                                   tab = 'P8',
                                   geo = "american indian area/alaska native area/hawaiian home land",
                                   dropNonFed = T) {
  
  # default dataset is "dhc" = demographic and housing
  # dataset values relevant for 2020 are: 
  # pl = redistricting data
  # dp = demographic profile
  # ddhca = detailed demographic and housing A
  # ddhcb = detailed demographic and housing B
  # sdhc = supplemental demographic and housing
  
  # NOTE: 2000 and 2010 datasets have different names.
  
  # tab is the table desired; default P8 provides the population by race/ethnicity
  # run view_tables_decennial.fn to see all tables available.
  
  # default geography product is "american indian area/alaska native area/hawaiian home land"
  # other possible decennial AIAN geo sets:
  # "alaska native regional corporation"
  # "american indian area/alaska native area (reservation or statistical entity only)" 
  
  # dropNonFed is a logical; T = drop state recognized areas and Hawaiian home lands
  # exception: three state areas associated with federally recognized entities
  # Lumbee (GEOID = 9815), Pamunkey (9260), Shinnecock (9370)
 
  # load variables for selected year and table
 variables <- load_variables(year, dataset = sumfile, cache = TRUE) %>% 
   mutate(table = str_split_i(name, "_",1)) %>%
   filter(table == tab) %>%
   mutate(label = str_trim(str_replace_all(label, "!!", ""))) 
 
 # logical to classify the table as specific to AIAN
 # if True, save all variables. If False, save totals and AIAN variables.
 AIAN.table <- str_detect(unique(variables$concept), "AMERICAN INDIAN")
 
 out <- get_decennial(year = year, 
                      geography = geo, 
                      sumfile = sumfile,
                      table = tab) 
 
 out <- left_join(out, variables %>% select(name, label), by = c('variable' = "name"))
 
 if (!AIAN.table) {
   # total variables end in ":", labels are not in caps
   out <- out %>% filter(str_sub(label,nchar(label)) == ":" | str_detect(label, "American Indian"))
 }
  
 if(dropNonFed) {
   # drop Native Hawaiian home lands
   out <- out %>% filter(!(as.numeric(GEOID) %in% c(5000:5499)))
   # drop state AIR and statistical areas, except 2 Fed recognize:
   out <- out %>% filter(!(as.numeric(GEOID) > 8999 & 
                             !(as.numeric(GEOID) %in% c(9260, 9370, 9815))))
   
 }
 
 out
}