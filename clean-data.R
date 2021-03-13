# clean env canada forecast data

library(tidyverse)
library(RSQLite)
library(lubridate)

mydb <- dbConnect(RSQLite::SQLite(), "weather.sqlite")
forecast <- dbReadTable(mydb, "weather")
dbDisconnect(mydb)

# clean data
# extract days and temperatures from `report`
f <- forecast %>%
  rename(issued = date) %>%
  mutate(obs_date = as_datetime(obs_date, tz="America/Halifax"),
         night = str_detect(report, "night"),
         high_low = str_extract(report, "(High|Low)"),
         current = str_detect(report, "Current Conditions"),
         negative = str_detect(report, "minus"),
         zero = str_detect(report, "zero"),
         temperature = str_extract(report, "-*[0-9]*\\.*[0-9]+") %>% as.numeric,
         temperature = case_when(zero ~ 0, 
                                 negative ~ -abs(temperature),
                                 TRUE ~ temperature),
         sequence = cumsum(current)) %>%
  select(-zero, -negative)

# date stuff
wday(f$obs_date, label=TRUE)
as_datetime(f$issued)
format_ISO8601(f$obs_date)

# compute day/time of forecast
f2 <- f %>% mutate(issued_dt = as_datetime(issued, tz="America/Halifax"),
             issued_ymd = as_date(issued_dt),
             issued_dow = wday(issued_dt, label=TRUE),
             report_dow = str_sub(report, 1, 3)) %>%
      group_by(sequence) %>%
      mutate(forecast_offset = cumsum(!night) - 1,
             forecast_date = case_when(current ~ NA_Date_,
                                       TRUE ~ issued_ymd + forecast_offset))

