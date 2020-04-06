if (!require(tidyverse)) {
  install.packages('tidyverse')
  require(tidyverse)
}
if (!require(lubridate)) {
  install.packages('lubridate')
  require(lubridate)
}


downloadData <- function(url, destination){
  download.file(url, destination, method = "curl", quiet = TRUE)
}


transformDatetime <- function(datetime){
  as.POSIXct(datetime, format = "%Y-%m-%dT%H:%M:%S")
}


removeNAObervations <- function(df, value){
  df[with(df, !is.na(eval(parse(text = value)))),]
}


sumDirections <- function(df, StationID, value, datetime){
  df %>% rename(StationID = StationID) %>%
    rename(value = value) %>%
    rename(datetime = datetime) %>%
    select(StationID, value, datetime) %>%
    group_by(StationID, datetime) %>%
    summarise(value = sum(value))
}


filterAndAggregate <- function(df, min_dayhours = 21) {
  data_gathered %>%
    group_by(StationID, date, typeofday) %>%
    summarise(value = sum(value), n_hours = n()) %>%
    filter(n_hours >= min_dayhours) -> df_daily
  
  df_daily %>%
    group_by(date, typeofday) %>%
    summarise(value = sum(value)) %>%
    ungroup() -> indicator_2020
  rm(df_daily)
  indicator_2020
}

sumPerDay <- function(df){
  df %>%
    mutate(date = format(datetime, format = "%Y-%m-%d")) %>%
    group_by(date) %>%
    summarize(value = sum(value)) -> df_return
  as.data.frame(df_return)
}


isWeekday <- function(df){
  df$datetime <- as.POSIXct(df$date, format = "%Y-%m-%d")
  df$isweekday <- ifelse(wday(df$datetime) %in% 2:6, 1, 0)
  df
}
