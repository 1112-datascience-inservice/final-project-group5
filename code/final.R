###
# DEBUG FILE #
###
first_bloom_csv <- "data/input/sakura-first-47city.csv"

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

cities_file <- read.csv("data/input/japanmaincity-47final.csv")

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
    weather_file <- paste0("data/input/WeatherData/", sprintf("%02d", city_row$NO), city_row$城市, "_200001-202304.csv")
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
# test <- array(testtest, dim = c(334, 18)) # for test
# test2 <- np$array(get_weather(cities_file[4, ], 2003), dtype = "object") # for test

######
### train_label: which is data of full bloom and first bloom
######
get_bloom_date <- function(from_csv, city_no, year) {
    data <- from_csv[from_csv$NO == city_no, paste0("X", year)]
    # transform to date
    sapply(data, function(x) {
        month <- as.numeric(substr(x, 0, 1))
        date <- as.numeric(substr(x, 2, 4))
        # 以 03/01 為起始點計算天數 eg. 4/25 > 56
        return(as.numeric(difftime(as.Date(paste0("2001-", sprintf("%02d", month), "-", sprintf("%02d", date))), as.Date("2001-02-28"), units = "days")))
    })
}
# test <- get_bloom_date(first_bloom, 1, 2001) # for test

######
### 自定義函數檢查閏年
######
is_leap_year <- function(year) {
    if (year %% 4 != 0) {
        return(FALSE)
    } else if (year %% 100 != 0) {
        return(TRUE)
    } else if (year %% 400 != 0) {
        return(FALSE)
    } else {
        return(TRUE)
    }
}

# 將資料轉為3D-array
n_batch <- as.integer(1) # 可以改變但是 label y的維度也要跟著變動
n_timesteps <- as.integer(334) # 30+31+30+31+31+30+31+30+31+31+28=334
n_features <- as.integer(18)
n_samples <- as.integer(train_cell_num)

library(reticulate)
np <- import("numpy")

train_data_x <- c()
train_data_y <- matrix(0, ncol = n_batch, nrow = n_samples / n_batch)

test_data_x <- c()
test_data_y <- matrix(0, ncol = n_batch, nrow = test_cell_num / n_batch)

train_count <- 0
test_count <- 0
for (i in seq_len(length(city_idx))) {
    for (j in seq_len(length(years))) {
        tmp <- get_weather(cities_file[i, ], years[[j]])
        if (is_leap_year(years[[j]])) {
            tmp <- tmp[-nrow(tmp), ] # 刪除最後一行
        }

        if (i %in% test_city_idx && years[[j]] %in% test_years) {
            test_count <- test_count + 1
            test_data_x <- c(test_data_x, unlist(tmp))
            test_data_y[test_count] <- get_bloom_date(first_bloom, cities_file[i, ]$NO, years[[j]])
        } else {
            train_count <- train_count + 1
            train_data_x <- c(train_data_x, unlist(tmp))
            train_data_y[train_count] <- get_bloom_date(first_bloom, cities_file[i, ]$NO, years[[j]])
        }
        # break
    }
}
# save data
saveRDS(tmp, "./data/input/rds/tmp.rds")
saveRDS(train_data_x, "./data/input/rds/train_data_x.rds")
saveRDS(train_data_y, "./data/input/rds/train_data_y.rds")
saveRDS(test_data_x, "./data/input/rds/test_data_x.rds")
saveRDS(test_data_y, "./data/input/rds/test_data_y.rds")
# how to make sure the test_data_x is all numeric or factor
train_data_x <- array(
    data = train_data_x, dim = c(
        n_timesteps,
        n_features,
        n_samples
    ),
    dimnames = list(
        rownames(tmp),
        colnames(tmp)
    )
)
test_data_x <- array(
    data = test_data_x, dim = c(
        n_timesteps,
        n_features,
        test_cell_num
    ),
    dimnames = list(
        rownames(tmp),
        colnames(tmp)
    )
)

###
# NETWORK #
###
######
### Metrics
######
recall_m <- function(y_true, y_pred) {
    true_positives <- sum(round(pmin(y_true * y_pred, 1)))
    possible_positives <- sum(round(pmin(y_true, 1)))
    recall <- true_positives / (possible_positives + 1e-07)
    return(recall)
}

precision_m <- function(y_true, y_pred) {
    true_positives <- sum(round(pmin(y_true * y_pred, 1)))
    predicted_positives <- sum(round(pmin(y_pred, 1)))
    precision <- true_positives / (predicted_positives + 1e-07)
    return(precision)
}

f1_m <- function(y_true, y_pred) {
    precision <- precision_m(y_true, y_pred)
    recall <- recall_m(y_true, y_pred)
    return(2 * ((precision * recall) / (precision + recall + 1e-07)))
}

######
### Define input layers
######

