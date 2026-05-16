#' ################################################################################
#  This function takes as input the days of symptoms onset of individual cases
#' and provides back the control days using a monthly time stratified
#' case-crossover design addittionally matching on the day of the week
#' 
#' Author: Giovenale Moirano
################################################################################

#' @title tssc_sampling
#'
#' @description This function takes as imput the days of symptoms onset of individual cases
#' and provides back the control days using a monthly time stratified
#' case-crossover design matched on DoW
#'
#' @param data A dataframe to use
#' @param dates The name of the variable containing dates of
#' the case onset (e.g. "dates")
#'
#' @return A list of sampling control days for each case in the dataset
#' @export
#'
#' @examples tscc_sampling(data, "day_of_symptoms")
#' @examples tscc_sampling(data, "dates_of_events")
#'
#' @author Giovenale Moirano

################################################################################
tscc_sampling <- function(data, dates) {
################################################################################
  
  # CREATE AN EMPTY MATRIX AND POPULATE IT WITH POTENTIAL SAMPLING DATE AROUND
  # THE CASE DAY. 
  
  m1 <- as.data.frame(matrix(rep(NA, nrow(data) * 61),
                             nrow = nrow(data), ncol = 61, byrow = T
  ))
  
  if (class(data[[dates]]) != "Date" & class(data[[dates]]) != "character") {
    stop("variable 'dates' must be provided as character or date format and expressed as '%Y-%m-%d'")
  } else if (class(data[[dates]]) == "Date") {
    for (i in 1:nrow(data)) {
      m1[i, ] <- as.character(as.Date((data[[dates]][i] - 30):(data[[dates]][i] + 30),
        origin = "1970-01-01"
      ))
    }
  } else if (class(data[[dates]]) == "character") {
    for (i in 1:nrow(data)) {
      m1[i, ] <- as.character(as.Date((as.Date(data[[dates]][i], format = "%Y-%m-%d") - 30):(as.Date(data[[dates]][i], format = "%Y-%m-%d") + 30),
        origin = "1970-01-01"
      ))
    }
  }
  
  # TRANSFORM EACH ELEMENT OF m1 TO DATE FORMAT 
  for (i in 1:ncol(m1)) {
    m1[, i] <- as.Date(m1[, i], format = "%Y-%m-%d")
  }

  # CREATE A MATRIX WITH MONTH OF CANDIDATE SAMPLING DATES
  
  mon <- as.data.frame(matrix(rep(NA, nrow(data) * 61),
    nrow = nrow(data), ncol = 61, byrow = T
  ))
  
  for (i in 1:ncol(m1)) {
    mon[, i] <- as.character(month(m1[, i]))
  }

  # SET CONDITION 1: MONTH MUST BE THE SAME OF CASE DAY
  cond1 <- NULL
  for (i in 1:nrow(mon)) {
    cond1[[i]] <- mon[i, ] == mon[i, 31]
  }

  # CREATE A MATRIX WITH DAY OF THE WEEK OF CANDIDATE SAMPLING DATES
  
  dow <- as.data.frame(matrix(rep(NA, nrow(data) * 61),
    nrow = nrow(data), ncol = 61, byrow = T
  ))

  for (i in 1:ncol(m1)) {
    dow[, i] <- as.character(wday(m1[, i], week_start = 1))
  }
  
  # SET CONDITION 2: DAY OF THE WEEK MUST BE THE SAME OF CASE DAY
  
  cond2 <- NULL
  for (i in 1:nrow(dow)) {
    cond2[[i]] <- dow[i, ] == dow[i, 31]
  }

  cond1 <- unlist(cond1)
  cond1_m <- matrix(cond1, nrow = nrow(m1), byrow = TRUE)

  cond2 <- unlist(cond2)
  cond2_m <- matrix(cond2, nrow = nrow(m1), byrow = TRUE)

  # SELECT DATES THAT MEET THE TWO CONDITIONS
  
  output <- NULL

  for (i in 1:nrow(m1)) {
    output[[i]] <- m1[i, cond1_m[i, ] == TRUE & cond2_m[i, ] == TRUE]
  }

  # REFRAME FORMAT AND VARIABLES NAMES 
  
  names(output) <- paste0("ID", 1:length(output))
  output2 <- stack(unlist(output))
  output2$ID <- ifelse(substr(
    output2$ind, nchar(as.character(output2$ind)) - 3,
    nchar(as.character(output2$ind)) - 3
  ) == ".",
  substr(output2$ind, 1, nchar(as.character(output2$ind)) - 4),
  substr(output2$ind, 1, nchar(as.character(output2$ind)) - 3)
  )

  output2$index_date <- substr(output2$ind, nchar(as.character(output2$ind)) - 2, nchar(as.character(output2$ind)))
  output2$caco <- 0
  output2$caco[output2$index_date == "V31"] <- 1
  output2$sampling_date <- as.Date(output2$values, format = "%Y-%m-%d", origin = "1970-01-01")
  return(output2[, c("ID", "caco", "sampling_date")])
  
}
