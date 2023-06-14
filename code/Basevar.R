source("lib.R")

# head(first_bloom)

# 將資料轉為3D-array
n_batch <- as.integer(1) # 可以改變但是 label y的維度也要跟著變動
n_timesteps <- as.integer(334) # 30+31+30+31+31+30+31+30+31+31+28=334
n_features <- as.integer(18)
