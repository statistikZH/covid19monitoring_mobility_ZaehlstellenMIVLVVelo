library(here)
library(tidyverse)
library(magrittr)
library(lubridate)

source("Parameters.R", encoding = "UTF-8")

# 2020-04-02
# EBP, Ralph Straumann

# Read and format the counting and location data --------------------------

# Read and merge 2019 and 2020 data
download.file(PATH_COUNTING_DATA_2019, "staging.csv")
df <- read_csv("staging.csv", col_types = COL_SPEC_COUNTING_DATA)
download.file(PATH_COUNTING_DATA_2020, "staging.csv")
df2020 <- read_csv("staging.csv", col_types = COL_SPEC_COUNTING_DATA)
file.remove("staging.csv")
df <- rbind(df, df2020)
rm(df2020)

# Rename columns
names(df) <- c("fk_counter", "fk_timelocation", "datetime", "velo_in", 
               "velo_out", "foot_in", "foot_out")

# Compute time-related columns
df$datetime <- parse_date_time2(df$datetime, "Y!-m!-*d! H!:M!", 
                                tz = "Europe/Berlin")
df$datehour <- strftime(df$datetime, "%Y-%m-%d %H")
df$date <- strftime(df$datetime, "%Y-%m-%d")
df$typeofday <- "Weekend"
df$typeofday[strftime(df$datetime, "%u") <= 5] <- "Weekday"

# Read metadata
df_meta <- read_csv(PATH_LOCATION_DATA, col_types = COL_SPEC_METADATA)

# Rename and reorder columns
head(df_meta)
df_meta <- transmute(df_meta, id_timelocation = id1, 
                              code_location = abkuerzung,
                              name_location = bezeichnung, 
                              fk_counter = fk_zaehler, 
                              valid_from = von, 
                              valid_to = bis, 
                              direction_in = richtung_in, 
                              direction_out = richtung_out)

# Parse datetime fields, adjust the <valid_to> values
df_meta$valid_from = parse_date_time2(df_meta$valid_from, "Y!m!*d!H!M!S!", 
                                      tz = "Europe/Berlin")
df_meta$valid_to = parse_date_time2(df_meta$valid_to, "Y!m!*d!H!M!S!", 
                                    tz = "Europe/Berlin")
df_meta$valid_to <- df_meta$valid_to - hms("00:00:01")

# Fill empty values for <valid_to> (i.e., the records that are currently still 
# valid)
df_meta$valid_to[is.na(df_meta$valid_to)] <- ymd_hms("2999-12-31 23:59:59", 
                                                     tz = "Europe/Berlin")

# Find the records that pertain to the years 2019 and 2020
df_meta <- filter(df_meta, int_overlaps(interval(start = "20190101", 
                                                 end = "20201231"), 
                                        interval(start = df_meta$valid_from, 
                                                 end = df_meta$valid_to)) == TRUE)



# Preprocess --------------------------------------------------------------

# Split dataframe into pedestrians and bicycles
df %>%
  filter(!is.na(foot_in)) %>%
  select(-c(velo_in, velo_out)) -> df_foot
df_foot

df %>%
  filter(!is.na(velo_in)) %>%
  select(-c(foot_in, foot_out)) -> df_velo
df_velo
rm(df)


# Clean or remove imperfect data ------------------------------------------

# Combine the two dataframes into one, specify the mode in a new column
df_foot <- transmute(df_foot, fk_counter = fk_counter, 
                              fk_timelocation = fk_timelocation, 
                              datetime = datetime, 
                              datehour = datehour,
                              date = date, 
                              typeofday = typeofday, 
                              count_in = foot_in, 
                              count_out = foot_out,
                              mode = "foot")
df_velo <- transmute(df_velo, fk_counter = fk_counter, 
                              fk_timelocation = fk_timelocation, 
                              datetime = datetime, 
                              datehour = datehour,
                              date = date, 
                              typeofday = typeofday, 
                              count_in = velo_in, 
                              count_out = velo_out,
                              mode = "bicycle")

df = rbind(df_foot, df_velo)
rm(df_foot)
rm(df_velo)

# Join with location table
df %>%
  left_join(df_meta, 
            by = c("fk_timelocation" = "id_timelocation"), 
            suffix = c("", "_y")) -> df
rm(df_meta)

#a few missings with name location removed
df<-subset(df, is.na(name_location)==F)

# Handle special cases ----------------------------------------------------

# The value for <direction_out> is "---" for certain records, which indicates
# counting in only one direction. However, there are more special cases.
# unique(df$direction_out)
# unique(df[df$direction_out == "---",10:11])

