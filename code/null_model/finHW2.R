library(dplyr)
library(ggplot2)
# 导入数据
data <- read.csv("BollomDate_weather.csv")
# 计算累积最高温度
data <- data %>%
  mutate(Date = as.Date(paste(year, month, day, sep = "-"))) %>%
  arrange(Date)

data$CumulativeMaxTemp <- ave(data$max.temp, data$year, FUN = cumsum)

# 提取开花日期的年份和累积最高温度
flowering_dates <- data %>%
  filter(bloom == 1) %>%
  select(year, CumulativeMaxTemp)

# 绘制累积值与训练年数的关系图
ggplot(flowering_dates, aes(x = year, y = CumulativeMaxTemp)) +
  geom_point() +
  geom_line() +
  labs(x = "Training Year", y = "Cumulative Max Temperature") +
  theme_minimal()
# 计算平均温度
mean_temp <- mean(flowering_dates$CumulativeMaxTemp)
# 验证是否使用600°C作为规则
if (mean_temp >= 600) {
  print("Should use 600°C as the rule for Tokyo.")
} else {
  print("Should not use 600°C as the rule for Tokyo.")
}

