# [GroupID] your projrct title
The goals of this project.

## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|何彥南|資科碩二|110753202|團隊中的吉祥物🦒，負責增進團隊氣氛| 
|張小銘|資科碩二|xxxxxxxxx|團隊的中流砥柱，一個人打十個|

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
Rscript code/genData.R # to generate input data and save to the RDS
Rscript code/modelTrain.R --weight "data/model/model_to_train_final.h5" --summary --plot
  --weight: the path of the model that we train
  --summary: to show the summary of the model structure
  --plot: to output a image of the model structure
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Your presentation, 1112_DS-FP_groupID.ppt/pptx/pdf (i.e.,1112_DS-FP_group1.ppt), by **06.08**
* Any related document for the project
  * i.e., software user guide

### data
* Input
  * /WeatherData
  * /rds
* Output
  * /rds

### code
* Analysis steps
* Which method or package do you use? 
  * original packages in the paper
  * additional packages you found

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