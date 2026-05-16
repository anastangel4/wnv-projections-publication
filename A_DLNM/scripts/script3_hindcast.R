rm(list = ls())
library(rstudioapi)
path <- rstudioapi::getActiveDocumentContext()$path
dir <- dirname(path)
setwd(dir)

packages <- c(
  "ggmap", "sf", "tidyr",
  "lubridate", "survival",
  "dlnm", "dplyr", "ggplot2"
)
install.packages(setdiff(packages, rownames(installed.packages())))
lapply(packages, require, character.only = TRUE)

source("functions/attrdl.R")

data <- read.csv("data/7.case_cross_data.csv")
data$clogit_id <- as.numeric(substr(data$ID, 3, 6))

t_mat <- as.matrix(data[, which(substr(names(data), 1, 2) == "tg")])
dim(t_mat)

a <- NULL
for (i in seq(from = 7, to = 56, by = 7)) {
  a[[ceiling(i / 7)]] <- apply(t_mat[, (i - 6):i], 1, mean)
}

t_mat_avg <- as.matrix(as.data.frame(a))
hist(t_mat_avg)

p_mat <- as.matrix(data[, which(substr(names(data), 1, 2) == "pr")])
dim(p_mat)

a2 <- NULL
for (i in seq(from = 7, to = 56, by = 7)) {
  a2[[ceiling(i / 7)]] <- apply(p_mat[, (i - 6):i], 1, sum)
}

p_mat_avg <- as.matrix(as.data.frame(a2))
dim(p_mat_avg)

hist(p_mat_avg)
clima_all <- read.csv(file = "data/6.weekly_prep_temp.csv")

clima_all <- clima_all %>%
  mutate(
    date = dmy(date),
    week = lubridate::week(date),
    year = lubridate::year(date)
  ) %>%
  filter(week > 19 & week <= 44) %>%
  group_by(week, year, NUTS_ID) %>%
  summarise(
    t_mean = mean(tg, na.rm = T),
    prep_cum = sum(prep, na.rm = T)
  )

tg_per <- c(quantile(clima_all$t_mean,
                     probs = c(0.10, 0.25, 0.33, 0.50, 0.66, 0.75, 0.9, 0.95, 0.99),
                     na.rm = TRUE
))

prcp_per <- c(quantile(clima_all$prep_cum,
                       probs = c(0.10, 0.25, 0.33, 0.50, 0.66, 0.75, 0.9, 0.95, 0.99),
                       na.rm = TRUE
))

temp_knots <- tg_per[c(3, 5)]

lag_knots <- c(1.66, 4.32)

temp_cb <- crossbasis(t_mat_avg,
                      lag = c(0, 7),
                      argvar = list(
                        fun = "ns",
                        knots = temp_knots, intercept = F
                      ),
                      arglag = list(
                        fun = "bs", degree = 3,
                        knots = lag_knots, intercept = T
                      )
)

prep_cb <- crossbasis(p_mat_avg,
                      lag = c(0, 7),
                      argvar = list(fun = "lin", intercept = F),
                      arglag = list(
                        fun = "bs", degree = 3,
                        knots = lag_knots, intercept = T
                      )
)

mod <- clogit(caco ~ temp_cb + prep_cb + strata(clogit_id),
              data = data, method = "approximate"
)

pred_best_t <- crosspred(temp_cb, mod,
                         cen = tg_per[6],
                         at = c(16:28), bylag = 0.25
)

pred_best_p <- crosspred(prep_cb, mod,
                         cen = prcp_per[6],
                         at = c(seq(0, 60, 5)), bylag = 0.25
)

weekly_hindcast <- clima_all
weekly_hindcast <- weekly_hindcast %>%
  rowwise() %>%
  mutate(
    RR_temp = pred_best_t$allRRfit[which.min(abs(pred_best_t$predvar - t_mean))],
    RR_prep = pred_best_p$allRRfit[which.min(abs(pred_best_p$predvar - prep_cum))],
    RR_model = RR_temp * RR_prep ) %>% ungroup()

bins <- seq(0, 10, by = 0.1)  # RR bins

weekly_RR_hindcast <- weekly_hindcast %>%
  mutate(
    RR_temp_bin = cut(RR_temp,
                      breaks = bins,
                      include.lowest = TRUE,
                      right = FALSE,
                      labels = round(bins[-length(bins)], 1)),
    RR_prep_bin = cut(RR_prep,
                      breaks = bins,
                      include.lowest = TRUE,
                      right = FALSE,
                      labels = round(bins[-length(bins)], 1)),
    RR_sum_bin = cut(RR_model,
                      breaks = bins,
                      include.lowest = TRUE,
                      right = FALSE,
                      labels = round(bins[-length(bins)], 1))
  )


# RR sum
RR_temp_hindcast <- weekly_RR_hindcast %>%
  group_by(NUTS_ID, year, RR_temp_bin) %>%
  summarise(weeks = n(), .groups = "drop") %>%
  group_by(NUTS_ID, RR_temp_bin) %>%
  summarise(mean_days_per_year = mean(weeks * 7/15, na.rm = TRUE), .groups = "drop")
RR_prep_hindcast <- weekly_RR_hindcast %>%
  group_by(NUTS_ID, year, RR_prep_bin) %>%
  summarise(weeks = n(), .groups = "drop") %>%
  group_by(NUTS_ID, RR_prep_bin) %>%
  summarise(mean_days_per_year = mean(weeks * 7/15, na.rm = TRUE), .groups = "drop")
RR_sum_hindcast <- weekly_RR_hindcast %>%
  group_by(NUTS_ID, year, RR_sum_bin) %>%
  summarise(weeks = n(), .groups = "drop") %>%
  group_by(NUTS_ID, RR_sum_bin) %>%
  summarise(mean_days_per_year = mean(weeks * 7/15, na.rm = TRUE), .groups = "drop")


if(!dir.exists("results")) dir.create("results")

write.csv(weekly_RR_hindcast,
          file = "results/weekly_RR_hindcast.csv",
          row.names = FALSE)
write.csv(RR_sum_hindcast,
          file = "results/mean_RR_days_hindcast.csv",
          row.names = FALSE)

RR_sum_hindcast_yearly <- weekly_RR_hindcast %>%
  group_by(NUTS_ID, year, RR_sum_bin) %>%
  summarise(days = n() * 7/15, .groups = "drop")