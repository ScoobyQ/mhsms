rm(list=ls(all=T))

## Load packages - check if installed first - if not install them
if (!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
if (!require(rvest)) install.packages("rvest"); library(rvest)
if (!require(formatR)) install.packages("formatR"); library(formatR)
detach("package:dplyr"); library(dplyr) #ensure dplyr is loaded last in case i forget to prefix the filter function

all_file_urls <- function (input_url, css_selector){
    nodes <- xml2::read_html(input_url)%>% html_nodes(css_selector)
    links <- nodes %>% html_attrs('href') %>% url_absolute(input_url)
    file_names <- html_text(nodes)
    return(data.frame(file_names, links))
}

landing_page <- "https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics"


files_df <- all_file_urls(landing_page, '.cta__button')