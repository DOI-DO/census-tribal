## Information about the code in this folder

This src folder includes code written to access Census Bureau data through the Census API and code to reformat those data and/or combine with the reference tables located in the data folder. For more information about the Census API see _https://www.census.gov/data/developers/data-sets.html_.

The code is written in R and sources the tidyverse (or dplyr and stringr), httr, and jsonlite packages.

- tidyverse can be found at:
https://cran.r-project.org/web/packages/tidyverse/index.html
- Information about using tidyverse can be found here:
https://tidyverse.tidyverse.org/

Another useful package is the tidycensus package, which is well documented and supported and lets you pull Census tables. Some Census tables associated with AIAN are not well supported by tidycensus, however, and this is the reason that we have created several functions to use the Census API.

- tidycensus can be found at:
https://cran.r-project.org/web/packages/tidycensus/index.html
- Information about using tidycensus can be found here:
https://walker-data.com/tidycensus/

To use the Census API regularly, you should request an API key. The URL to request a key is: https://api.census.gov/data/key_signup.html.

The tidycensus function call _census_api_key("your_api_key_here", install = TRUE)_ will install the key in your .Renviron file (set it and forget it!).

### Brief description of code files in this folder:
1. _get_table_ids_fn.R_ This function queries the _variable.json_ file associated with a specific Census 'dataset' or 'summary file' (summary file is 2000 and 2010 Decennial Census terminology). You must specify the year of data that you want; if you are requesting 5-yr ACS data, specify the LAST year. You also specify the program, i.e., 'dec' for Decennial and 'acs' for the American Community Survey. Finally, specify the dataset/summary file. Possible values for this third parameter are found in the table included below. If you wish to see only the 'main' tables and those specific to AIAN, set subsetAIAN = TRUE (default). This drops non-AIAN race specific tables. This function is the **first** function that you need to run to pull Decennial or ACS data from the API, because you need to specify a table from the dataset. The output of this function gives you a list of variables (name, label) in the dataset and the associated tables (concept, group). The group code is entered into the  _get_census_table.fn_ function. 
2. _get_dataset_geographies_fn.R_ Census datasets are available for different geographies. For example, some datasets only report data for states, while others might include summary tables for counties, Census tracts, and AIAN geographies. This function queries the _geography.json_ file to tell you what geographies are associated with the dataset you plan to use. This function is the **second** function that you need to run to pull Decennial or ACS data from the API, because you need to specify the geography that you want in your API data call. As with _get_table_ids.fn_, you need to specify the year, program, and dataset of interest, and can restrict output to only AIAN geographies via the subsetAIAN parameter.  
3. _resolve_geo_fn.R_ This function accepts the output from _get_dataset_geographies.fn_ and, for a specified geography code, outputs the fields needed in the API call when the information you want is subset to areas where the geography intersects with another, non-nested or nesting, geography, for example, if you want information for AIAN reservations by state for reservations that cross state boundaries. This is the **third** function to run prior to pulling data from the API.
4. _get_census_table_fn.R_ This function pulls tabled data from the Census API for the Decennial Census and the ACS. In addition to specifying the year, program, and dataset, you must specify the table id (from _get_table_ids.fn_) and geography (from  _get_dataset_geographies.fn_ and, if nested, _resolve_geo.fn_). The resulting table is **wide** (variables and MOE as columns) and can be tidied and lengthened using _reshape_census_long.fn_.
5. _createPopulationGrps_ReferenceTable.R_ and _create...Table2.R_ include the code used to create the _census-tribal_PopGrp_RaceCode.csv_ and _census-tribal_PopGrp.csv_ reference files, respectively.

Table with program, year, and dataset/sumfile values:
| program | year | dataset |
|:------:|:----:|:-------:|
| dec | 2020 | dhc |
| dec | 2020 | dp |
| dec | 2020 | ddhca |
| dec | 2020 | ddhcb |
| dec | 2020 | sdhc |
| dec | 2020 | pl |
| dec | 2010 | sf1 |
| dec | 2010 | sf2 |
| dec | 2010 | pl |
| dec | 2000 | sf1 |
| dec | 2000 | sf2 |
| dec | 2000 | sf2profile |
| dec | 2000 | sf3 |
| dec | 2000 | sf3profile |
| dec | 2000 | sf4 |
| dec | 2000 | sf4profile |
| dec | 2000 | aian |
| dec | 2000 | aianprofile |
| dec | 2000 | pl |
| acs | 2009-2024 | acs5 |
| acs | 2010-2024 | acs5/subject |
| acs | 2009-2024 | acs5/profile |
| acs | 2010,2015,2021 | acs5/spt |
| acs | 2010,2021 | acs5/sptprofile |
| acs | 2010,2015,2021 | acs5/aian |
| acs | 2010,2015,2021 | acs5/aianprofile |

