library(here)
library(readr)

# URL to GitHub repository
URL_GITHUB <- "https://github.com/statistikZH/<to-be-defined>"

# URLs to MIV data
URL_MIV_2019 <- "https://data.stadt-zuerich.ch/dataset/6212fd20-e816-4828-a67f-90f057f25ddb/resource/fa64fa70-6328-4d47-bcf0-1eff694d7c22/download/sid_dav_verkehrszaehlung_miv_od2031_2019.csv"
URL_MIV_2020 <- "https://data.stadt-zuerich.ch/dataset/6212fd20-e816-4828-a67f-90f057f25ddb/resource/44607195-a2ad-4f9b-b6f1-d26c003d85a2/download/sid_dav_verkehrszaehlung_miv_od2031_2020.csv"
URL_MIV_2021 <- "https://data.stadt-zuerich.ch/dataset/6212fd20-e816-4828-a67f-90f057f25ddb/resource/b2b5730d-b816-4c20-a3a3-ab2567f81574/download/sid_dav_verkehrszaehlung_miv_od2031_2021.csv"


# Paths where the MIV raw data of 2019 and 2020 will be stored
PATH_MIV_2019 <- here::here("data", "miv", "sid_dav_verkehrszaehlung_miv_od2031_2019.csv")
PATH_MIV_2020 <- here::here("data", "miv", "sid_dav_verkehrszaehlung_miv_od2031_2020.csv")
PATH_MIV_2021 <- here::here("data", "miv", "sid_dav_verkehrszaehlung_miv_od2031_2021.csv")


# Path where the MIV indicator for 2019 will be stored
PATH_MIV_INDICATOR_2019 <- here::here("data", "miv", "indicators_2019.Rdata")

# Paths to pedestrian and bicycle data as well as metadata on counting locations
PATH_COUNTING_DATA_2019 <- "https://data.stadt-zuerich.ch/dataset/83ca481f-275c-417b-9598-3902c481e400/resource/33b3e7d3-f662-43e8-b018-e4b1a254f1f4/download/2019_verkehrszaehlungen_werte_fussgaenger_velo.csv"
PATH_COUNTING_DATA_2020 <- "https://data.stadt-zuerich.ch/dataset/83ca481f-275c-417b-9598-3902c481e400/resource/b9308f85-9066-4f5b-8eab-344c790a6982/download/2020_verkehrszaehlungen_werte_fussgaenger_velo.csv"
PATH_COUNTING_DATA_2021 <- "https://data.stadt-zuerich.ch/dataset/83ca481f-275c-417b-9598-3902c481e400/resource/ebe5e78c-a99f-4607-bedc-051f33d75318/download/2021_verkehrszaehlungen_werte_fussgaenger_velo.csv"

PATH_LOCATION_DATA <- here::here("data", "lv", "taz.view_eco_standorte.csv")

# LV: Specify data types explicitly. Do not import attributes <OST> and <NORD>.
COL_SPEC_COUNTING_DATA <- cols_only(FK_ZAEHLER = col_character(),
                                    FK_STANDORT = col_character(),
                                    DATUM = col_character(),
                                    VELO_IN = col_integer(),
                                    VELO_OUT = col_integer(),
                                    FUSS_IN = col_integer(),
                                    FUSS_OUT = col_integer())

# LV: Specify data types explicitly. Do not import attributes <objectid> and <geometry>.
COL_SPEC_METADATA <- cols_only(abkuerzung = col_character(),
                               bezeichnung = col_character(), 
                               bis = col_character(),
                               fk_zaehler = col_character(), 
                               id1 = col_character(),
                               richtung_in = col_character(), 
                               richtung_out = col_character(), 
                               von = col_character())

PATH_RESULT_CSV <- here::here("Mobilität_AufkommenTerrestrischerVerkehr.csv")
