# Wrappers around get_census_table.fn() for pulling AIAN "(or part)" geographies
# E Silverman 29-July-2026 with Claude Opus 4.8
#
# Rev 25-Aug-2026: added .pad_fips() leading-zero guard + validation on all
#                  GEOID / FIPS entry paths (character vector, GEOID column,
#                  state/county/tract columns, and user-supplied `states`).
#
# Two use cases:
#   pull_aian_within_state.fn()  -- AIAN areas broken out WITHIN each state
#                                   (summary level whose requires == "state";
#                                    e.g. 280 in 2010 SF1)
#   pull_aian_in_tracts.fn()     -- given a set of tracts (e.g. opportunity
#                                   zones), find which contain an AIAN part and
#                                   pull data for those parts (summary level
#                                   whose requires == state|county|tract;
#                                   e.g. 144 in 2010 SF1)
#
# Both DISCOVER the right summary level from get_dataset_geographies.fn()'s
# 'requires' field rather than hardcoding a geoLevelDisplay, so they work
# across datasets (2010 SF1, 2020 DHC, ACS5, etc.).
#
# Requires in scope: get_dataset_geographies.fn(), get_census_table.fn()
# ---------------------------------------------------------------------------

library(dplyr)

# Internal: zero-pad numeric-looking FIPS/GEOID values that lost leading zeros
# (the classic CSV/Excel auto-typing hazard: "06" -> 6, "06001400100" -> a
# number that drops the leading 0). Only pads values that are all-digits AND
# shorter than `width`; correct-width and non-numeric values pass through
# untouched. Uses double (%.0f) not integer so 11-digit GEOIDs survive
# (they exceed .Machine$integer.max but are exact as doubles).
.pad_fips <- function(x, width) {
  x <- as.character(x)
  fix <- grepl("^[0-9]+$", x) & nchar(x) < width
  x[fix] <- sprintf(paste0("%0", width, ".0f"), as.numeric(x[fix]))
  x
}

# Internal: find AIAN geography rows whose parent chain exactly matches `chain`.
# `chain` is a character vector, e.g. c("state") or c("state","county","tract").
.find_aian_levels <- function(geos, chain) {
  geos %>%
    filter(!is.na(requires)) %>%
    mutate(.req = strsplit(requires, "\\|")) %>%
    filter(vapply(.req, function(r) identical(r, chain), logical(1))) %>%
    select(-.req)
}

# ---------------------------------------------------------------------------
# USE CASE 1: AIAN areas within each state
# ---------------------------------------------------------------------------
pull_aian_within_state.fn <- function(year, program, sumfile, table_id,
                                      states = NULL,   # optional vector of
                                      # state FIPS; if NULL,
                                      # tries state:* then
                                      # falls back to all states
                                      key = Sys.getenv("CENSUS_API_KEY")) {
  
  # Guard user-supplied state codes (tidycensus default is already padded).
  if (!is.null(states)) {
    states <- .pad_fips(states, 2)
    bad <- nchar(states) != 2
    if (any(bad))
      stop("state FIPS not 2 digits after padding: ",
           paste(unique(states[bad]), collapse = ", "))
  }
  
  geos <- get_dataset_geographies.fn(year, program, sumfile, subsetAIAN = T)
  if (is.null(geos)) stop("Could not fetch geographies for this dataset.")
  
  lv <- .find_aian_levels(geos, c("state"))
  if (nrow(lv) == 0)
    stop("No within-state AIAN level (requires == 'state') found for ",
         program, "/", sumfile, " ", year, ".")
  
  results <- list()
  for (i in seq_len(nrow(lv))) {
    nm  <- lv$name[i]
    geo <- paste0(nm, ":*")
    
    # If the caller gave no state list, try state:* first -- one call may cover
    # the nation (metadata under-reports top-container wildcard support). If the
    # caller DID specify states, respect that and never wildcard past it. This
    # also makes ANRCs (level 230) behave with no special-casing: with states
    # supplied, non-AK states 204 and drop out; with states = NULL, the probe
    # returns all ANRCs (all in AK) in a single call.
    if (is.null(states)) {
      df <- get_census_table.fn(year, program, sumfile, table_id,
                                geography = geo, in_geo = c(state = "*"), key = key)
      if (!is.null(df)) {
        df$.aian_level <- nm
        results[[length(results) + 1]] <- df
        next
      }
    }
    
    # Loop states one at a time: the supplied list, or (if the wildcard probe
    # above failed) a full FIPS list.
    st <- states
    if (is.null(st)) {
      if (requireNamespace("tidycensus", quietly = TRUE)) {
        st <- unique(tidycensus::fips_codes$state_code)
      } else {
        stop("state:* not supported for this level and no `states` supplied ",
             "(and tidycensus isn't available for a default FIPS list). ",
             "Pass states = c(\"01\",\"02\",...).")
      }
    }
    for (s in st) {
      d <- get_census_table.fn(year, program, sumfile, table_id,
                               geography = geo, in_geo = c(state = s), key = key)
      if (!is.null(d)) {
        d$.aian_level  <- nm
        d$.query_state <- s
        results[[length(results) + 1]] <- d
      }
    }
  }
  
  if (length(results) == 0) return(NULL)
  bind_rows(results)
}

