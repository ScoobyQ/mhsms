rm(list=ls(all=T))

## Load packages - check if installed first - if not install them
if (!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
if (!require(rvest)) install.packages("rvest"); library(rvest)
if (!require(formatR)) install.packages("formatR"); library(formatR)
if (!require(furrr)) install.packages("furrr"); library(furrr)

detach("package:dplyr"); library(dplyr) #ensure dplyr is loaded last in case i forget to prefix the filter function

all_file_urls <- function (input_url, css_selector){
    nodes <- xml2::read_html(input_url)%>% html_nodes(css_selector)
    links <- nodes %>% html_attr('href') %>% url_absolute(input_url)
    file_names <- html_text(nodes)
    return(data.frame(file_names, links))
}

get_url2 <- function (input_url, css_selector){
  print(input_url)
  link <- xml2::read_html(input_url)%>%
    html_node(css_selector)%>%
    html_attr('href') %>% url_absolute(input_url)
  return(link)
}
dd
cleaned_csv2 <- function(input_csv){
  c <- filter(input_csv, BREAKDOWN %in% keep_breakdowns, MEASURE_VALUE!='*', !is.na(MEASURE_VALUE)) 
  c$REPORTING_PERIOD_START <- as.Date(c$REPORTING_PERIOD_START,'%d/%m/%Y')
  c$REPORTING_PERIOD_END <- as.Date(c$REPORTING_PERIOD_END,'%d/%m/%Y')
  c$MEASURE_VALUE <- as.integer(c$MEASURE_VALUE)
  c$SECONDARY_LEVEL <- as.character(c$SECONDARY_LEVEL)
  c$BREAKDOWN <- map(c$BREAKDOWN, remap_breakdown)
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

landing_page <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"

files_df <- all_file_urls(landing_page, '[data-uipath]:not([data-uipath*=upcoming]) .cta__button') #need to exclude upcoming url!

#2020 files only
files_df <- filter(files_df, grepl('*2020', links))

plan(multiprocess)


combined_csvs <- future_map_dfr(.x = files_df$links, 
                                .f = ~ cleaned_csv2(read_csv(get_url2(.x, '[title*="MHSDS Data File"]')))
                                , seed=TRUE)




