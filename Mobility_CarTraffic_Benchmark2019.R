source("Parameters.R", encoding = "UTF-8")
source("Functions.R", encoding = "UTF-8")



# Data cleaning ----------------------------------

# Download the data
downloadData(URL_MIV_2019, PATH_MIV_2019)

# Load the data
data_raw <- read.csv(PATH_MIV_2019, stringsAsFactors = FALSE)

# Change to proper datetime format
data_raw$datetime <- transformDatetime(data_raw$MessungDatZeit)

# Remove observations data with timestamp "2019-03-31T02:00:00" (time change)
data_reduced1 <- data_raw[!is.na(data_raw$datetime),]

# Remove wrong values
data_reduced2 <- removeNAObervations(data_reduced1, "AnzFahrzeuge")

# Remove counting stations because of too few measurements in 2020
# Z006: data available for less than 2/3 of the year 2019
# Z024: no data between 2020-01-01 and 2020-03-31
# Z050: data available for less than 2/3 of the year 2019
# Z092: no data between 2020-02-19 and 2020-03-31
# Z096: no data between 2020-01-01 and 2020-03-31
data_reduced3 <- subset(data_reduced2, !(ZSID %in% c("Z006", "Z024", "Z050", "Z092", "Z096")))

# Gather all directions within each counting station
data_gathered <- sumDirections(data_reduced3, "ZSID", "AnzFahrzeuge", "datetime")


# Do the analysis ------------------------------

# Derive date from datetime
data_gathered$date <- strftime(data_gathered$datetime, "%Y-%m-%d")

# Derive type of day (weekday or not)
data_gathered$typeofday <- "Weekend"
data_gathered$typeofday[strftime(data_gathered$datetime, "%u") <= 5] <- "Weekday"

# Remove counting station for days when during more than three hours no data
# is available. Then aggregate the remaining data over all relevant counting
# locations
indicator_2019 <- filterAndAggregate(data_gathered)

# Derive the mean over the whole year over all relevant counting stations 
# for weekdays and for weekends
indicator_2019 %>%
  group_by(typeofday) %>%
  summarise(value = round(mean(value))) -> indicator_2019

# Save the indicators
save(indicator_2019, file = PATH_MIV_INDICATOR_2019)



