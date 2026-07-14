# This function pulls the variable names, labels, concepts and group 
# from the variables.json associated with a Census dataset.

# Use it to identify the table_id (group)to specify in get_census_table.fn

# Originally we were using load_variables from tidycensus for this purpose but
# Census coding is not consistent between products with respect to the relationship  
# between the variable name and the group code ... instead of trying to manage all
# the changes and exceptions, this code loads both table and variable.

# 9-July-2026 E Silverman with Claude Chat

# ---------------------------------------------------------------------------
# get_table_ids.fn()
# Pulls variables.json directly for any year/program/sumfile combination and
# returns a clean data frame of real variables with their authoritative
# 'group' (table_id), bypassing tidycensus::load_variables().
#
# This code manages two problems:
#   1. Census's table/variable inference is inconsistent across years
#      and products (e.g. 2010 SF1 variable P029007 belongs to group "P29",
#      not "P029" as naive inference from the variable name would suggest).
#   2. variables.json itself includes non-variable structural/metadata
#      entries (e.g. "for"/"in" geography predicates, and fields like
#      GEO_ID/NAME) that must be excluded -- GEO_ID in particular has been
#      observed (2010 SF1) to carry a malformed 'group' value containing a
#      giant comma-separated list of unrelated table IDs, rather than a
#      real group or NA. These structural fields are excluded by name.
# ---------------------------------------------------------------------------
get_table_ids.fn <- function(year, program, sumfile, subsetAIAN = T) {
 
  # year = YYYY, 
  # program = "dec" for decennial or "acs" for American Community Survey 
  # sumfile = "dhc", "pl", "sf1", "acs5", "acs5/profile", etc. for Census data 
  # subsetAIAN = logical, default TRUE: subset to basic tables and AIAN alone,
  # .... this is *usually* tables ending in numbers or AIAN letters (e.g., C = AIAN along)
  
  url <- paste0("https://api.census.gov/data/", year, "/", program, "/", sumfile, "/variables.json")
  response <- GET(url)
  
  if (status_code(response) != 200) {
    warning(paste0("Failed to retrieve variables.json for ", program, "/", sumfile,
                   " (", year, ") -- status ", status_code(response)))
    return(NULL)
  }
  
  data <- fromJSON(content(response, "text"), flatten = TRUE)
  vars_list <- data$variables
  
  # Drop "for"/"in" geography predicate entries (predicateOnly == TRUE)
  is_real_variable <- function(x) {
    is.null(x$predicateOnly) || x$predicateOnly == FALSE
  }
  real_vars <- vars_list[sapply(vars_list, is_real_variable)]
  
  vars_df <- data.frame(
    name = names(real_vars),
    label = sapply(real_vars, function(x) if (is.null(x$label)) NA else x$label),
    concept = sapply(real_vars, function(x) if (is.null(x$concept)) NA else x$concept),
    group = sapply(real_vars, function(x) if (is.null(x$group)) NA else x$group),
    stringsAsFactors = FALSE
  ) %>% # Improve label readability
    mutate(label = str_trim(label)) %>%
    mutate(label = ifelse(str_sub(label, 1, 2) == "!!", 
                         str_sub(label, 3, 
                                 nchar(label)), label)) %>%
    mutate(label = str_replace_all(label, "!!", "_")) # Improve label readability
  
  # Exclude known non-variable structural/metadata fields. These aren't
  # real data variables and can carry malformed or meaningless 'group'
  # values (see GEO_ID note above).
  structural_fields <- c("GEO_ID", "NAME")
  vars_df <- vars_df %>% filter(!(name %in% structural_fields | (group == "N/A" & !is.na(group))))
  
  # Safety net: also drop anything whose group value itself looks
  # malformed (comma-separated list) in case other structural fields
  # with the same issue turn up in future datasets.
  malformed <- grepl(",", vars_df$group)
  if (any(malformed)) {
    message("Excluded ", sum(malformed), " row(s) with malformed (comma-separated) group values: ",
            paste(vars_df$name[malformed], collapse = ", "))
    vars_df <- vars_df[!malformed, ]
  }
  
 row.names(vars_df) <- c(1:nrow(vars_df))
  
  if (subsetAIAN) {
    # resolve a case with concept = NA in all cases
    vars_df <- vars_df %>% mutate(concept = ifelse(is.na(concept), "N/A", concept))
    
    vars_df <- vars_df %>% filter((str_sub(group, nchar(group)) %in% c(0:9) &
                                  # odd cases with numeric end and another race, not AIAN:
                                  !((str_detect(concept, "ASIAN") | 
                                       str_detect(concept, "WHITE") | 
                                       str_detect(concept, "BLACK") | 
                                       str_detect(concept, "HAWAIIAN")) & 
                                      !str_detect(concept, "AMERICAN INDIAN")))
                               # or includes AIAN in concept description:
                               | str_detect(concept, "AMERICAN INDIAN"))
  }
  
  vars_df
}

# Example:
# sf1_2010_vars <- get_table_ids.fn(year = 2010, program = "dec", sumfile = "sf1")
# unique(sf1_2010_vars$group)
