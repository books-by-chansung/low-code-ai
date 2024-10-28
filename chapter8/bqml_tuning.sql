## 데이터셋을 생성하고 테이블로 불러오기 위한, 빅쿼리용 SQL입니다. 콘솔을 사용하는 방법은 8장을 참고하기 바랍니다

CREATE SCHEMA car_sales_prices OPTIONS(location='US');

LOAD DATA OVERWRITE cars_sales_prices.car_prices_train
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_train.csv']
  );
 
 LOAD DATA OVERWRITE cars_sales_prices.car_prices_valid
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_valid.csv']
  );

LOAD DATA OVERWRITE cars_sales_prices.car_prices_test
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_test.csv']
  );
  
## 데이터의 일부 행을 탐색하고 전처리하기 위한 SQL 문

SELECT
  * EXCEPT (int64_field_0, mmr, odometer, year, condition),
  ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
  ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
  ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
  ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
  ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior
FROM
  `car_sales_prices.car_prices_train`
LIMIT 10;

## TRANSFORM 문을 곁들여 선형 모델을 생성하는 MODEL 문

CREATE OR REPLACE MODEL
  `car_sales_prices.linear_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='linear_reg',
    input_label_cols=['sellingprice'],
    data_split_method='NO_SPLIT') AS
SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;

## linear_car_model 모델에 대한 ML.EVALUATE 문

SELECT mean_absolute_error
FROM ML.EVALUATE(MODEL `ddml.linear_car_model`,
    (SELECT * FROM `car_sales_prices.car_prices_valid`))

## linear_car_model 모델에 대한 ML.PREDICT 문

SELECT *
FROM ML.PREDICT(MODEL `ddml.linear_car_model`,
    (SELECT * FROM `car_sales_prices.car_prices_valid`));
    
## DNN 모델을 생성하기 위한 CREATE MODEL 문

CREATE OR REPLACE MODEL
  `car_sales_prices.dnn_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='dnn_regressor',
    hidden_units=[64, 32, 16],
    input_label_cols=['sellingprice'],
    data_split_method='NO_SPLIT') AS
SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;

## 빅쿼리 ML의 DNN을 위한 하이퍼파라미터 튜닝 작업

CREATE OR REPLACE MODEL
  `car_sales_prices.dnn_hp_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='dnn_regressor',
    hidden_units=hparam_candidates([STRUCT([64,32,16]), 
                                    STRUCT([32,16]),
                                    STRUCT([32])]),
    dropout=hparam_range(0,0.8),
    input_label_cols=['sellingprice'],
    num_trials = 10,
    hparam_tuning_objectives=['mean_absolute_error']) 
AS SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;


## 후보 모델에 대한 평가 지표를 확인하기 위한 ML.TRIAL_INFO 함수 사용

SELECT
  *
FROM
  ML.TRIAL_INFO(MODEL `car_sales_prices.dnn_hp_car_model`)






