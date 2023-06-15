![image](https://github.com/1112-datascience-inservice/final-project-group5/assets/126131693/1aa3b0a5-3969-4d81-bb27-b9b7a8bfc968)# [group5] 櫻前線預測
用過去的天氣資料使用深度模型預測櫻花開花日

## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|許瀞文|資科碩一|111971010|資料前處理 撰寫/LSTM 訓練模型規劃與訓練|
|商瑞珊|資科碩一|111971014|資料蒐集 資料前處理 預測結果視覺化|
|許瑋如|資科碩一|111971017||
|洪明義|資科碩二|110971013||

## Enviroment
* With Python
```
python3, tensorflow and keras with cuda, numpy
```
* With R
```
install.packages("keras")
install.packages("tidyverse")
install.packages("missForest")
install.packages("caret")
install.packages("reticulate")
```

## Quick start
You might provide an example commend or few commends to reproduce your analysis, i.e., the following R script
```R
# to generate input data and save to the RDS
Rscript code/genData.R
# to train model
Rscript code/modelTrain.R --weight "data/model/model_to_train_final.h5" --summary --plot
  --weight:  the path of the model that we train
  --summary: to show the summary of the model structure(Optional)
  --plot:    to output a image of the model structure(Optional)
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Your presentation, 1112_DS-FP_groupID.ppt/pptx/pdf (i.e.,1112_DS-FP_group1.ppt), by **06.08**
* Any related document for the project
  * i.e., software user guide

### data
* Input
  * Structure
    * /WeatherData
      * data_of_weather_by_city.csv
      * 檔案格式```{city_no}{city_name}_200001-202304.csv```

      |欄位名稱: 年月|日|1-1氣壓(hPa)-平地平均|1-2氣壓(hPa)-海面平均|2-1降水量(mm)-合計|2-2降水量(mm)-一小時內最大|2-3降水量(mm)-10分鐘內最大|3-1氣温(℃)-平均|3-2氣温(℃)-最高|3-3氣温(℃)-最低|4-1湿度(％)-平均|4-2湿度(％)-最小|5-1風向・風速(m/s)-平均風速|5-2風向・風速(m/s)-最大風速|5-3風向・風速(m/s)-最大風向|5-4風向・風速(m/s)-最大瞬間風速|5-5風向・風速(m/s)-最大瞬間風向|6日照時間(h)|7-1雪(cm)-降雪|7-2雪(cm)-最深積雪|8-1天気概況-晝|8-2天気概況-夜|
      |-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|
      |範例: |200001|1|1019|1022.3|18.5|5.5|1.5|-3.3|-0.7|-5|86|53|1.5|5.3|北西|10.7|北西|4.5|34|53|晴後雪|雪|


    * /rds
      * the_data_after_genData_using_missForest.rds
      * test_data_x.rds
      * test_data_y.rds
      * train_data_x.rds
      * test_data_y.rds
    * japanmaincity-47-final.csv
      * 欄位

      |欄位名稱: |地區|NO|城市|緯度|經度|海拔|
      |-|-|-|-|-|-|-|
      |範例: |石狩地方|1|札幌|北緯43度03.6分|東經141度19.7分|17.4m|
    * sakura-first-47city.csv
      * 欄位: NO,地点名,1953,1954,...2022
      * 47個城市的櫻花開花日
    * sakura-full-47city.csv
      * 欄位: NO,地点名,1953,1954,...2022
      * 47個城市的櫻花滿開日


* Output
  * Structure
    * /rds
      * the_data_output_by_model.rds
      * 儲存的結果方便日後做其他分析

### code
* Step1. run code/genData.R to generate the data of training and testing
* Step2. run code/modelTrain.R to continue training or training a new model

* code 檔案功能

|位置|檔名|語言|作用|
|-|-|-|-|
|code/null_model|bollomDatte_weather.csv|csv|null model 用資料|
|code/null_model|finHW2.R|R|null model code|
|code/spider|日本氣象廳-1各地區各城市.ipynb|python|爬蟲抓取開花日|
|code/spider|日本氣象廳-2每日資料.ipynb|python|爬蟲抓取天氣資料|
|code/|lib.R|R|訓練模型與資料前處理會用到的 library|
|code/|Basevar.R|R|R中設定基本變數|
|code/|modelSetting.R|R|設定model的架構|
|code/|modelTrain.R|R|Train 模型|
|code/|final.R|R|撰寫途中產物，未有接受任何 arguement|

* Which method or package do you use? 
  * original packages in the paper
    * None
  * additional packages you found
    * Keras

### results
* What is a null model for comparison?
* How do your perform evaluation?
  * Cross-validation, or extra separated data

## References
* Packages you use
  * [missForest](https://cran.r-project.org/web/packages/missForest/index.html)
    - 補缺值用
  * [reticulate](https://cran.r-project.org/web/packages/reticulate/index.html)
* Related publications
  * 參考程式碼
    - https://github.com/TasnimAhmedEee/Cherry-Blossom-Date-Prediction/tree/master
  * 參考文獻
    - https://arxiv.org/pdf/2210.04406.pdf 2020 的論文，使用了 SVM 與 LSTM
    - https://pansci.asia/archives/115553 櫻花櫻花何時開！日本的櫻花預報「櫻前線」是怎麼算出來的？ - PanSci 泛科學
    - https://omdena.com/blog/time-series-classification-model-tutorial/
