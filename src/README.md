## Information about the code in this folder

This src folder includes code written to access Census Bureau data through the Census API and code to reformat those data and/or combine with the reference tables located in the data folder.

The code is written in R and sources the tidyverse and tidycensus packages.

- tidyverse can be found at:
https://cran.r-project.org/web/packages/tidyverse/index.html
- Information about using tidyverse can be found here:
https://tidyverse.tidyverse.org/

- tidycensus can be found at:
https://cran.r-project.org/web/packages/tidycensus/index.html
- Information about using tidycensus can be found here:
https://walker-data.com/tidycensus/

To use the Census API regularly, you should request an API key. The URL to request a key is: https://api.census.gov/data/key_signup.html.

The tidycensus function call _census_api_key("your_api_key_here", install = TRUE)_ will install the key in your .Renviron file.

### Brief description of code files in this folder:
1. _view_tables_decennial_fn.R_ Uses tidycensus _load_variables_ function to display tables and variables available for a 2020 decennial census file. Subsets tables to main tables and those for AIAN (drops non-AIAN race-specific tables from view). Running this function first allows you to determine which tables and/or variables you would like to call with the _get_table_decennial_ function. **Note** Function should work of other decennial census years (2000, 2010) but requires specific file names. See _https://www.census.gov/data/developers/data-sets/decennial-census.html_.
2. _get_table_decennial_fn.R_ Uses tidycensus _get_decennial_ function to download 2020 decenial census files based on selecting a table for download. On request, filters AIAN geographies to only those associated with federally-recognized tribal entities. Currently, should not be used for ddhca, ddhcb, and sdhc files, as there is an error in the get_decennial function API call for these files.
3. _get_table_decennial_detailed_fn.R_ Function TBW, which will call ddhca, ddhcb, and sdhc tables.
4. _get_AIAN_popn_data_decennial_fn.R_ This function is similar to _get_table_decennial_fn.R_ but the file (dhc) and table (P8) are pre-specified. The function summarizes estimates of total population, AIAN alone, and AIAN alone or in combination for the selected geographies. All AIAN geographies or only those associated with federally-recognized tribes can be selected.
5. _createPopulationGrps_ReferenceTable.R_ and _create...Table2.R_ include the code used to create the _census-tribal_PopGrp_RaceCode.csv_ and _census-tribal_PopGrp.csv_ reference files, respectively.
