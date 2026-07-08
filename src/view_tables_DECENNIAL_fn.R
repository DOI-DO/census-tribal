# Function to identify tables and variables available for the Decennial Census

# 22-April-2026 E Silverman

# Note: datasets described here are for the 2000, 2010, and 2020 census. See Census Bureau documentation
# https://www.census.gov/data/developers/data-sets/decennial-census.html
# NOte that variable name format differs between 2020 and 2000/2010. 
# 2000 "profile" name convention is different from same datatset name, not "profile" 

view_tables_decennial.fn <- function(year = 2020, dataset = "dhc", output_method = "v") {

  # dataset values relevant for 2020 are: 
  # pl = redistricting data
  # dp = demographic profile
  # dhc = demographic and housing
  # ddhca = detailed demographic and housing A
  # ddhcb = detailed demographic and housing B
  # sdhc = supplemental demographic and housing
  
  # dataset values relevant for 2010 are:
  # pl = redistricting data
  # sf1 = summary file 1
  # sf2 = summary file 2
  
  # dataset values relevant for 2000 are:
  # pl = redistricting
  # sf1 = summary file 1
  # sf2 = summary file 2
  # sf2profile = demographic profile 
  # sf3 = summary file 3
  # sf3profile = sf2 demographic profile
  # sf4 = summary file 4
  # sf4profile = sf4 demographic profile
  # aian = AIAN summary file
  # aianprofile = AIAN demographic profile
  # as = island areas
  
  
  # output_method = option for output with "p" = print to screen, "v" = View
  # point to object and answer "t" or "v" to last question to save output to an object
  
  library(tidyverse)
  library(tidycensus)
  
  file.info <- 
    load_variables(
      year = year,
      dataset = dataset,
      cache = FALSE
    ) 
  
  table.info <- distinct(file.info %>% 
                    mutate(table = ifelse(str_detect(name, "_"), 
                                          str_split_i(name, "_",1),
                                          str_sub(name, 1, (nchar(name)-3)))
                           ) %>% 
                    select(table, concept)) %>%
          filter(str_sub(table, nchar(table)) %in% c(0:9) | str_detect(concept, "AMERICAN INDIAN"))
  
  if (output_method == "p") {
    print(table.info, n = Inf) 
    } else {
      if (output_method == "v") {
        View(table.info) } 
    }

  cat("\n Do you want to see the variables associated with a table? \n")
  cat("\n If yes, type in the table name. \n\n")
  
  table.request <- readline(prompt = "If no, type 'no'  ")
  
  while (table.request != "no") {
    
    variable.info <- file.info %>% 
      mutate(table = ifelse(str_detect(name, "_"), 
                                    str_split_i(name, "_",1),
                                    str_sub(name, 1, (nchar(name)-3)))) %>%
      filter(table == table.request) %>%
      select(variable = name, label)
    
    if (nrow(variable.info) == 0) {
      cat("\n You have typed in an invalid table. \n")
    } else {
      if(output_method == "p") {
        print(variable.info,
              n = Inf)
      } else {
        if(output_method == "v") {
          View(variable.info)
        }
      }
    }
  
    cat("\n Do you want to see the variables associated with another table? \n")
    cat("\n If yes, type in the table name. \n\n")
    
    table.request <- readline(prompt = "If no, type 'no'  ")
    
  }

  cat("\n Do you want to save the last table (yes, type 't') or variable information (yes, type 'v') to an object? \n")
  
  ANSWER <- readline(prompt = "If no, type 'no'  ")
  
  if (ANSWER == "t") {
    table.info
  } else {
    if (ANSWER == "v") {
      variable.info
    }
  }
 
}

