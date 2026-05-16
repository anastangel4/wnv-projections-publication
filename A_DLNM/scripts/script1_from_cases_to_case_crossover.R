rm(list = ls())
library(rstudioapi)
path <- rstudioapi::getActiveDocumentContext()$path
dir <- dirname(path)
setwd(dir)

packages <- c(
  "ggmap", "sf", "zoo", "lubridate",
  "dplyr", "terra", "readxl", "Hmisc"
  )

install.packages(setdiff(packages, rownames(installed.packages())))
lapply(packages, require, character.only = TRUE)

source("functions/tscc_sampling.R")

data <- read.csv(file = "data/3.sim_cases.csv")
head(data)

data$ID <- paste0("ID", seq(1 : length(data$date)))
head(data)

db_cc <- tscc_sampling(data = data, dates = "date")
head(db_cc)

data <- db_cc %>%
  left_join(data, by = "ID") %>%
  select(- date)

head(data)

ref_date <- as.Date("2009-12-31")
data$sampling_date <- as.Date(data$sampling_date)
data$index <- as.numeric(data$sampling_date - ref_date)

data_tg <- read.csv(file = "data/4.temperatures.csv")
class(data_tg)
dim(data_tg)

temp_data <- merge(data, data_tg, by = "NUTS_ID", all.x = T)
names(temp_data)
dim(temp_data)

col <- which(grepl("^X.+", names(temp_data)))[1] #column 6
start <- col - 1 #starting column

df <- data.frame(matrix(ncol = start + 56, nrow = 0))
names(df) <- c(names(temp_data[1:start]), paste0("tg_lag", c(1:56)))
for (i in 1:dim(temp_data)[1]) {
  df[i,] <- temp_data[i, c(1:start, (start + temp_data$index[i] - 1):(start + temp_data$index[i] - 56))]
}

df[, which(substr(names(df), 1, 2) == "tg")] <- apply(df[, which(substr(names(df), 1, 2) == "tg")], FUN = as.numeric, MARGIN = 2)
df[, which(substr(names(df), 1, 2) == "tg")] <- apply(df[, which(substr(names(df), 1, 2) == "tg")], function(x) {
  x - 273
  }, MARGIN = 2)

data_prcp <- read.csv(file = "data/5.precipitation.csv")
dim(data_prcp)

temp_data2 <- merge(data, data_prcp, by = "NUTS_ID", all.x = T)

col <- which(grepl("^X.+", names(temp_data2)))[1] #column 8
start <- col - 1
df2 <- data.frame(matrix(ncol = start + 56, nrow = 0))
names(df2) <- c(names(temp_data2[1:start]), paste0("pr_lag", c(1:56)))
for (i in 1:dim(temp_data)[1]) {
  df2[i,] <- temp_data2[i, c(1:start, (start + temp_data2$index[i] - 1):(start + temp_data2$index[i] - 56))]
}

df2[, which(substr(names(df2), 1, 2) == "pr")] <- apply(df2[, which(substr(names(df2), 1, 2) == "pr")], FUN = as.numeric, MARGIN = 2)
df2[, which(substr(names(df2), 1, 2) == "pr")] <- apply(df2[, which(substr(names(df2), 1, 2) == "pr")], function(x) {
  x *60*60*24*1000
}, MARGIN = 2)

CC_data <- merge(df, df2, by = c(names(df)[1:start]))
dim(CC_data)
ftable(CC_data$caco)
head(CC_data)

write.csv(CC_data,
  file = "data/7.case_cross_data.csv",
  row.names = FALSE
)