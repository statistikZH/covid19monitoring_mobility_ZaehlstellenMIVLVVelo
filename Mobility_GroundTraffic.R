#Achtung: im Hauptverzeichnis müssen ordner ./data/miv/ .data/lv/ existieren. da nicht versioniert, müssen sie beim ersten Mal angelegt werden 
# To do: auf Ausfall von Zählstellen testen
source("Mobility_CarTraffic.R", encoding = "UTF-8")
remove(list = ls())
source("Mobility_PedestrianAndBicycleTraffic.R", encoding = "UTF-8")

mob<-read.csv("Mobilität_AufkommenTerrestrischerVerkehr.csv", encoding="UTF-8")

range(as.Date(mob$date))
