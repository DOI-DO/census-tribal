# Function to pull table from 2020 decennial DDHC-A and -B datasets
# ... for these datasets, tidycensus does not work for table specifications, only variables

# This pulls the whole table (all variables for all popn groups) and must be run
# with wrap around code to subset to AIAN population groups of interest

# 7-July-2026 E Silverman, written with Claude Chat

# ---------------------------------------------------------------------------
# get_table_decennial_ddhc.fn()
# Pulls an entire DDHC-A or DDHC-B table (all variables via group()) for specified
# geography and all population groups, cleans duplicate columns, and converts
# Census suppression sentinel codes (e.g. -888888888) to NA.
# ---------------------------------------------------------------------------
get_table_decennial_ddhc.fn <- function(table_id,
                                        sumfile = "ddhca",
                                        key,
                                        geography = "american indian area/alaska native area/hawaiian home land:*") {
  
  library(httr)
  library(jsonlite)
  library(dplyr)
  
  base_url <- paste0("https://api.census.gov/data/2020/dec/", sumfile)
  
  # Encode the geography string so spaces/slashes don't break the URL
  geography_encoded <- URLencode(geography)
  
  # NOTE: POPGROUP is deliberately left out of get= since it's already
  # supplied as a filter below (&POPGROUP=*) -- including it in both
  # places is what caused the duplicate-column error.
  if (sumfile %in% c("ddhca", "ddhcb")) {
    url <- paste0(
      base_url,
      "?get=NAME,group(", table_id, "),POPGROUP_LABEL",
      "&for=", geography_encoded,
      "&POPGROUP=*",
      "&key=", key
    )
  } else if (sumfile == "sdhc") {
    url <- paste0(
      base_url,
      "?get=NAME,group(", table_id, ")",
      "&for=", geography_encoded,
      "&key=", key
    )
  } else {
    # Generic fallback for other decennial sumfiles (dhc, pl, etc.) --
    # no POPGROUP, standard group() request.
    url <- paste0(
      base_url,
      "?get=NAME,group(", table_id, ")",
      "&for=", geography_encoded,
      "&key=", key
    )
  }
  
  response <- GET(url)
  
  if (status_code(response) != 200) {
    warning(paste0(
      "Request failed for table ", table_id,
      " with status: ", status_code(response),
      " -- this may indicate no data available for this table/geography ",
      "combination (adaptive design gap)."
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
  
  # Identify the actual estimate columns for this table (pattern: T02001_001N, etc.)
  # est_cols <- grep(paste0("^", table_id, "_\\d{3}N$"), colnames(df), value = TRUE)
  est_cols <- grep(paste0("^", table_id, "(_\\d{3}N|_COL\\d+_R\\d+)$"), colnames(df), value = TRUE)
  
  if (length(est_cols) == 0) {
    message("No columns matched the expected '", table_id, "_###N' pattern. ",
            "Skipping suppression-code cleanup -- check colnames(df) manually.")
  } else {
    df <- df %>%
      mutate(across(all_of(est_cols), as.numeric)) %>%
      mutate(across(all_of(est_cols), ~ ifelse(. < 0, NA, .)))
  }
  
  df
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
my_key <- "YOUR_KEY"

t01001 <- get_ddhc_table("T01001", sumfile = "ddhca", key = my_key)
t02001 <- get_ddhc_table("T02001", sumfile = "ddhca", key = my_key)

head(t02001)
colnames(t02001)

# ---------------------------------------------------------------------------
# Optional: pull multiple tables in one pass and stack/store as a named list
# ---------------------------------------------------------------------------
pull_multiple_ddhc_tables <- function(table_ids, sumfile = "ddhca", key) {
  results <- lapply(table_ids, function(tid) {
    message("Pulling table: ", tid)
    get_ddhc_table(tid, sumfile = sumfile, key = key)
  })
  names(results) <- table_ids
  results
}

# Example:
# tables_needed <- c("T01001", "T02001", "T03001")
# all_tables <- pull_multiple_ddhc_tables(tables_needed, key = my_key)
# all_tables$T02001  # access individual table results