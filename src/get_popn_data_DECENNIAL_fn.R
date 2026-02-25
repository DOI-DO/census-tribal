# This function pulls population totals and AIAN totals (alone, in combination)
# from decennial census.
# Sums all in the in combination responses, geographies = AIANNH home lands

# Result = GEOID, geography name, variable (total popn, AIAN-A or AIAN-IC), and value

# other possible geos:
# "alaska native regional corporation"
# "american indian area/alaska native area (reservation or statistical entity only)"

# prior to running set key: census_api_key("MY KEY HERE")

# To create a wide table with total, AIAN-A, AIAN-AoIC:
# pivot_wider(out, id_cols = c("GEOID", "NAME"), names_from = variable) %>% 
#           mutate(AoIC = A + IC) %>% select(GEOID, NAME, total, A, AoIC)

# E Silverman 9-FEb-2026

get_popn_data <- function(year = 2020, sumfile = "dhc",
                          geo = "american indian area/alaska native area/hawaiian home land",
                          dropNonFed = T) {
 
  library(tidycensus)
  library(tidyverse)
  
  # load variables for selected year and table
  variables <- load_variables(year, sumfile, cache = TRUE)
  
  # select all P8 variables with AIAN, as well as the total (_001N)
  var.select <- c("P8_001N",
                  variables %>% 
                    filter(str_detect(label, "American Indian and Alaska Native") & 
                             str_detect(name, "P8_")) %>% 
                    select(name) %>% pull)
  
  out <- get_decennial(geography = geo, 
                        variables = var.select, 
                        year = year,
                        sumfile = sumfile) %>%
    mutate(variable = ifelse(variable == "P8_001N", "total",
                             ifelse(variable == "P8_005N", "A", "IC"))) %>% 
    group_by(GEOID, NAME, variable) %>% summarize(value = sum(value), .groups ='drop' )
  
  if(dropNonFed) {
    # drop Native Hawaiian home lands
    out <- out %>% filter(!(as.numeric(GEOID) %in% c(5000:5499)))
    # drop state AIR and statistical areas, except 2 Fed recognize:
    out <- out %>% filter(!(as.numeric(GEOID) > 8999 & 
                              !(as.numeric(GEOID) %in% c(9260, 9370, 9815))))
    
  }
  
  out
}

