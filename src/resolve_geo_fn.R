# resolve_geo.fn()
# E Silverman 29-July-2026 coding with Claude
#
# Given the output of get_dataset_geographies.fn() and a target summary level
# (geoLevelDisplay), build the matching `geography` (for=) string and `in_geo`
# (in=) vector for get_census_table.fn().
#
# WHY THIS EXISTS: a geography 'name' is NOT unique -- the same name maps to
# many summary levels, each tabulated within a different parent (that's what
# "(or part)" means: the part of the area within that parent). e.g. for the
# AIAN/Hawaiian home land name, geoLevelDisplay 250 = the area as a whole,
# 280 = its within-state parts, 144 = its within-tract parts. Selecting by
# name alone is ambiguous; the summary level is the real key. This function
# forces name + requires to come from the SAME row, and validates parent
# codes against the 'requires'/'wildcard' fields before you spend a round
# trip on a 400.
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