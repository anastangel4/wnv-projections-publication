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

seqlag <- function(lag, by = 1) seq(from = lag[1], to = lag[2], by = by)
levels <- pretty(pred_best_t$matRRfit, 30)
col1 <- colorRampPalette(c("blue", "white"))
col2 <- colorRampPalette(c("white", "red"))
col <- c(col1(sum(levels < 1)), col2(sum(levels > 1)))
filled.contour(
  x = pred_best_t$predvar, y = (seqlag(pred_best_t$lag, pred_best_t$bylag) + 1),
  z = pred_best_t$matRRfit, col = col, plot.title = title(
    main = "A", adj = 0.6,
    xlab = "Weekly Avg Temp (°C)",
    ylab = "Lag (weeks)"
  ),
  levels = levels, key.title = title("OR", cex.main = 0.75, line = 0.2),
  plot.axes = {
    axis(1)
    axis(2)
    lines(c(tg_per[6], tg_per[6]), c(0, 8), lty = 2)
    lines(c(tg_per[6]+1, tg_per[6]+1), c(0, 8), lty = 1)
  }
)

seqlag <- function(lag, by = 1) seq(from = lag[1], to = lag[2], by = by)
levels <- pretty(pred_best_p$matRRfit, 30)
col1 <- colorRampPalette(c("blue", "white"))
col2 <- colorRampPalette(c("white", "red"))
col <- c(col1(sum(levels < 1)), col2(sum(levels > 1)))
filled.contour(
  x = pred_best_p$predvar, y = (seqlag(pred_best_p$lag, pred_best_p$bylag) + 1),
  z = pred_best_p$matRRfit, col = col, plot.title = title(
    main = "B", adj = 0.60,
    xlab = "Weekly Cum Prep (mm)",
    ylab = "Lag (weeks)"
  ),
  levels = levels, key.title = title("OR", cex.main = 0.75, line = 0.2),
  plot.axes = {
    axis(1)
    axis(2)
    lines(c(prcp_per[6], prcp_per[6]), c(0, 8), lty = 2, lwd = 1.5)
    lines(c(prcp_per[6]+10, prcp_per[6]+10), c(0, 8), lty = 1, lwd = 1.5)
  }
)

save_dir <- "results/model_objects_temp"

if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE)

save(mod, file = file.path(save_dir, "mod_fitted_object.RData"))
save(temp_cb, file = file.path(save_dir, "temp_cb.RData"))
save(prep_cb, file = file.path(save_dir, "prep_cb.RData"))
save(temp_knots, file = file.path(save_dir, "temp_knots.RData"))
save(lag_knots, file = file.path(save_dir, "lag_knots.RData"))
save(tg_per, file = file.path(save_dir, "tg_per.RData"))
save(prcp_per, file = file.path(save_dir, "prcp_per.RData"))
save(pred_best_t, file = file.path(save_dir, "pred_best_t.RData"))
save(pred_best_p, file = file.path(save_dir, "pred_best_p.RData"))
