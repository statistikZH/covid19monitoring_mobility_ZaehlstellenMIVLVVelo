library(tidyverse)
library(magrittr)

source("Parameters.R", encoding = "UTF-8")
source("Functions.R", encoding = "UTF-8")



# Data cleaning ----------------------------------

# Download the data
downloadData(URL_MIV_2020, PATH_MIV_2020)
downloadData(URL_MIV_2021, PATH_MIV_2021)


# Load the data
data_raw20 <- read.csv(PATH_MIV_2020, stringsAsFactors = FALSE)
# Load the data
data_raw21 <- read.csv(PATH_MIV_2021, stringsAsFactors = FALSE)
data_raw<-rbind(data_raw20, data_raw21)
rm(data_raw20)
rm(data_raw21)

# Change to proper datetime format
data_raw$datetime <- as.POSIXct(data_raw$MessungDatZeit, 
                                format = "%Y-%m-%dT%H:%M:%S")

# Remove observations data with timestamp "2020-03-29T02:00:00" (time change)
data_reduced1 <- data_raw[!is.na(data_raw$datetime),]

# Remove wrong values
data_reduced2 <- removeNAObervations(data_reduced1, "AnzFahrzeuge")

# Remove counting stations because of too few measurements in 2020
# Z006: data available for less than 2/3 of the year 2019
# Z024: no data between 2020-01-01 and 2020-03-31
# Z050: data available for less than 2/3 of the year 2019
# Z092: no data between 2020-02-19 and 2020-03-31
# Z096: no data between 2020-01-01 and 2020-03-31
data_reduced3 <- subset(data_reduced2, !(ZSID %in% c("Z006", "Z024", "Z050", "Z092", "Z096", "Z019", "Z087")))


# Gather all directions within each counting station
data_gathered <- sumDirections(data_reduced3, "ZSID", "AnzFahrzeuge", "datetime")


# Do the analysis ------------------------------

# Derive date from datetime
data_gathered$date <- strftime(data_gathered$datetime, "%Y-%m-%d")

# Derive type of day (weekday or not)
data_gathered$typeofday <- "Weekend"
data_gathered$typeofday[strftime(data_gathered$datetime, "%u") <= 5] <- "Weekday"

# Sind stationen ausgefallen seit mitte Februar 

#Weg damit! (Z077?)
data_gathered<-(subset(data_gathered, !StationID%in%c("Z007", "Z037", "Z051", "Z088", "Z086", "Z060", "Z077")))
ee<-with(subset(data_gathered, date>"2020-02_16"), tapply(value, list(date, StationID), sum))
print(sort(apply(ee,2, sum), na.last=T))
View(ee)
# Remove counting station for days when during more than three hours no data
# is available. Then aggregate the remaining data over all relevant counting
# locations
indicator_2020 <- filterAndAggregate(data_gathered)

# Check if file with value of  2019 exist
if (!file.exists(PATH_MIV_INDICATOR_2019)){
  source("Mobility_CarTraffic_Benchmark2019.R")
}

# Load the indicators of 2019
load(PATH_MIV_INDICATOR_2019)

# Derive the value for 2020 relative to 2019 per day
indicator_2020 %>%
  left_join(indicator_2019, by = c("typeofday" = "typeofday"), 
            suffix = c("", "_2019")) %>%
  mutate(value_relative = value / value_2019 * 100) -> indicator_2020


# Write CSV ----------------------------------

# Create the structure of the csv file for the sum indicator
result_sum <- indicator_2020[, c("date", "value")]
result_sum$date <- result_sum$date
result_sum$topic <- "Mobilität"
result_sum$variable_short <- "aufkommen_miv"
result_sum$variable_long <- "Aufkommen MIV an ausgewählten Zählstellen"
result_sum$location <- "Stadt Zürich"
result_sum$unit <- "Anzahl"
result_sum$source <- "Dienstabteilung Verkehr, Sicherheitsdepartement"
result_sum$update <- "täglich"
result_sum$public <- "ja"
result_sum$description <-"https://github.com/statistikZH/covid19monitoring_mobility_ZaehlstellenMIVLVVelo"

# Create the structure of the csv file for the relative indicator
result_relative <- indicator_2020[, c("date", "value_relative")]
names(result_relative) <- c("date", "value")
result_relative$date <- result_relative$date
result_relative$topic <- "Mobilität"
result_relative$variable_short <- "aufkommen_miv_indexiert"
result_relative$variable_long <- "Aufkommen MIV an ausgewählten Zählstellen, relativ zu mittlerem Aufkommen 2019"
result_relative$location <- "Stadt Zürich"
result_relative$unit <- "Anteil"
result_relative$source <- "Dienstabteilung Verkehr, Sicherheitsdepartement"
result_relative$update <- "täglich"
result_relative$public <- "ja"
result_relative$description <- "https://github.com/statistikZH/covid19monitoring_mobility_ZaehlstellenMIVLVVelo"

# Write the results to the csv
write_csv(rbind(result_sum, result_relative), PATH_RESULT_CSV, col_names = TRUE)

#are all counting stations active
#ee<-tapply(data_gathered$value, list(data_gathered$date, data_gathered$StationID), sum)


