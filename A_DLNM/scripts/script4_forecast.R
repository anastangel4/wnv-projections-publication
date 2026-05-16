rm(list = ls())
library(rstudioapi)
path <- rstudioapi::getActiveDocumentContext()$path
dir <- dirname(path)
setwd(dir)

library(dplyr)
library(lubridate)
library(ggplot2)
library(viridis)
library(scales)
scenario <- 45   # choose 45 (for 4.5) or 85 (for 8.5)
proj_temp <- read.csv(paste0("data/CMIP6_", scenario, "_proj.csv"))

proj_temp <- proj_temp %>%
  mutate(
    dates = dmy(dates),   
    week = week(dates),
    year = year(dates)
  ) %>%
  filter(week >= 20 & week <= 44)

weekly_temp <- proj_temp %>%
  group_by(NUTS_ID, year, week) %>%
  summarise(
    t_mean = mean(temp, na.rm = TRUE),
    prep_cum = sum(tp, na.rm = TRUE),
    .groups = "drop"
  )

load("results/model_objects_temp/pred_best_t.RData")
load("results/model_objects_temp/pred_best_p.RData")

weekly_temp <- weekly_temp %>%
  rowwise() %>%
  mutate(
    RR_temp = pred_best_t$allRRfit[which.min(abs(pred_best_t$predvar - t_mean))],
    RR_prep = pred_best_p$allRRfit[which.min(abs(pred_best_p$predvar - prep_cum))],
    RR_model = RR_temp * RR_prep
  ) %>%
  ungroup()

weekly_temp <- weekly_temp %>%
  mutate(period = case_when(
    year >= 2061 & year <= 2075 ~ "2061–2075",
    year >= 2076 & year <= 2090 ~ "2076–2090",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(period))

bins <- seq(0, 10, by = 0.1)

weekly_temp <- weekly_temp %>%
  mutate(
    RR_temp_bin = cut(RR_temp, breaks = bins, include.lowest = TRUE, right = FALSE,
                      labels = round(bins[-length(bins)], 1)),
    RR_prep_bin = cut(RR_prep, breaks = bins, include.lowest = TRUE, right = FALSE,
                      labels = round(bins[-length(bins)], 1)),
    RR_sum_bin = cut(RR_model,
                     breaks = bins,
                     include.lowest = TRUE,
                     right = FALSE,
                     labels = round(bins[-length(bins)], 1)))

RR_temp_periods <- weekly_temp %>%
  group_by(period, NUTS_ID, RR_temp_bin) %>%
  summarise(mean_days_per_year = mean(n() * 7/15, na.rm = TRUE), .groups = "drop")

RR_prep_periods <- weekly_temp %>%
  group_by(period, NUTS_ID, RR_prep_bin) %>%
  summarise(mean_days_per_year = mean(n() * 7/15, na.rm = TRUE), .groups = "drop")

RR_sum_periods <- weekly_temp %>%
  group_by(period, NUTS_ID, RR_sum_bin) %>%
  summarise(mean_days_per_year = mean(n() * 7/15, na.rm = TRUE), .groups = "drop")

write.csv(weekly_temp, 
          file = paste0("results/weekly_", scenario, ".csv"), 
          row.names = FALSE)

write.csv(RR_sum_periods, 
          file = paste0("results/mean_RRsum_days_per_NUTS_proj", scenario, ".csv"), 
          row.names = FALSE)
RR_sum_hindcast_yearly <- weekly_temp %>%
  group_by(NUTS_ID, year, RR_sum_bin) %>%
  summarise(days = n() * 7/15, .groups = "drop")