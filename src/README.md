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
