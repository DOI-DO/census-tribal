# This function pulls the variable names, labels , concepts and group (table) from
# the variables.json associated with a Census dataset.

# Use it to identify the table_id to specifiy in get_census_table.fn

# Originally was using load_variables from tidycensus for this purpose but
# Census is not consistent between products in the relationship between the 
# variable name and the group code. 

# 9-July-2026 E Silverman with Claude Chat

# ---------------------------------------------------------------------------
# get_table_ids.fn()
# Pulls variables.json directly for any year/program/sumfile combination and
# returns a clean data frame of real variables with their authoritative
# 'group' (table_id), bypassing tidycensus::load_variables() entirely.
#
# This avoids two problems seen in practice:
#   1. tidycensus's table/variable inference is inconsistent across years
#      and products (e.g. 2010 SF1 variable P029007 belongs to group "P29",
#      not "P029" as naive inference from the variable name would suggest).
#   2. variables.json itself includes non-variable structural/metadata
#      entries (e.g. "for"/"in" geography predicates, and fields like
#      GEO_ID/NAME) that must be excluded -- GEO_ID in particular has been
#      observed (2010 SF1) to carry a malformed 'group' value containing a
#      giant comma-separated list of unrelated table IDs, rather than a
#      real group or NA. These structural fields are excluded by name.
# ---------------------------------------------------------------------------
get_table_ids.fn <- function(year, program, sumfile) {
  
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
  )
  
  # Exclude known non-variable structural/metadata fields. These aren't
  # real data variables and can carry malformed or meaningless 'group'
  # values (see GEO_ID note above).
  structural_fields <- c("GEO_ID", "NAME")
  vars_df <- vars_df %>% filter(!(name %in% structural_fields))
  
  # Safety net: also drop anything whose group value itself looks
  # malformed (comma-separated list) in case other structural fields
  # with the same issue turn up in future datasets.
  malformed <- grepl(",", vars_df$group)
  if (any(malformed)) {
    message("Excluded ", sum(malformed), " row(s) with malformed (comma-separated) group values: ",
            paste(vars_df$name[malformed], collapse = ", "))
    vars_df <- vars_df[!malformed, ]
  }
  
  vars_df
}

# Example:
# sf1_2010_vars <- get_table_ids.fn(year = 2010, program = "dec", sumfile = "sf1")
# unique(sf1_2010_vars$group)
