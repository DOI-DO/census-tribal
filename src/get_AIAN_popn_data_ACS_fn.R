# This function pulls population totals and AIAN totals (alone, in combination)
# from 5-year American Community Survey (ACS) data.
# Geographies = AIANNH home lands associated with federally recognized AIAN entities

# NOTE: this includes 3 geographies belonging to federally recognized tribes
# with state-only areas: Lumbee (9815), Pamunkey (9260), Shinnecock (9370).

# NOTE!!
# Prior to running, source the tidycensus package and
# set the API key: census_api_key("MY KEY HERE").
# Include, "install = T" if you want to skip adding the key at every session.
# 

# Inputs:
# year = integer for 5-year interval from (year-5, year)
# acs_table = ACS 5-year profile table is the default for this function
# geo = character string indicate the AIAN geography product to select
# dropNonFed = logical, default = T, remove geographies not associated with federally-recognized entities

# default geography product is "american indian area/alaska native area/hawaiian home land"
# other possible geo sets:
# "alaska native regional corporation"
# "american indian area/alaska native area (reservation or statistical entity only)"
# "american indian area (off-reservation trust land only)/hawaiian home land"

# Output: data frame with five columns
# GEOID = character, four digit Census geography code, includes leading zeros
# NAME = character, Census geography names, includes state
# variable = character,values are
#   :'total' = all responses, regardless of race/ethnicity
#   :'A' = AIAN alone
#   :'AoIC' = AIAN alone or in combination
# estimate = integer, estimated population size for variable
# moe = integer, margin of error for estimate

# To create a wide table with total, AIAN-A, AIAN-AoIC:
# pivot_wider(out, id_cols = c("GEOID", "NAME"), names_from = variable, values_from = estimate) %>% 
#           mutate(AoIC = A + IC) %>% select(GEOID, NAME, total, A, AoIC)

# To call, specify the year of ACS you want, e.g. get_acs_popn_data(year = 2024)

# A Miller, adapted from E Silverman "get_popn_data_DECENNIAL_fn.R"

get_AIAN_popn_data_ACS.fn <- function(year = year,
                              acs_table = "acs5/profile",
                              geo = "american indian area/alaska native area/hawaiian home land",
                              dropNonFed = T) {
  
  library(tidycensus)
  library(tidyverse)
  
  # load variables for selected year and table
  variables <- load_variables(year, acs_table, cache=TRUE)
  
  # select all P8 variables with AIAN, as well as the total (_001N)
  var.select <- c("DP05_0001",
                  variables %>% 
                    filter(str_detect(name, "DP05_")) %>%
                    filter(label == "Estimate!!RACE!!Total population!!One race!!American Indian and Alaska Native" |
                             label ==  "Estimate!!Race alone or in combination with one or more other races!!Total population!!American Indian and Alaska Native") %>%
                    select(name) %>% pull)
  
  out <- get_acs(geography = geo, 
                 variables = var.select, 
                 year = year) %>%
    left_join(select(variables, name, label), by = c('variable' = 'name')) %>%
    mutate(variable = ifelse(variable == "DP05_0001", "total",
                             ifelse(str_detect(label, "One race"), "A", "AoIC"))) %>%
    select(-label)
  
  # To create a wide table with estimates of total, AIAN-A, AIAN-AoIC, uncomment:
  # out <- pivot_wider(out, id_cols = c("GEOID", "NAME"), names_from = variable, values_from = estimate) %>%
  #   select(GEOID, NAME, total, A, AoIC)
  
  if(dropNonFed) {
    # drop Native Hawaiian home lands
    out <- out %>% filter(!(as.numeric(GEOID) %in% c(5000:5499)))
    # drop state AIR and statistical areas, except 3 Fed recognized:
    out <- out %>% filter(!(as.numeric(GEOID) > 8999 & 
                              !(as.numeric(GEOID) %in% c(9260, 9370, 9815))))
    
  }
  
  out
}

