
# Function necessary to create correct API call when downloading data for intersecting
# geographies that are not nested. Follows get_dataset_geographies.fn and supports
# get_census_table.fn.

# E Silverman 29-July-2026 coding with Claude Chat
#
# The geographies output from get_dataset_geographies_fn() may include repeated
# values for a geography "name" with different geoLevelDisplay codes. This
# is due to different products reporting results for different intersections of
# named geographies. For example, for the AIAN/Hawaiian home land name, 
# geoLevelDisplay 250 = the area as a whole, 280 = its within-state parts, 
# 144 = its within-tract parts. Selecting by name alone is ambiguous.
# The geoLevelDisplay code indicates the unique combination or
# 'name' + 'requires.' The 'name' in these cases typically includes "(or part)"
# because only a part of a named geography area may be represented: the part
# that intersects with the 'requires' geographies.

# The "requires" geographies must be specified in the API call. 

# Given the output of get_dataset_geographies.fn() and a target summary level
# (geoLevelDisplay), this function outputs information to build the correct 
# API call from the matching `geography` (for=) string and `in_geo`
# (in=) vector for get_census_table.fn().
#
#
# Returns a list: $geography (pass to geography=), $in_geo (pass to in_geo=).

resolve_geo.fn <- function(geos,             # output of get_dataset_geographies.fn()
                           geoLevelDisplay,  # target summary level, e.g. 280
                           parent_codes = NULL # named vector, e.g. c(state = "06")
) {
  
  library(dplyr)
  
  row <- geos %>% filter(geoLevelDisplay == !!as.character(geoLevelDisplay))
  
  if (nrow(row) == 0)
    stop("No geography with geoLevelDisplay == ", geoLevelDisplay, ".")
  if (nrow(row) > 1)
    stop("geoLevelDisplay ", geoLevelDisplay, " matched ", nrow(row),
         " rows -- expected exactly one.")
  
  for_str <- paste0(row$name, ":*")
  
  req <- if (is.na(row$requires)) character(0) else strsplit(row$requires, "\\|")[[1]]
  wc  <- if (is.na(row$wildcard)) character(0) else strsplit(row$wildcard, "\\|")[[1]]
  
  in_geo <- NULL
  if (length(req) > 0) {
    if (is.null(parent_codes))
      stop("Summary level ", geoLevelDisplay, " requires parent(s): ",
           paste(req, collapse = ", "),
           ".\n  Supply parent_codes as a named vector, e.g. c(",
           paste0(req, ' = "..."', collapse = ", "), ").")
    
    missing <- setdiff(req, names(parent_codes))
    if (length(missing) > 0)
      stop("Missing code(s) for required parent(s): ",
           paste(missing, collapse = ", "), ".")
    
    # order to match the requires chain (order matters to the API)
    in_geo <- parent_codes[req]
    
    # any parent given as '*' must be listed in 'wildcard', else the API 400s
    bad_wc <- req[in_geo == "*" & !(req %in% wc)]
    if (length(bad_wc) > 0)
      warning("Parent(s) not wildcard-able for this level (not in 'wildcard'): ",
              paste(bad_wc, collapse = ", "),
              ".\n  Supply real codes (loop over them if you need all) or ",
              "expect a 400.")
  }
  
  list(geography = for_str, in_geo = in_geo)
}