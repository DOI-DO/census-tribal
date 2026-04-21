# This function pulls population totals and AIAN totals (alone, in combination)
# from decennial census for AIAN home lands.

# NOTE: this includes 3 geographies belonging to federally recognized tribes
# with state-only areas: Lumbee (9815), Pamunkey (9260), Shinnecock (9370).

# NOTE!!
# Prior to running, source the tidycensus package and
# set the API key: census_api_key("MY KEY HERE").
# Include, "install = T" if you want to skip adding the key at every session.
# 

# Inputs:
# year = integer for 5-year interval from (year-5, year)
# sumfile = Decennial table to pull, dhc = 
# geo = character string indicate the AIAN geography product to select
# dropNonFed = logical, default = T, remove geographies not associated with federally-recognize entities

# default geography product is "american indian area/alaska native area/hawaiian home land"
# other possible geo sets:
# "alaska native regional corporation"
# "american indian area/alaska native area (reservation or statistical entity only)"

# Output: data frame with four columns
# GEOID = character, four digit Census geography code, includes leading zeros
# NAME = character, Census geography names, includes state
# variable = character,values are
#   :'total' = all responses, regardless of race/ethnicity
#   :'A' = AIAN alone
#   :'IC' = AIAN in combination
# value = integer, population size for variable

# NOTE: ACS5 tables are "Alone or in combination," while Decennial tables are
# "In combination," so Alone and In combination must be summed to calculate AoIC.

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
                             ifelse(variable == "P8_005N", "A", "IC"))) %>% z
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

