# Create descriptive cross-walk file 

# 7-April-2026 E Silverman

# This function reads in the Fed Reg Notice Entity x Census AIAN geography file (inFile1)
# inFile1 uses the FRN Entity CICD 'neid_mid' code to identify FRN entities

# The function also reads in the table listing the CICD codes along with full
# FRN names (inFile2)
# The names file includes a date code for the name, currently referenced to 
# the 11-Dec-2024 FRN, i.e., most entities have this date. There are additioanl
# earlier dates if the name was different in the Jan 2024 or Jan 2026 FRN

# Function will use the MOST recent date for each neid_mid code.

# See repository data README for file column descriptions.
# Function presumes column names in repository files.

create_descriptive_crosswalk.fn <- function(Path, 
                                inFile1 = "census-tribal_FRNEntityCICD_CensusGeography.csv", 
                                inFile2 = "census-tribal_CICDEntityID_FRNName.csv") {

  # Path = File Path
  # inFile1 = name of file with CICD entity x Census Geo for FRN Tribes/Native Villages
  # inFile2 = name of file with full listing of CICD entity codes x past FRN names and dates
  
  library(tidyverse)
  
  # read FRN entity x Census geo crosswalk
  crosswalk <- read.csv(paste0(Path, inFile1))
  # read CICD entity code, FRN name file
  # NOTE: need encoding specified to interpret em dashes, need to convert FRN_Date to date format
  FRN_names <- read.csv(paste0(Path, inFile2), fileEncoding = "Windows-1252") %>%
    mutate(FRN_Date = as.Date(FRN_Date, format = "%m/%d/%Y"))
  
  # subset to most recent FRN text name for each entity:
  FRN_names <- FRN_names %>% group_by(neid_mid) %>% 
    mutate(ind = (FRN_Date == max(FRN_Date))) %>% ungroup() %>% 
    filter(ind) %>% select(-ind)
  
  full_crosswalk <- left_join(crosswalk, FRN_names)
  
  full_crosswalk
  }