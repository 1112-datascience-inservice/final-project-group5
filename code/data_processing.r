###
# DEBUG FILE #
###
first_bloom_csv <- "data/sakura-first-47city.csv"

library(tidyverse)
library(keras)
library(caret)

###
# READ #
###
first_bloom <- read.csv(first_bloom_csv)
head(first_bloom)
###
# DATA PREPROCESSING #
###
######
### split the train data and test data
######

cities_file <- read.csv("data/japanmaincity-47final.csv")

set.seed(123)
years <- c(2001:2022)

all_cells_num <- length(years) * nrow(cities_file) # 1034
test_cell_num <- all_cells_num * 0.2 # 206.8
test_cell_num <- 200 # 取 200 個測試資料
train_cell_num <- all_cells_num - test_cell_num # 834

test_years <- sample(years, 10) # 2001 2003 2006 2008 2010 2011 2012 2014 2015 2021
test_years <- test_years[order(test_years)]

set.seed(554)
city_idx <- cities_file$NO
test_city_idx <- sample(city_idx, 20)
test_city_idx <- test_city_idx[order(test_city_idx)]
test_cities <- cities_file[test_city_idx, ]

length(test_years)
length(test_cities$NO)
length(test_years) * length(test_cities$NO) # 測試資料總數

library("missForest") # https://zhuanlan.zhihu.com/p/45091612
library(readr)
######
### train_X: which is weather data
######
get_weather <- function(city_row, year) {
    weather_file <- paste0("data/WeatherData/", sprintf("%02d", city_row$NO), city_row$城市, "_200001-202304.csv")
    weather <- read.csv(weather_file, na.strings = c("×"))
    # print(city_row$城市)
    # from (year-1)04 to (year)02
    selection <- c(
        # 200004 ~ 200012
        paste0(c(year - 1), sprintf("%02d", 4:12)),
        # 200101 ~ 200102
        paste0(c(year), sprintf("%02d", 1:2))
    )
    col_names <- colnames(weather)[3:20] # 拿掉前面後面兩個欄位
    weather <- weather[weather[[1]] %in% selection, col_names]
    colnames(weather) <- seq_along(colnames(weather))
    rownames(weather) <- seq_along(rownames(weather))

    # weather 在這邊做前處理的原因是可以針對該城市該年的狀況去補值
    # 處理資料為 -- 的改為 0，並將其column轉回 numeric
    weather[[3]] <- as.numeric(ifelse(weather[[3]] == "--", 0, weather[[3]]))
    weather[[4]] <- as.numeric(ifelse(weather[[4]] == "--", 0, weather[[4]]))
    weather[[5]] <- as.numeric(ifelse(weather[[5]] == "--", 0, weather[[5]]))
    weather[[16]] <- as.numeric(ifelse(weather[[16]] == "--", 0, weather[[16]]))
    weather[[17]] <- as.numeric(ifelse(weather[[17]] == "--", 0, weather[[17]]))
    weather[[18]] <- as.numeric(ifelse(weather[[18]] == "--", 0, weather[[18]]))

    # using factor to transform categorical data
    weather[[13]] <- factor(weather[[13]])
    weather[[15]] <- factor(weather[[15]])
    # transform to numeric
    weather[[1]] <- as.numeric(weather[[1]])
    weather[[2]] <- as.numeric(weather[[2]])
    weather[[6]] <- as.numeric(weather[[6]])
    weather[[7]] <- as.numeric(weather[[7]])
    weather[[8]] <- as.numeric(weather[[8]])
    weather[[9]] <- as.numeric(weather[[9]])
    weather[[10]] <- as.numeric(weather[[10]])
    weather[[11]] <- as.numeric(weather[[11]])
    weather[[12]] <- as.numeric(weather[[12]])
    weather[[14]] <- as.numeric(weather[[14]])
    # normalize data
    # 讓高氣壓變成正值，低氣壓變成負值
    weather[[1]] <- weather[[1]] - 1013.25
    weather[[2]] <- weather[[2]] - 1013.25

    # 處理 NA (根據資料集的特性)
    weather_i <- missForest(weather, maxiter = 10, ntree = 100)
    # weather_i 有兩個物件，一個是ximp，是填補後的資料，另一個是 OOBerror，麻煩找資料說明一下
    weather <- weather_i$ximp

    weather[[13]] <- keras::to_categorical(as.integer(weather[[13]]))
    weather[[15]] <- keras::to_categorical(as.integer(weather[[15]]))
    # weather <- scale(weather) #todo: check if its correct
    return(weather)
}
# test <- get_weather(cities_file[1, ], 2001)
