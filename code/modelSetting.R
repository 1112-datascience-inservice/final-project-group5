source("Basevar.R")
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
### Define input and output layer
### TODO: static input
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

model_to_train <- keras_model(
    inputs = recurrent_input,
    outputs = lstm_outputs,
    name = "LSTM_MODEL"
)