# That is the case for the following counting locations:
# code_location     name_location    
# VZS_LIMC      Limmatquai --> Central 
# VZS_LIMB      Limmatquai --> Bellevue
# VZS_HOFW      Hofwiesenstrasse       
# VZS_BUCH      Bucheggplatz

# What follows is diagnostic code. This does not need to be re-run, it just 
# served to find special cases and heuristics to handle them.

# # Both Limmatquai locations count in only one direction. The other direction is
# # NA except for one record which is 0.
# df[df$name_location == "Limmatquai --> Central", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# summary(temp[!is.na(temp$count_out),8])
# df[df$name_location == "Limmatquai --> Bellevue", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# summary(temp[!is.na(temp$count_out),8])
#  
# # Hofwiesenstrasse counts in one direction always, and has data in the other 
# # direction 10% of the time. But all that latter data is 0.
# df[df$name_location == "Hofwiesenstrasse", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# summary(temp[!is.na(temp$count_out),8])
# 
# # Bucheggplatz counts in one direction always, and has data in the other 
# # direction 5% of the time. But all that latter data is equal to the first direction.
# df[df$name_location == "Bucheggplatz", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# summary(temp[!is.na(temp$count_out),8])
# summary(temp[!is.na(temp$count_in),8])
# 
# # Both Langstrasse locations count in both directions
# df[df$name_location == "Langstrasse (Unterführung Nord)", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# df[df$name_location == "Langstrasse (Unterführung Süd)", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# 
# # Both Hardbrücke locations count in both directions
# df[df$name_location == "Hardbrücke Nord (Seite Altstetten)", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# df[df$name_location == "Hardbrücke Süd (Seite HB)", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# 
# # Fischerweg counts in both directions
# df[df$name_location == "Fischerweg", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))
# 
# # Kloster-Fahr-Weg counts in both directions
# df[df$name_location == "Kloster-Fahr-Weg", ] -> temp
# summary(is.na(temp$count_in))
# summary(is.na(temp$count_out))

# Limmatquai: Set <count_out> to 0
df$count_out[df$name_location == "Limmatquai --> Central"] <- 0
df$count_out[df$name_location == "Limmatquai --> Bellevue"] <- 0

# Hofwiesenstrasse: Set <count_out> to <count_in>
df$count_out[df$name_location == "Hofwiesenstrasse"] <- 
  df$count_in[df$name_location == "Hofwiesenstrasse"]

# Bucheggplatz: Set <count_out> to <count_in>
df$count_out[df$name_location == "Bucheggplatz"] <- 
  df$count_in[df$name_location == "Bucheggplatz"]

# Langstrasse: Do nothing
# Hardbrücke: Do nothing
# Fischerweg: Do nothing
# Kloster-Fahr-Weg: Do nothing



# Do the actual analysis --------------------------------------------------

# Compute cross-sectional value
df$count_crosssection = df$count_in + df$count_out

# Compute hourly values. Remove hours that do not have four input records, i.e.
# that don't have four 15min intervals of counting data
df %>%
  filter(!is.na(count_crosssection)) %>%
  group_by(code_location, mode, date, typeofday, datehour) %>%
  summarise(count_crosssection = sum(count_crosssection), n_records = n()) %>%
  filter(n_records == 4) -> df_hourly
rm(df)

# Compute daily values. Remove days that do not have at least 21 hours of 
# counting data as input
df_hourly %>%
  group_by(code_location, mode, date, typeofday) %>%
  summarise(count_crosssection = sum(count_crosssection), n_hours = n()) %>%
  filter(n_hours >= 21) -> df_daily
rm(df_hourly)

# Find counting locations that do not have enough data values in order to be
# part of the index. What follows is diagnostic code. This does not need to be 
# re-run, it just served to find a sensible benchmark for excluding counting 
# locations.
# df_daily %>%
#   group_by(year(date), typeofday, mode, code_location) %>%
#   summarise(count = n()) -> temp
# temp$count[temp$typeofday == "Weekday"] <- 
#   temp$count[temp$typeofday == "Weekday"] / 5
# temp$count[temp$typeofday == "Weekend"] <- 
#   temp$count[temp$typeofday == "Weekend"] / 2
# temp <- spread(temp, typeofday, count)
# write_delim(temp, "Datenvolumen.csv", delim=";")

