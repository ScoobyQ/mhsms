# Borrows from https://github.com/LPulle/NHSE-Analytics/blob/main/code/amb_checker.R

rm(list=ls(all=T))

## Load packages - check if installed first - if not install them
if (!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
if (!require(rvest)) install.packages("rvest"); library(rvest)
if (!require(formatR)) install.packages("formatR"); library(formatR)
detach("package:dplyr"); library(dplyr) #ensure dplyr is loaded last in case i forget to prefix the filter function

get_url <- function (input_url, css_selector){
  link <- xml2::read_html(input_url)%>%
    html_node(css_selector)%>%
    html_attr('href') %>% url_absolute(input_url) # paste0(switch(tolower(substring( ., 1L, 5L)) ,'https' = '','https://digital.nhs.uk'), .)
  return(link)
}


### clean dataframe function.....
cleaned_csv <- function(input_csv){
  c <- filter(input_csv,!is.na(input_csv$MEASURE_VALUE) & input_csv$MEASURE_VALUE != "*") 
  c$REPORTING_PERIOD_START <- as.Date(c$REPORTING_PERIOD_START,'%d/%m/%Y')
  c$REPORTING_PERIOD_END <- as.Date(c$REPORTING_PERIOD_END,'%d/%m/%Y')
  c$MEASURE_VALUE <- as.integer(c$MEASURE_VALUE)
  return(c)
}  
  

landing_page <- 'https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics'

# Manually disable DirectAccess first
latest_files_link <- get_url(landing_page, '.cta__button')
web_file <- get_url(latest_files_link, '[title*="MHSDS Data File"]')
csv <- read_csv(web_file)
clean <- cleaned_csv(csv)

glimpse(clean)
