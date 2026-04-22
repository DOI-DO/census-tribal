# Function to identify tables and variables available for the Decennial Census

# 22-April-2026 E Silverman

# Note: datasets described here are for the 2020 census. See Census Bureau documentation
# or tidycensus for dataset names for 2000 and 2010 censuses.

# dataset values relevant for 2020 are 
# pl = redistricting data
# dp = demographic profile
# dhc = demographic and housing
# ddhca = detailed demographic and housing A
# ddhcb = detailed demographic and housing B
# sdhc = supplemental demographic and housing

# output_method = option for output with "p" = print to screen, "v" = View

view_tables_decennial.fn <- function(year = 2020, dataset = "dhc", output_method = "p") {
  
  library(tidyverse)
  library(tidycensus)
  
  file.info <- 
    load_variables(
      year = year,
      dataset = dataset,
      cache = FALSE
    ) 
  
  table.info <- distinct(file.info %>% 
                    mutate(table = str_split_i(name, "_",1)) %>% 
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
      mutate(table = str_split_i(name, "_",1)) %>%
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
  
 
}