# ---------------------------------------------------------------------------
# USE CASE 2: which of my tracts contain an AIAN part -- and pull it
# ---------------------------------------------------------------------------
# `tracts` may be:
#   - a character vector of 11-digit GEOIDs ("06001400100"), or
#   - a data frame with a GEOID column, or
#   - a data frame with state / county / tract columns (2 / 3 / 6 digits)
#
# Returns one combined data frame containing only the tracts that HAD an AIAN
# part (others return 204 -> NULL -> skipped). Each row is tagged with
# .query_tract (which of your tracts produced it) and .aian_level. Tracts with
# no AIAN part are simply absent from the result -- that absence IS the
# "no intersection" answer.
pull_aian_in_tracts.fn <- function(year, program, sumfile, table_id,
                                   tracts,
                                   key = Sys.getenv("CENSUS_API_KEY"),
                                   verbose = TRUE) {
  
  parse_geoid <- function(g) {
    g <- .pad_fips(g, 11)
    if (any(is.na(g))) stop("GEOID vector contains NA.")
    bad <- nchar(g) != 11
    if (any(bad))
      stop("GEOIDs not 11 digits after padding: ",
           paste(unique(g[bad]), collapse = ", "))
    data.frame(GEOID  = g,
               state  = substr(g, 1, 2),
               county = substr(g, 3, 5),
               tract  = substr(g, 6, 11),
               stringsAsFactors = FALSE)
  }
  
  # Normalize input to a state/county/tract/GEOID data frame.
  if (is.character(tracts)) {
    tdf <- parse_geoid(tracts)
  } else if (is.data.frame(tracts)) {
    if (all(c("state", "county", "tract") %in% names(tracts))) {
      tdf <- tracts
      tdf$state  <- .pad_fips(tdf$state,  2)
      tdf$county <- .pad_fips(tdf$county, 3)
      tdf$tract  <- .pad_fips(tdf$tract,  6)
      built <- paste0(tdf$state, tdf$county, tdf$tract)
      # If a GEOID column was also supplied, the components win -- but warn on
      # disagreement, since that usually means an upstream join went wrong.
      if ("GEOID" %in% names(tdf) && !all(tdf$GEOID == built))
        warning("Existing GEOID column disagrees with state/county/tract; ",
                "using the state/county/tract components.")
      tdf$GEOID <- built
      bad <- nchar(tdf$GEOID) != 11
      if (any(bad))
        stop("Assembled GEOIDs not 11 digits: ",
             paste(unique(tdf$GEOID[bad]), collapse = ", "))
    } else if ("GEOID" %in% names(tracts)) {
      tdf <- parse_geoid(tracts$GEOID)
    } else {
      stop("`tracts` data frame needs a GEOID column or state/county/tract columns.")
    }
  } else {
    stop("`tracts` must be a character vector of 11-digit GEOIDs or a data frame.")
  }
  
  geos <- get_dataset_geographies.fn(year, program, sumfile, subsetAIAN = TRUE)
  if (is.null(geos)) stop("Could not fetch geographies for this dataset.")
  
  lv <- .find_aian_levels(geos, c("state", "county", "tract"))
  if (nrow(lv) == 0)
    stop("No within-tract AIAN level (requires == state|county|tract) found ",
         "for ", program, "/", sumfile, " ", year, ".")
  
  results <- list()
  n <- nrow(tdf)
  for (j in seq_len(n)) {
    r <- tdf[j, ]
    if (verbose) message(sprintf("[%d/%d] tract %s", j, n, r$GEOID))
    
    for (i in seq_len(nrow(lv))) {
      nm  <- lv$name[i]
      geo <- paste0(nm, ":*")
      d <- get_census_table.fn(
        year, program, sumfile, table_id,
        geography = geo,
        in_geo    = c(state = r$state, county = r$county, tract = r$tract),
        key       = key
      )
      if (!is.null(d)) {
        d$.aian_level  <- nm
        d$.query_tract <- r$GEOID
        results[[length(results) + 1]] <- d
      }
    }
  }
  
  if (length(results) == 0) {
    if (verbose) message("No AIAN parts found in any of the supplied tracts.")
    return(NULL)
  }
  bind_rows(results)
}