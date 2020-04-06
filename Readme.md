# Readme

The R scripts in this repository calculate indicators pertaining to ground-based mobility, specifically for the pedestrian, cycling, and car transport modes. The data originates from the official counting stations of the city of Zurich as part of the [city's open data offering](https://data.stadt-zuerich.ch):

- Source for car data: https://data.stadt-zuerich.ch/dataset/sid_dav_verkehrszaehlung_miv_od2031
- Source for pedestrian and bicycle data: https://data.stadt-zuerich.ch/dataset/ted_taz_verkehrszaehlungen_werte_fussgaenger_velo

Each indicator is provided as sum over all relevant counting stations. In addition, the indicators are provided indexed with relatively to the mean daily traffic of the respective transport mode in 2019, at all relevant counting stations. Counting stations with larger measuring gaps are excluded from the relevant counting stations and thus from the calculations. 

Additionally, a day's data of an individual counting station was excluded from further analysis if 20 or fewer hours were recorded at the respective counting station. For pedestrian and bicycle traffic (which are counted in 15 minute intervals), additionally an hour's data was excluded from further analysis, if not all four 15 minute intervals were measured.

