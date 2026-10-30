# derive_denominator_stems.fn()
# E Silverman with Claude Chat Opus 4.8
# 20-OCt-2026

# ---------------------------------------------------------------------------
# Finds the "denominator / section-universe" variables in an ACS PROFILE table
# (DP02/DP04/DP05/...), whose percent-estimate (PE) column is a PLACEHOLDER:
# the API copies the COUNT into the PE slot (because a section total's percent
# is 100% by defintion), and flags PM as "(X)". These must be distinguished
# from real percentages.
#
# METHOD -- why it needs many geographies:
#   A denominator has PE == E in EVERY geography (it's structurally a copied
#   count). A real sub-share can have PE == E coincidentally -- most often when
#   the count is 0 (so percent is 0 too), which is PERVASIVE in AIAN popgroup
#   data where many tribes have 0 count in a given area. That zero-count
#   coincidence smears PE==E across a third of cells and makes any single-pull
#   or single-geography test unreliable. The ONLY robust signal is PE == E
#   across MANY geographies: frac_equal == 1.0 exactly. A sub-share can't reach
#   1.0 because its nonzero geographies have real percents != their counts.
#
#   THEREFORE this derivation REFUSES to run on too few distinct geographies --
#   returning a list derived from 1-2 geographies would silently misflag
#   zero-count sub-shares as denominators. Derive once on a rich (e.g. national,
#   all-states or all-popgroups) pull, SAVE the result, and feed it to
#   label_census_vars.fn for all future pulls (including single-geography ones).
#
# Inputs:
#   long_df     - output of reshape_census_long.fn(); needs `variable`, `value`,
#                 and the geography id columns.
#   geo_id_cols - character vector of columns that together identify a distinct
#                 geography x subgroup (e.g. c("GEO_ID","POPGROUP")). Used to
#                 count how many distinct units we're comparing across.
#   min_geos    - refuse to derive if fewer than this many distinct geo units
#                 (default 30 -- enough that an all-1.0 result can't be
#                 zero-count luck).
#   tol         - |PE - E| < tol counts as "equal" (default 0.5).
#
# Returns: character vector of denominator stems (e.g. "DP02_0001"). Attreibutes
#   include the per-stem frac_equal table for auditing (attr "audit").
# ---------------------------------------------------------------------------
library(dplyr)
library(stringr)
library(tidyr)

derive_denominator_stems.fn <- function(long_df,
                                        geo_id_cols = c("GEO_ID", "POPGROUP"),
                                        min_geos = 30,
                                        tol = 0.5) {
  
  geo_id_cols <- intersect(geo_id_cols, names(long_df))
  if (length(geo_id_cols) == 0)
    stop("None of the geo_id_cols are in long_df -- pass the columns that ",
         "identify a distinct geography (e.g. GEO_ID, POPGROUP).")
  
  n_geos <- long_df %>% distinct(across(all_of(geo_id_cols))) %>% nrow()
  if (n_geos < min_geos)
    stop("Only ", n_geos, " distinct geographies found (need >= ", min_geos,
         "). Denominator derivation is UNRELIABLE on few geographies because ",
         "zero-count sub-shares coincidentally have PE == E. Derive this list ",
         "on a rich multi-geography pull, save it, and pass it to ",
         "label_census_vars.fn for smaller/single-geography pulls.")
  
  # Keep only E and PE rows; pair them per geo x stem.
  wide <- long_df %>%
    mutate(stem = str_remove(variable, "P?E$"),
           kind = case_when(str_detect(variable, "PE$") ~ "PE",
                            str_detect(variable, "E$")  ~ "E",
                            TRUE ~ NA_character_)) %>%
    filter(!is.na(kind)) %>%
    select(all_of(geo_id_cols), stem, kind, value) %>%
    pivot_wider(names_from = kind, values_from = value)
  
  if (!all(c("E", "PE") %in% names(wide)))
    stop("Could not form E/PE pairs -- check that `variable` holds full column ",
         "names like DP02_0001E / DP02_0001PE.")
  
  audit <- wide %>%
    mutate(pe_eq_e = abs(PE - E) < tol) %>%
    group_by(stem) %>%
    summarise(frac_equal = mean(pe_eq_e, na.rm = TRUE),
              n_compared = sum(!is.na(pe_eq_e)),
              .groups = "drop") %>%
    arrange(desc(frac_equal))
  
  # Denominators: PE == E in ALL compared geographies (exactly 1.0), with enough
  # comparisons to be meaningful.
  denom <- audit %>%
    filter(n_compared >= min_geos, frac_equal == 1) %>%
    pull(stem)
  
  structure(denom, audit = audit, n_geos = n_geos)
}