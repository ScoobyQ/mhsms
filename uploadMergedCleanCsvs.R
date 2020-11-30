library(tidyverse)
library(data.table)
## RODBC
if(!require(RODBC)) install.packages("RODBC"); library(RODBC)

GetSQLServer <- "" #Enter the servername here
GetSQLInstance <- "" #Enter the SQL Instance name here
GetSQLDatabase <- "" #Enter the SQL Database name here

## Create Connection String from parameters and connect to database
GetConnectionString <- paste("driver={SQL Server};server=", paste(GetSQLServer, GetSQLInstance, sep="\\"), paste(";database=", GetSQLDatabase, ";trusted_connection=true", sep=""),sep="")
dbhandle <- odbcDriverConnect(GetConnectionString)

folder <- ""
files <- dir(folder)
# files <- files[grepl(".*?\\.csv"),  dir(folder)]

multmerge = function(path){
  filenames=list.files(path=path, full.names=TRUE)
  rbindlist(lapply(filenames, fread))
}


df <- multmerge(folder)
df <- cleaned_csv(df)

varTypes = c(REPORTING_PERIOD_START="datetime",
             REPORTING_PERIOD_END="datetime",
             STATUS="nvarchar(510)",
             BREAKDOWN="nvarchar(510)",
             PRIMARY_LEVEL="nvarchar(510)",
             PRIMARY_LEVEL_DESCRIPTION="nvarchar(510)",
             SECONDARY_LEVEL="nvarchar(510)",
             SECONDARY_LEVEL_DESCRIPTION="nvarchar(510)",
             MEASURE_ID="nvarchar(510)",
             MEASURE_NAME="nvarchar(510)",
             MEASURE_VALUE="float")


sqlSave(dbhandle, df, tablename = ""
        , nastring = NULL, verbose = F, append=T, rownames=F,varTypes = varTypes,fast = T)



# write.csv(df, paste0(getwd(),'/20201126_', 'MhsmsDlpUploadData.csv'), na = '')      