recurrent_input <- layer_input(
    shape = c(n_timesteps, n_features),
    name = "TIMESERIES_INPUT"
)
# static_input <- layer_input(shape = 3, name = "STATIC_INPUT")

lstm_outputs <-
    recurrent_input %>%
    bidirectional(
        layer = layer_lstm(
            units = 512,
            batch_input_shape = c(n_batch, n_timesteps, n_features),
            # (batch_size, timesteps, features
            kernel_regularizer = regularizer_l2(0.01),
            recurrent_regularizer = regularizer_l2(0.01),
            return_sequences = TRUE
        ),
        name = "BIDIRECTIONAL_LAYER_1"
    ) %>%
    layer_dropout(
        rate = 0.1,
        name = "DROPOUT_LAYER_1"
    ) %>%
    bidirectional(
        layer = layer_lstm(
            units = 512,
            kernel_regularizer = regularizer_l2(0.01),
            recurrent_regularizer = regularizer_l2(0.01),
        ),
        name = "BIDIRECTIONAL_LAYER_2"
    ) %>%
    layer_dropout(
        rate = 0.1,
        name = "DROPOUT_LAYER_2"
        # )

        # static_layers <-
        # layer_concatenate(
        #     inputs = c(lstm_outputs, static_input),
        #     axis = 1,
        #     name = "CONCATENATED_TIMESERIES_STATIC"
    ) %>%
    layer_dense(
        units = 512,
        kernel_regularizer = regularizer_l2(0.001),
        activation = "relu",
        name = "DENSE_LAYER_1"
    ) %>%
    layer_dense(
        units = 256,
        activation = "relu",
        name = "DENSE_LAYER_2"
    ) %>%
    layer_dense(
        units = 90,
        activation = "softmax",
        name = "OUTPUT_LAYER"
    )
model <- keras_model(
    inputs = recurrent_input, outputs = lstm_outputs,
    # inputs = list(recurrent_input, static_input), outputs = static_layers,
    name = "mnist_model"
)
plot(model)
# Compile the model
model %>% compile(
    loss = "categorical_crossentropy",
    optimizer = optimizer_adam(),
    metrics = c(
        "mse",
        "accuracy",
        "categorical_accuracy"
    ),
    # custom_metric("recall_m", recall_m),
    # custom_metric("precision_m", precision_m),
    # custom_metric("f1_m", f1_m)),
)

# Print the model summary
model %>% summary()

input_data <- aperm(train_data_x, c(3, 1, 2)) # np$array(train_data_x, dtype = "object")
label_data <- unlist(train_data_y) # 有疑慮但先這樣
label_data <- keras::to_categorical(label_data, num_classes = 90)
dim(label_data) # 834 90
typeof(label_data)
# restored_label <- apply(label_data, 1, function(x) which.max(x) - 1) # to check if the label is correct
history2 <- model %>% fit(
    # data = train_data_x,
    input_data,
    # train_data_x,
    # labels = train_data_y,
    label_data,
    batch_size = 20,
    epochs = 8,
    verbose = TRUE,
)
# save_model_hdf5(model, "model6.h5")
# save_model_tf(model, "./model_by_save_model.tf", overwrite = TRUE)
model
save_model_weights_hdf5(model, "model7.h5")

model_test <- keras_model(
    inputs = recurrent_input, outputs = lstm_outputs,
    # inputs = list(recurrent_input, static_input), outputs = static_layers,
    name = "mnist_model_test"
)
load_model_weights_hdf5(model_test, "model7.h5")
summary(model_test)
model_test %>% compile(
    loss = "categorical_crossentropy",
    optimizer = optimizer_adam(),
    metrics = c(
        "mse",
        "accuracy",
        "categorical_accuracy"
    ),
)
model_test %>% evaluate(test_input_data, test_label_data)
# model_test <- load_model_hdf5("model6.h5", compile = FALSE)
# model_test %>% summary()


# test <- keras$models$load_model("model.h5")
# data <- h5read("model.h5", "/model_weights")
library(rhdf5)


test_input_data <- aperm(test_data_x, c(3, 1, 2))
test_label_data <- unlist(test_data_y) # 有疑慮但先這樣
test_label_data <- keras::to_categorical(test_label_data, num_classes = 90)
test_eval <- model %>% evaluate(test_input_data, test_label_data)

test2 <- model %>%
    predict(test_input_data, verbose = 1, batch_size = 20)
restored_label <- apply(test2, 1, function(x) which.max(x) - 1)
true_restored_label <- apply(test_label_data, 1, function(x) which.max(x) - 1)

test3 <- model %>%
    predict(input_data, verbose = 1, batch_size = 20)
restored_label2 <- apply(test3, 1, function(x) which.max(x) - 1)
true_restored_label2 <- apply(label_data, 1, function(x) which.max(x) - 1)
write(restored_label2, "restored_label_f.txt")
write(true_restored_label2, "true_restored_label2.txt")

