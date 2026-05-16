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

z_t <- pred_best_t$matRRfit
x_t <- pred_best_t$predvar
y_t <- seqlag(pred_best_t$lag, pred_best_t$bylag) + 1
tiff("Temperature_3D_Plot.png", 
     width = 2000, height = 2000, 
     res = 500,                    
     compression = "lzw")          
persp(x = x_t, y = y_t, z = z_t,
      theta = 45, phi = 30, expand = 0.5,
      col = "lightblue", shade = 0.5,
      ticktype = "detailed",
      xlab = "\n\nWeekly Average 2m Temperature (°C)",
      ylab = "\n\nLag (weeks)",
      zlab = "\n\nOR",
      main = "3D Surface: Temperature Effect",
      cex.axis = 0.8,  
      cex.lab = 0.8,   
      font.main = 2     
)
dev.off()

tiff("Precip_3D_Plot.png", 
     width = 2000, height = 2000, 
     res = 500,                   
     compression = "lzw")          
z_p <- pred_best_p$matRRfit
x_p <- pred_best_p$predvar
y_p <- seqlag(pred_best_p$lag, pred_best_p$bylag) + 1
persp(x = x_p, y = y_p, z = z_p,
      theta = 45, phi = 30, expand = 0.5,
      col = "lightblue", shade = 0.5,
      ticktype = "detailed",
      xlab = "\n\nWeekly Cumulative Precipitation (mm)",
      ylab = "\n\nLag (weeks)",
      zlab = "\n\nOR",
      main = "3D Surface: Precipitation Effect",
      cex.axis = 0.8,   
      cex.lab = 0.8,     
      font.main = 2,
)
dev.off()
