# label_census_vars.fn()
# E Silverman with Claude Chat Opus 4.8
# 20-Oct-2026

# ---------------------------------------------------------------------------
# Adds authoritative variable metadata to a long-format census table (the
# output of reshape_census_long.fn), using the variable labels from
# get_table_ids.fn().
#
# WHAT THIS DOES -- two separate jobs:
#   (1) ALWAYS: joins the variable LABEL from get_table_ids.fn and derives
#       `is_percent` (label starts "Percent" vs "Estimate") and a `measure_type`
#       from the E/M/PE/PM suffix. Useful on any table (incl. B-tables).
#   (2) ONLY IF denom_stems IS SUPPLIED: tags the "fake percent" placeholder
#       cells (see below). Without denom_stems this job is NOT done.
#
# THE "FAKE PERCENT" LANDMINE (profile tables) -- why the LABEL is NOT enough:
#   ACS profile tables (DP02/DP04/DP05) mix COUNT and PERCENT variables. For
#   DENOMINATOR / section-universe variables (e.g. "Total households"), the
#   percent is 100% by definition, so the API copies the COUNT into the PE
#   (percent-estimate) slot and flags PM as "(X)". The LABEL does NOT reveal
#   this -- the denominator's PE is still labeled "Percent_...Total households"
#   (the label describes the column's ROLE, not that the value is a count). So
#   is_percent alone will mislabel these as real percents.
#   The ONLY reliable way to identify the denominators is PE == E across MANY
#   geographies (frac_equal == 1.0), done ONCE by derive_denominator_stems.fn
#   on a rich pull and saved. That saved stem list is passed here as
#   `denom_stems` to tag the placeholder cells. WITHOUT it, this function
#   cannot solve the fake-percent problem -- it only does job (1), and (for a
#   profile table) emits a warning saying so.
#
# Inputs:
#   long_df    - output of reshape_census_long.fn(); must have a `variable`
#                column holding FULL column names (e.g. "DP02_0001E",
#                "DP02_0001PE") -- the same strings as the `name` field from
#                get_table_ids.fn().
#   var_labels - the data frame from get_table_ids.fn(year, program, sumfile).
#                Must contain `name` and `label` (and ideally `concept`).
#   denom_stems- OPTIONAL character vector of denominator/section-universe stems
#                (e.g. c("DP02_0001","DP02_0018",...)) indicating PE/PM columns that
#                are PLACEHOLDERS (the count copied into the percent slot). Derive
#                ONCE per profile table via derive_denominator_stems.fn on a
#                rich multi-geography pull, save it, and pass it here for ALL
#                pulls (including single-geography ones, where it can't be
#                re-derived). If NULL, no placeholder tagging is done.
#
# Adds columns:
#   label        - full Census label (e.g. "Percent_RACE_Total population_...")
#   concept      - table concept (if present in var_labels)
#   is_percent   - TRUE if label starts with "Percent", FALSE if "Estimate",
#                  NA if the variable didn't match / label is unrecognized
#   measure_type - "pct_est" / "pct_moe" / "count_est" / "count_moe" /
#                  "pct_placeholder" / NA. "pct_placeholder" marks the PE/PM of
#                  a denominator stem -- the value is a COUNT sitting in the
#                  percent slot, NOT a real percent. Value is LEFT AS-IS (tagged,
#                  not NA'd) so it's auditable; the caller filters it out, e.g.
#                    out %>% filter(measure_type != "pct_placeholder")
#
# Nothing is dropped -- the caller filters explicitly, e.g.
#   out %>% filter(is_percent, measure_type != "pct_placeholder")  # real % only
#   out %>% filter(measure_type == "count_est")                    # counts only
# ---------------------------------------------------------------------------
library(dplyr)
library(stringr)

label_census_vars.fn <- function(long_df, var_labels, denom_stems = NULL) {
  
  if (!"variable" %in% names(long_df))
    stop("long_df has no `variable` column -- pass the output of ",
         "reshape_census_long.fn().")
  if (!all(c("name", "label") %in% names(var_labels)))
    stop("var_labels must have `name` and `label` columns -- pass the output ",
         "of get_table_ids.fn().")
  
  keep <- intersect(c("name", "label", "concept"), names(var_labels))
  lbl  <- var_labels[, keep, drop = FALSE]
  
  # Report any variables that won't find a label, so a silent join miss doesn't
  # masquerade as "all counts" downstream.
  miss <- setdiff(unique(long_df$variable), lbl$name)
  if (length(miss) > 0)
    message(length(miss), " variable(s) had no match in var_labels (e.g. ",
            paste(head(miss, 3), collapse = ", "),
            "). Their label/is_percent will be NA.")
  
  # Warn if this looks like a profile table (has PE columns) but no denom_stems
  # were supplied -- the fake-percent placeholders will go UNtagged and look
  # like real percents.
  if (is.null(denom_stems) && any(str_detect(long_df$variable, "PE$")))
    warning("This looks like a profile table (PE columns present) but ",
            "denom_stems was not supplied. Denominator/section-universe ",
            "percents (where the PE column holds a COUNT, not a percent) will ",
            "NOT be flagged and will appear as real percents (pct_est). Derive ",
            "the list once with derive_denominator_stems.fn on a rich ",
            "multi-geography pull, save it, and pass it as denom_stems.")
  
  out <- long_df %>%
    left_join(lbl, by = c("variable" = "name")) %>%
    mutate(
      is_percent = case_when(
        str_starts(label, "Percent")  ~ TRUE,
        str_starts(label, "Estimate") ~ FALSE,
        TRUE                          ~ NA
      ),
      # suffix on the FULL variable name: ...PE / ...PM / ...E / ...M
      .suffix = str_extract(variable, "(P?[EM])$"),
      .stem   = str_remove(variable, "P?[EM]$"),
      .is_denom = !is.null(denom_stems) & .stem %in% denom_stems,
      measure_type = case_when(
        .is_denom & .suffix %in% c("PE","PM") ~ "pct_placeholder",
        is_percent  & .suffix == "PE" ~ "pct_est",
        is_percent  & .suffix == "PM" ~ "pct_moe",
        !is_percent & .suffix == "E"  ~ "count_est",
        !is_percent & .suffix == "M"  ~ "count_moe",
        TRUE                          ~ NA_character_
      )
    ) %>%
    select(-.suffix, -.stem, -.is_denom)
  
  out
}