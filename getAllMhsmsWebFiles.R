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


landing_page <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"

files_df <- all_file_urls(landing_page, '[data-uipath]:not([data-uipath*=upcoming]) .cta__button') #need to exclude upcoming url!

#2020 files only
files_df <- filter(files_df, grepl('*2020', links))

plan(multiprocess)


combined_csvs <- future_map_dfr(.x = files_df$links, #%>%set_names(~ letters[seq_along(.)])
               .f = ~ cleaned_csv(read_csv(get_url2(.x, '[title*="MHSDS Data File"]'))), seed=TRUE)