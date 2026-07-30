# Code to list geographies associated with a Census data product

# E Silverman 29-July-2026

# This function repeats some code used to process the api call from the 
# get_census_table.fn function which was written with Claude Chat. This function
# was also debugged and reworked with Claude to resolve the nested geo issue.

# Output is a dataframe with geography 'name', 3-digit Census 'geoLevelDisplay'
# code, the reference date, AND the nesting metadata needed to query the geo:
#   requires          - pipe-separated parent levels that mu st appear in &in=
#   wildcard          - pipe-separated subset of parents that may be ':*'
#   optionalWithWCFor - parent that may be omitted (implicitly wildcarded)
#   nested            - TRUE if the level requires an &in= clause
#
# output can be all supported geographies or subset to AIAN only (subsetAIAN parameter)

get_dataset_geographies.fn <- function(year,
                                       program,      # "dec" or "acs"
                                       sumfile,      # e.g. "ddhca", "sf1", "acs5", "acs5/aian"
                                       subsetAIAN = T # if TRUE include only AIAN geos in output
) {
  
  library(tidyverse)
  library(httr)
  library(jsonlite)
  
  url <- paste("https://api.census.gov/data",year,program,sumfile,"geography.json", sep = "/")
  
  response <- GET(url)
  
  if (status_code(response) != 200) {
    warning(
      "Request failed -- check that input parameters are correct."
    )
    return(NULL)
  }

  body <- content(response, "text", encoding = "UTF-8")
  
  if (nchar(trimws(body)) == 0) {
    warning("Empty response body for table -- no content returned.")
    return(NULL)
  } 
  
  data <- fromJSON(body, flatten = TRUE)
  
  fips <- as_tibble(data$fips)
  cn   <- names(fips)
  
  # requires / wildcard come back as list-columns (variable-length arrays);
  # some datasets omit them entirely, and non-nested rows carry NULL.
  # Collapse each to a single pipe-separated string, NA where absent.
  collapse_list_col <- function(col) {
    if (is.null(col)) return(NA_character_)
    if (!is.list(col)) col <- as.list(col)
    vapply(col, function(v) {
      if (is.null(v)) return(NA_character_)
      v <- v[!is.na(v) & nzchar(v)]
      if (length(v) == 0) NA_character_ else paste(v, collapse = "|")
    }, character(1))
  }
  
  fips$requires <- if ("requires" %in% cn)
    collapse_list_col(fips$requires) else NA_character_
  
  fips$wildcard <- if ("wildcard" %in% cn)
    collapse_list_col(fips$wildcard) else NA_character_
  
  fips$optionalWithWCFor <- if ("optionalWithWCFor" %in% cn)
    as.character(fips$optionalWithWCFor) else NA_character_
  
  fips$nested <- !is.na(fips$requires)
  
  out <- fips %>%
    select(any_of(c("name", "geoLevelDisplay", "referenceDate",
                    "requires", "wildcard", "optionalWithWCFor", "nested")))
  
  if (subsetAIAN) {
    
    out <- out %>% 
      filter(str_detect(name, "indian|home land|tribal|native|trust land"))  
  }
  
  out
}


