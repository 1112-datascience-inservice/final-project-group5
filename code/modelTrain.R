source("modelSettings.R")
# Path: code\modelSettings.R

args <- commandArgs(trailingOnly = TRUE)
# Load the data
train_data_x <- readRDS("./data/rds/input/train_data_x.rds")
train_data_y <- readRDS("./data/rds/input/train_data_y.rds")
test_data_x <- readRDS("./data/rds/input/test_data_x.rds")
test_data_y <- readRDS("./data/rds/input/test_data_y.rds")

model_weight <- "model_to_train.h5"
# if there exists a model, load it's weights
if ("--weight" %in% args) {
    model_weight <- args[which(args == "--weight") + 1]
    model_to_train <- load_model_weights_hdf5(model_to_train, model_weight)
}

# compile the model
model_to_train %>% compile(
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

if ("--summary" %in% args) {
    summary(model_to_train)
    # save summary to txt
    cat(summary(model_to_train), file = "./docs/model_summary.txt")
}

if ("--plot" %in% args) {
    plot(model_to_train, to_file = "./docs/model_structure.png", show_shapes = TRUE)
}

input_data <- aperm(train_data_x, c(3, 1, 2))
label_data <- unlist(train_data_y) # 有疑慮但先這樣
label_data <- keras::to_categorical(label_data, num_classes = 90)

history <- model_to_train %>% fit(
    input_data,
    label_data,
    batch_size = 20,
    epochs = 8,
    verbose = TRUE,
)

save_model_weights_hdf5(model_to_train, model_weight)

test_input_data <- aperm(test_data_x, c(3, 1, 2))
test_label_data <- unlist(test_data_y) # 有疑慮但先這樣
test_label_data <- keras::to_categorical(test_label_data, num_classes = 90)

test_eval <- model_to_train %>% evaluate(test_input_data, test_label_data)
write(test_eval, file = "./output/test_eval.txt")

test_pred <- model_to_train %>% predict(test_input_data)
restored_label <- apply(test_pred, 1, function(x) which.max(x) - 1)
true_label <- apply(test_label_data, 1, function(x) which.max(x) - 1)

saveRDS(restored_label, "./output/rds/restored_test_pred_label.rds")
saveRDS(true_label, "./output/rds/true_test_pred_label.rds")
