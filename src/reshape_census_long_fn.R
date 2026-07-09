# This function tidies the table produced by get_census_table.fn by creating
# a column for variable and one for annotation (wide to long)

# 9-July-2026 E Silverman with Claude Chat

# ---------------------------------------------------------------------------
# reshape_census_long()
# Converts a wide get_census_table() result into long format:
#   one row per geography x variable, with columns:
#     variable          -- the base variable/column stub (e.g. B01001_001)
#     value             -- the numeric estimate/count (N, E, or COL_R value)
#     annotation        -- the raw annotation/flag column name (e.g. B01001_001EA)
#     annotation_value  -- the content of that annotation column, if any
#
# All non-variable columns (NAME, GEO_ID, state, POPGROUP, etc.) are kept
# as identifier columns and repeated across the long rows.
# ---------------------------------------------------------------------------
reshape_census_long.fn <- function(df, table_id) {
  
  all_cols <- colnames(df)
  
  # Value columns: flat suffix (_###N/E/M) or matrix style (_COL#_R#)
  value_cols <- grep(paste0("^", table_id, "(_\\d{3}[NEM]|_\\d{4}[CP]|_COL\\d+_R\\d+)$"), all_cols, value = TRUE)
  
  # Annotation columns: same stub + trailing A (e.g. _001NA, _001EA, _001MA)
  # or matrix style with trailing A (e.g. _COL1_R1A)
  annot_cols <- grep(paste0("^", table_id, "(_\\d{3}[NEM]A|_\\d{4}[CP]A|_COL\\d+_R\\d+A)$"), all_cols, value = TRUE)
  
  id_cols <- setdiff(all_cols, c(value_cols, annot_cols))
  
  if (length(value_cols) == 0) {
    message("No value columns found for table ", table_id, " -- returning df unchanged.")
    return(df)
  }
  
  # Long-format the value columns
  long_vals <- df %>%
    select(all_of(c(id_cols, value_cols))) %>%
    pivot_longer(cols = all_of(value_cols), names_to = "variable", values_to = "value")
  
  # Long-format the annotation columns, then strip trailing "A" from the
  # variable name so it matches the corresponding value row for joining
  if (length(annot_cols) > 0) {
    long_annot <- df %>%
      select(all_of(c(id_cols, annot_cols))) %>%
      pivot_longer(cols = all_of(annot_cols), names_to = "annotation", values_to = "annotation_value") %>%
      mutate(variable = str_remove(annotation, "A$"))
    
    out <- long_vals %>%
      left_join(long_annot, by = c(id_cols, "variable"))
  } else {
    out <- long_vals %>%
      mutate(annotation = NA_character_, annotation_value = NA_character_)
  }
  
  out
}