# The following counting locations are excluded from further analysis as they do
# not have data for at least 2/3 of the days in 2019 and 2020
df_daily %>%
  filter(!(code_location == "VZS_ANDR" & mode == "bicycle")) %>%
  filter(!(code_location == "VZS_BUCH" & mode == "bicycle")) %>%
  filter(!(code_location == "VZS_FISC" & mode == "bicycle")) %>%
  filter(!(code_location == "VZS_KLOW" & mode == "bicycle")) %>%
  filter(!(code_location == "VZS_SAUM" & mode == "bicycle")) %>%
  filter(!(code_location == "VZS_SCHE" & mode == "bicycle")) %>%
  filter(!(code_location == "FZS_CHOR" & mode == "foot")) %>%
  filter(!(code_location == "FZS_LETL" & mode == "foot")) %>%
  filter(!(code_location == "FZS_ALTW" & mode == "foot")) %>%
  filter(!(code_location == "VZS_FISC" & mode == "foot")) %>%
  filter(!(code_location == "FZS_HARD" & mode == "foot")) %>%
  filter(!(code_location == "VZS_KLOW" & mode == "foot")) %>%
  filter(!(code_location == "FZS_LETD" & mode == "foot")) %>%
  filter(!(code_location == "FZS_OHMO" & mode == "foot")) %>%
  filter(!(code_location == "FZS_WEIN" & mode == "foot")) -> df_daily
  
# Compute benchmark values based on 2019's data
df_daily$date <- df_daily$date

df_daily %>%
  filter(year(date) == 2019) %>%
  group_by(date, mode, typeofday) %>%
  summarise(sum_crosssection = sum(count_crosssection)) %>%
  group_by(mode, typeofday) %>%
  summarise(benchmark_crosssection = mean(sum_crosssection)) -> df_benchmark
df_benchmark

# Compute 2020 data
df_daily %>%
  filter(year(date) == 2020) %>%
  group_by(date, mode, typeofday) %>%
  summarise(sum_crosssection = sum(count_crosssection)) %>%
  ungroup() -> df_2020
rm(df_daily)

# Compare to 2019 benchmark data
df_2020 %>%
  left_join(df_benchmark, 
            by = c("typeofday" = "typeofday", "mode" = "mode")) %>%
  mutate(value = sum_crosssection, 
         value_indexed = sum_crosssection / benchmark_crosssection * 100,
         topic = "Mobilität",
         location = "Stadt Zürich",
         source = "Dienstabteilung Verkehr, Sicherheitsdepartement",
         update = "täglich",
         public = "ja", 
         description = "https://github.com/statistikZH/covid19monitoring_mobility_ZaehlstellenMIVLVVelo") %>%
  select(-c(sum_crosssection, benchmark_crosssection, typeofday)) -> df_2020


# Extract individual datasets

df_2020 %>%
  filter(mode == "bicycle") %>%
  mutate(variable_short = "aufkommen_veloverkehr",
         variable_long = "Veloverkehrsaufkommen an ausgewählten Zählstellen",
         unit = "Anzahl") %>%
  select(date, value, topic, variable_short, variable_long, location, unit, 
         source, update, public, description) %>%
  write_csv(PATH_RESULT_CSV, append = TRUE, quote = FALSE)

df_2020 %>%
  filter(mode == "bicycle") %>%
  select(-c(value)) %>%
  mutate(variable_short = "aufkommen_veloverkehr_indexiert",
         variable_long = "Veloverkehrsaufkommen an ausgewählten Zählstellen, relativ zu mittlerem Aufkommen 2019",
         unit = "Anteil",
         value = value_indexed) %>%
  select(date, value, topic, variable_short, variable_long, location, unit, 
         source, update, public, description) %>%
  write_csv(PATH_RESULT_CSV, append = TRUE, quote = FALSE)

df_2020 %>%
  filter(mode == "foot") %>%
  mutate(variable_short = "aufkommen_fussverkehr",
         variable_long = "Fussverkehrsaufkommen an ausgewählten Zählstellen",
         unit = "Anzahl") %>%
  select(date, value, topic, variable_short, variable_long, location, unit, 
         source, update, public, description) %>%
  write_csv(PATH_RESULT_CSV, append = TRUE, quote = FALSE)

df_2020 %>%
  filter(mode == "foot") %>%
  select(-c(value)) %>%
  mutate(variable_short = "aufkommen_fussverkehr_indexiert",
         variable_long = "Fussverkehrsaufkommen an ausgewählten Zählstellen, relativ zu mittlerem Aufkommen 2019",
         unit = "Anteil",
         value = value_indexed) %>%
  select(date, value, topic, variable_short, variable_long, location, unit, 
         source, update, public, description) %>%
  write_csv(PATH_RESULT_CSV, append = TRUE, quote = FALSE)


