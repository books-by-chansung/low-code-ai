-- 6장에서 사용된 SQL 쿼리
-- 이래의 SQL을 사용하고자하는 경우, your-project-id 문자열을 실제 구글 클라우드 프로젝트 식별자로 대체하여야 합니다.

-- Temp 열의 NULL 값을 확인합니다

SELECT 
  IF(Temp IS NULL, 1, 0) AS is_temp_null
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- 모든 열의 NULL 값을 확인합니다

SELECT
  SUM(IF(Temp IS NULL, 1, 0)) AS no_temp_nulls,
  SUM(IF(Exhaust_Vacuum IS NULL, 1, 0)) AS no_ev_nulls,
  SUM(IF(Ambient_Pressure IS NULL, 1, 0)) AS no_ap_nulls,
  SUM(IF(Relative_Humidity IS NULL, 1, 0)) AS no_rh_nulls,
  SUM(IF(Energy_Production IS NULL, 1, 0)) AS no_ep_nulls
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- Temp 열의 MIN(최솟값)과 MAX(최댓값)을 계산합니다

SELECT
  MIN(Temp) as min_temp,
  MAX(Temp) as max_temp
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- 모든 열의 MIN(최솟값)과 MAX(최댓값)을 계산합니다

SELECT 
  MIN(Temp) as min_temp,
  MAX(Temp) as max_temp,
  MIN(Exhaust_Vacuum) as min_ev,
  MAX(Exhaust_Vacuum) as max_ev,
  MIN(Ambient_Pressure) as min_ap,
  MAX(Ambient_Pressure) as max_ap,
  MIN(Relative_Humidity) as min_rh,
  MAX(Relative_Humidity) as max_rh,
  MIN(Energy_Production) as min_ep,
  MAX(Energy_Production) as max_ep
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- 전처리된 데이터를 위한 테이블을 생성합니다

CREATE TABLE
  `data_driven_ml.ccpp_cleaned`
AS
  SELECT 
    *
  FROM 
    `your-project-id.data_driven_ml.ccpp_raw`
  WHERE
    Temp BETWEEN 1.81 AND 37.11 AND
    Ambient_Pressure BETWEEN 992.89 AND 1033.30 AND
    Relative_Humidity BETWEEN 25.56 AND 100.16 AND
    Exhaust_Vacuum BETWEEN 25.36 AND 81.56 AND
    Energy_Production BETWEEN 420.26 AND 495.76

-- Temp와 Exhaust_Vacuum 열 사이의 피어슨 상관 계수를 계산합니다

SELECT
  CORR(Temp, Exhaust_Vacuum)
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Temp와 다른 열 사이의 피어슨 상관 계수를 계산합니다

SELECT 
  CORR(Temp, Ambient_Pressure) AS corr_t_ap,
  CORR(Temp, Relative_Humidity) AS corr_t_rh,
  CORR(Temp, Exhaust_Vacuum) AS corr_t_ev
FROM 
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- 빅쿼리 ML로 선형 회귀 모델을 생성하는 SQL 입니다

CREATE OR REPLACE MODEL data_driven_ml.energy_production 
  OPTIONS(model_type='linear_reg',
          input_label_cols=['Energy_Production']) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- 학습된 선형 회귀 모델을 평가합니다

SELECT
  *
FROM
  ML.EVALUATE(MODEL data_driven_ml.energy_production)

-- 단일 데이터에 대해 예측을 수행합니다

SELECT
  *
FROM
  ML.PREDICT(MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      27.45 AS Temp,
      1001.23 AS Ambient_Pressure,
      84 AS Relative_Humidity,
      65.12 AS Exhaust_Vacuum) )

-- 전역 "설명 가능성" 기능을 활성하고, 빅쿼리 ML로 선형 회귀 모델을 학습시킵니다

CREATE OR REPLACE MODEL data_driven_ml.energy_production
  OPTIONS(model_type='linear_reg',
          input_label_cols=['Energy_Production'],
          enable_global_explain=TRUE) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- ML.GLOBAL_EXPLAIN 함수를 사용합니다

SELECT 
  *
FROM
  ML.GLOBAL_EXPLAIN(MODEL `data_driven_ml.energy_production`)

-- 설명 가능성 기능과 함께 예측을 수행합니다

SELECT
  *
FROM
  ML.EXPLAIN_PREDICT(
    MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      Temp,
      Ambient_Pressure,
      Relative_Humidity,
      Exhaust_Vacuum
    FROM
      `your-project-id.some_dataset.some_table`),
    STRUCT(3 AS top_k_features) )

-- 회귀를 위한 신경망 모델을 학습시킵니다

CREATE OR REPLACE MODEL data_driven_ml.energy_production_nn
  OPTIONS 
    (model_type='dnn_regressor',
     hidden_units=[32,16,8],
     input_label_cols=['Energy_Production']) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- 학습된 신경망 모델을 평가합니다

SELECT
  *
FROM
  ML.EVALUATE(MODEL data_driven_ml.energy_production)

-- 신경망 모델로 단일 데이터에 대해 예측을 수행합니다

SELECT
  *
FROM
  ML.PREDICT(MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      27.45 AS Temp,
      1001.23 AS Ambient_Pressure,
      84 AS Relative_Humidity,
      65.12 AS Exhaust_Vacuum) )


