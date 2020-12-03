rm(list=ls(all=T))

## Load packages - check if installed first - if not install them
if (!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
if (!require(rvest)) install.packages("rvest"); library(rvest)
if (!require(formatR)) install.packages("formatR"); library(formatR)
if (!require(furrr)) install.packages("furrr"); library(furrr)
detach("package:dplyr"); library(dplyr) #ensure dplyr is loaded last in case forget to prefix the filter function

all_file_urls <- function (input_url, css_selector){
    nodes <- xml2::read_html(input_url)%>% html_nodes(css_selector)
    links <- nodes %>% html_attr('href') %>% url_absolute(input_url) #  %>% paste0(switch(tolower(substring( ., 1L, 5L)) ,'https' = '','https://digital.nhs.uk'), .)
    file_names <- html_text(nodes)
    return(data.frame(file_names, links))
}


get_url <- function (input_url, css_selector){
  link <- xml2::read_html(input_url)%>%
    html_node(css_selector)%>%
    html_attr('href') %>% url_absolute(input_url)
  return(link)
}


cleaned_csv <- function(input_csv){
  c <- filter(input_csv, BREAKDOWN %in% keep_breakdowns, MEASURE_VALUE!='*', !is.na(MEASURE_VALUE)) 
  c$REPORTING_PERIOD_START <- as.Date(ifelse(grepl("/", c$REPORTING_PERIOD_START),  
                                             as.Date(c$REPORTING_PERIOD_START, '%d/%m/%Y'), 
                                             as.Date(c$REPORTING_PERIOD_START, '%Y-%m-%d')), origin = '1970-01-01')
  
  c$REPORTING_PERIOD_END <- as.Date(ifelse(grepl("/", c$REPORTING_PERIOD_END),  
                                           as.Date(c$REPORTING_PERIOD_END, '%d/%m/%Y'), 
                                           as.Date(c$REPORTING_PERIOD_END, '%Y-%m-%d')), origin = '1970-01-01')
  c$MEASURE_VALUE <- as.integer(c$MEASURE_VALUE)
  c$BREAKDOWN <- map(c$BREAKDOWN, remap_breakdown)
  c$STATUS <- as.character(c$STATUS)
  return(c)
}   


remap_breakdown <- function (input_breakdown){
  if(grepl('CCG', input_breakdown, ignore.case=T)){'CCG - GP Practice or Residence'}
  else if(grepl('Provider', input_breakdown, ignore.case=T)){'Provider'}
  else if(grepl('England', input_breakdown, ignore.case=T)){'England'}
  else{input_breakdown}
}


keep_breakdowns <- c('CCG - GP Practice or Residence', 'CCG - GP Practice or Residence; ConsMediumUsed', 
                     'England', 'England; ConsMediumUsed', 'Provider', 'Provider; ConsMediumUsed', 
                     'Region', 'STP')
colTypes = cols(
  REPORTING_PERIOD_START = col_character(),
  REPORTING_PERIOD_END = col_character(),
  STATUS = col_character(),
  BREAKDOWN = col_character(),
  PRIMARY_LEVEL = col_character(),
  PRIMARY_LEVEL_DESCRIPTION = col_character(),
  SECONDARY_LEVEL = col_character(),
  SECONDARY_LEVEL_DESCRIPTION = col_character(),
  MEASURE_ID = col_character(),
  MEASURE_NAME = col_character(),
  MEASURE_VALUE = col_character()
)

landing_page <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"

files_df <- all_file_urls(landing_page, '[data-uipath]:not([data-uipath*=upcoming]) [title*="Mental Health Services Monthly Statistics" ]') #need to exclude upcoming url!

#2020 files only
files_df <- filter(files_df, grepl('*2020|*2019', links))

plan(multiprocess)

temp_df <- data.frame(REPORTING_PERIOD_START= NA_character_,
                      REPORTING_PERIOD_END=NA_character_,
                      STATUS=NA_character_,
                      BREAKDOWN=NA_character_,
                      PRIMARY_LEVEL=NA_character_,
                      PRIMARY_LEVEL_DESCRIPTION=NA_character_,
                      SECONDARY_LEVEL=NA_character_,
                      SECONDARY_LEVEL_DESCRIPTION=NA_character_,
                      MEASURE_ID=NA_character_,
                      MEASURE_NAME=NA_character_,
                      MEASURE_VALUE='*')

#tryCatch idea from @FJCC https://community.rstudio.com/t/read-csv-readr-output-empty-dataframe-with-expected-headers-if-actual-headers-dont-all-match-definition/89790
combined_csvs <- future_map_dfr(.x = files_df$links, 
                                .f = ~ cleaned_csv(
                                  tryCatch(read_csv(get_url(.x, '[title*="MHSDS Data File"],[title*="MHSDS Monthly Data File"]'), col_types = colTypes), 
                                           warning=function(e) temp_df)   
                                ), seed=TRUE)


# unique(subset(combined_csvs, REPORTING_PERIOD_END == "2020-02-29")$REPORTING_PERIOD_START)
#  unique(subset(combined_csvs, REPORTING_PERIOD_START == "2019-12-01")$REPORTING_PERIOD_END)
