library(xml2)
library(tidyverse)
library(RSQLite)
mydb <- dbConnect(RSQLite::SQLite(), "weather.sqlite")
weather <- read_html("https://weather.gc.ca/rss/city/ns-19_e.xml")
# xml_find_all(weather, ".//title")
w <- tibble(report = xml_find_all(weather, ".//entry/title") %>% xml_text(),
            date = xml_find_all(weather, ".//entry/published") %>% xml_text(),
) %>% slice(n = -1) %>%
  mutate(day = (1:n())-1,
         obs_date = lubridate::now(tz="UTC"))
dbWriteTable(mydb, "weather", w, append=TRUE, overwrite=FALSE)
dbDisconnect(mydb)


