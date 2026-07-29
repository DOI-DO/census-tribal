# This function pulls data from Census decennial or ACS

# Similar to get_decennial and get_acs from tidycensus which were not
# working for some datasets (e.g., 2020 decennial ddhcb amd acs/aian and spt tables)

# 9-July-2-26 E Silverman with Claude Chat
# 29-July-2026 added in_geo for nested geographies (tract, block group, etc.)

# ---------------------------------------------------------------------------
# get_census_table.fn()
# General-purpose function to pull from any Census decennial or ACS API dataset,
# including nested sumfile paths like "acs/acs5/aian") that aren't well
# supported by tidycensus (e.g. ddhca, ddhcb, sdhc, or ACS subject-population
# tables like AIAN/1-year Puerto Rico, etc.)
#
# Handles:
#   - DDHCA/DDHCB: adaptive-design POPGROUP wildcard dimension (pulls all pop groups)
#   - SDHC: race/ethnicity are specified by the table_id, no POPGROUP
#   - ACS / other dec sumfiles: standard group() pull, no POPGROUP
#   - Nested geographies via in_geo (e.g. tract requires state; block group
#     requires state + county)
#
# Cleans duplicate columns and converts Census suppression sentinel codes
# (e.g. -888888888, -999999999) to NA.
# ---------------------------------------------------------------------------
get_census_table.fn <- function(year,
                                program,      # "dec" or "acs"
                                sumfile,      # e.g. "ddhca", "sf1", "acs5", "acs5/aian"
                                table_id,
                                geography = "state:*",
                                in_geo    = NULL, # named vector of parent
                                # level -> code, e.g.
                                # c(state = "06", county = "*")
                                # Get parents from the
                                # 'requires' field of
                                # get_dataset_geographies.fn().
                                key = Sys.getenv("CENSUS_API_KEY")
                                # defaults to the CENSUS_API_KEY
                                # env var (set in .Renviron or
                                # via Sys.setenv()) so the key
                                # never has to be typed into a
                                # script or land in a shared URL.
) {
  
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(stringr)
  
  if (!nzchar(key))
    stop("No Census API key. Set CENSUS_API_KEY (e.g. in .Renviron or via ",
         "Sys.setenv(CENSUS_API_KEY = \"...\")) or pass key= explicitly.")
  
  base_url <- paste0("https://api.census.gov/data/", year, "/", program, "/", sumfile)
  
  # Encode geography string so spaces/slashes (e.g. aian homeland geography name)
  # don't break the URL. URLencode() by default leaves *, &, =, : alone,
  # these are meaningful in the query string.
  geography_encoded <- URLencode(geography)
  
  # Build the &in= clause for nested geographies. in_geo is a NAMED vector
  # mapping each required parent level to its code, e.g.
  #   c(state = "06")                     -> &in=state:06
  #   c(state = "06", county = "*")       -> &in=state:06&in=county:*
  # Emit ONE &in= per parent (rather than a single space-separated &in=)
  # because some level names contain spaces or slashes (e.g. 'block group',
  # 'american indian area/alaska native area/hawaiian home land'), which are
  # ambiguous when packed into one &in=. URLencode() (no reserved=TRUE)
  # encodes those spaces/slashes but leaves ':' and '*' intact, matching the
  # &for= convention above.
  in_clause <- ""
  if (!is.null(in_geo) && length(in_geo) > 0) {
    pairs     <- paste0(names(in_geo), ":", unname(in_geo))
    encoded   <- vapply(pairs, URLencode, character(1))
    in_clause <- paste0(paste0("&in=", encoded), collapse = "")
  }
  
  # DDHCA/DDHCB use an adaptive-design POPGROUP dimension (race/ethnicity
  # "pop group" is a wildcard-able filter applied on top of the table).
  # SDHC instead has race/ethnicity encoded in the table ID (e.g., 'C' suffix)
  # for AIAN (e.g. PH1 = total, PH1C = AIAN alone) and does NOT accept a
  # POPGROUP parameter -- including it causes a 400 error.
  # NOTE: POPGROUP is left out of get= since it's already supplied as a
  # filter below when relevant -- including it in both places caused a
  # duplicate-column error for ddhca/ddhcb.
  base_sumfile <- tolower(strsplit(sumfile, "/")[[1]][1])  # e.g. "ddhca" from "ddhca", "acs5" from "acs5/aian"
  
  if (base_sumfile %in% c("ddhca", "ddhcb")) {
    url <- paste0(
      base_url,
      "?get=NAME,group(", table_id, "),POPGROUP_LABEL",
      "&for=", geography_encoded,
      in_clause,
      "&POPGROUP=*", # pull all popn groups, filter outside function
      "&key=", key
    )
  } else {
    # SDHC, ACS (including subtables like acs5/aian), and any other
    # standard sumfile -- plain group() pull, no POPGROUP.
    url <- paste0(
      base_url,
      "?get=NAME,group(", table_id, ")",
      "&for=", geography_encoded,
      in_clause,
      "&key=", key
    )
  }
  
  response <- GET(url)
  
  # 204 No Content: a VALID request that matched no rows (e.g. a within-tract
  # AIAN level for a tract that contains no AIAN part, or an adaptive-design
  # gap). Not an error -- return NULL quietly-ish so loops over many geos
  # don't spam alarming warnings for expected empty cells.
  if (status_code(response) == 204) {
    message(paste0("No data (204) for table ", table_id,
                   " at the requested geography -- valid request, empty result."))
    return(NULL)
  }
  
  if (status_code(response) != 200) {
    # Surface the API's own error text -- Census 400s usually say exactly
    # what's wrong (e.g. "unsupported geography hierarchy"), which is far
    # more diagnostic than the status code alone.
    err_body <- tryCatch(
      trimws(content(response, "text", encoding = "UTF-8")),
      error = function(e) ""
    )
    warning(paste0(
      "Request failed for table ", table_id,
      " (", program, "/", sumfile, ", ", year, ") with status: ", status_code(response),
      if (nzchar(err_body)) paste0("\n  API said: ", err_body) else "",
      "\n  -- check table_id validity, adaptive-design availability, ",
      "whether this sumfile accepts the parameters used, or whether the ",
      "geography's in_geo (parent) clause matches its 'requires' field."
    ))
    return(NULL)
  }
  
  body <- content(response, "text", encoding = "UTF-8")
  
  if (nchar(trimws(body)) == 0) {
    warning(paste0("Empty response body for table ", table_id, " -- no content returned."))
    return(NULL)
  }
  
  data <- fromJSON(body, flatten = TRUE)
  df <- as.data.frame(data[-1, ], stringsAsFactors = FALSE)
  colnames(df) <- data[1, ]
  
  # De-duplicate any repeated column names (e.g. POPGROUP echoed twice)
  if (any(duplicated(colnames(df)))) {
    dupes <- colnames(df)[duplicated(colnames(df))]
    message(paste0("Removed duplicate column(s): ", paste(unique(dupes), collapse = ", ")))
    df <- df[, !duplicated(colnames(df))]
  }
  
  # Identify the actual estimate + MOE columns for this table. Matches:
  #   - flat suffix style:   T02001_001N, B01001_001E (estimate), B01001_001M (MOE)
  #   - additional flat suffix style: DP1_0001C (count), DP1_0001P (percent)
  #   - row/col matrix style: PH1_COL1_R1
  # Excludes annotation columns (trailing A, e.g. _001EA/_001MA/_001NA) since
  # those are flags/text, not numeric values to clean.
  est_cols <- grep(paste0("^", table_id, "(_\\d{3}[NEM]|_\\d{4}[CP]|_COL\\d+_R\\d+)$"), colnames(df), value = TRUE)
  
  if (length(est_cols) == 0) {
    message("No columns matched the expected '", table_id, "' estimate pattern. ",
            "Skipping suppression-code cleanup -- check colnames(df) manually.")
  } else {
    df <- df %>%
      mutate(across(all_of(est_cols), as.numeric)) %>%
      mutate(across(all_of(est_cols), ~ ifelse(. < 0, NA, .)))
  }
  
  df
}