load_variables_2021 <- 
function (dataset = c("acs5","acs5/profile",
                            "acs5/subject", "acs5/cprofile", 
                            "acs5/spt", "acs5/sptprofile",
                            "acs5/aian", "acs5/aianprofile"), cache = FALSE) 
{
  year <- 2021

  if (!(dataset %in%  c("acs5","acs5/profile",
                      "acs5/subject", "acs5/cprofile", 
                      "acs5/spt", "acs5/sptprofile",
                      "acs5/aian", "acs5/aianprofile"))) {
    stop("Wrong table code used.", 
         call. = FALSE)
  }
  
  rds <- paste0(dataset, "_", year, ".rds")
  if (grepl("^acs[135]/(profile|subject|cprofile)$", dataset)) {
    rds <- gsub("/", "_", rds)
  }
  var_type <- NULL
  if (stringr::str_detect(dataset, "/")) {
    split <- stringr::str_split(dataset, "/")[[1]]
    dataset <- split[1]
    var_type <- split[2]
  }
  
     dataset <- paste0("acs/", dataset)

  if (!is.null(var_type)) {
    dataset <- paste0(dataset, "/", var_type)
  }
  get_dataset <- function(d, year) {
    set <- paste(year, d, sep = "/")
    url <- paste("https://api.census.gov/data", set, "variables.json", 
                 sep = "/")
    resp <- httr::GET(url)
    if (httr::status_code(resp) == 404L) {
      stop("API endpoint not found. Does this data set exist for the specified year? See https://api.census.gov/data.html for data availability.")
    }
    else if (httr::http_status(resp)$category != "Success") {
      stop(paste("API request failed. Reason:", httr::http_status(resp)$message))
    }
    dat <- resp %>% httr::content(as = "text") %>% jsonlite::fromJSON() %>% 
      purrr::modify_depth(2, function(x) {
        x$validValues <- NULL
        x
      }) %>% purrr::flatten_df(.id = "name") %>% dplyr::arrange(name)
    out <- dat[, 1:3]
    names(out) <- tolower(names(out))
    out1 <- out[grepl("^B[0-9]|^C[0-9]|^DP[0-9]|^S[0-9]|^P.*[0-9]|^H.*[0-9]|^K[0-9]|^CP[0-9]|^T[0-9]", 
                      out$name), ]
    out1$name <- stringr::str_replace(out1$name, "E$|M$", 
                                      "")
    out2 <- out1[!grepl("Margin Of Error|Margin of Error", 
                        out1$label), ]
    if (dataset == "acs/acs5" && year > 2010) {
      geo <- tidycensus::acs5_geography
      geo_lookup <- geo[geo$year == year, ]
      out2 <- out2 %>% dplyr::mutate(table = stringr::str_remove(name, 
                                                                 "_.*")) %>% dplyr::left_join(geo_lookup, by = "table") %>% 
        dplyr::select(-year, -table)
    }
    return(as_tibble(out2))
  }
  if (cache) {
    cache_dir <- user_cache_dir("tidycensus")
    if (!file.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    if (file.exists(cache_dir)) {
      file_loc <- file.path(cache_dir, rds)
      if (file.exists(file_loc)) {
        out <- read_rds(file_loc)
        if (year > 2010 && dataset == "acs/acs5") {
          if (!"geography" %in% names(out)) {
            df <- get_dataset(dataset, year)
            readr::write_rds(df, file_loc)
            return(df)
          }
        }
        if (year == 2010 && dataset == "dec/sf1") {
          if ("H00010001" %in% out$name) {
            df <- get_dataset(dataset, year)
            write_rds(df, file_loc)
            return(df)
          }
          if (!"PCT001001" %in% out$name) {
            df <- get_dataset(dataset, year)
            write_rds(df, file_loc)
            return(df)
          }
        }
        out1 <- out[grepl("^B[0-9]|^C[0-9]|^DP[0-9]|^S[0-9]|^P.*[0-9]|^H.*[0-9]|^K[0-9]|^CP[0-9]", 
                          out$name), ]
        out1$name <- str_replace(out1$name, "E$|M$", 
                                 "")
        out2 <- out1[!grepl("Margin Of Error|Margin of Error", 
                            out1$label), ]
        return(out2)
      }
      else {
        df <- get_dataset(dataset, year)
        write_rds(df, file_loc)
        return(df)
      }
    }
  }
  else {
    get_dataset(dataset, year)
  }
}