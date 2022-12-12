--Всем привет!
--В качестве 5го дз вам будет нужно повторить экперимент, проведенный на лекции:
--1. Развернуть кластер через Docker (или выполнить ДЗ на учебном клстере, удалив файлы потом)
--2. Загрузить в наш развернутый hdfs самый большой файл из датасета и сделать external table (образец с лекции тут )
--3. Далее создать таблицы с разными форматами как в local_hive.sql и попробовать пописать различные запросы, засечь и сравнить время.
--4. Повторить эксперимент с паркетом и orc добавив 2 различных сжатия (GZIP/SNAPPY) и сравнить получившийся размер файлов с изначальным, 
-- а так же время выполнения запросов.

USE student42_18;

--1. Развернуть кластер через Docker (или выполнить ДЗ на учебном клстере, удалив файлы потом)
-- РЕШЕНИЕ: развернул, только в нём и работаю

--2. Загрузить в наш развернутый hdfs самый большой файл из датасета и сделать external table (образец с лекции тут )
-- РЕШЕНИЕ: вот он 
/*
root@e07f4c457369:/opt# hdfs dfs -du -h /root/uberdata
526.1 M  /root/uberdata/uber-raw-data-janjune-15.csv
 */

--3. Далее создать таблицы с разными форматами как в local_hive.sql и попробовать пописать различные запросы, засечь и сравнить время.
--4. Повторить эксперимент с паркетом и orc добавив 2 различных сжатия (GZIP/SNAPPY) 
-- и сравнить получившийся размер файлов с изначальным, а так же время выполнения запросов.
-- РЕШЕНИЕ: 

-- 1) EXTERNAL TABLE
DROP TABLE IF EXISTS uber_data_ex;
CREATE EXTERNAL TABLE uber_data_ex(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT
)ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/root/uberdata'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(1) FROM uber_data_ex; -- время 5 512
SELECT COUNT(locationID) FROM uber_data_ex; -- время 7 526
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex; -- время 7 511

-- 2) CSV
DROP TABLE IF EXISTS uber_data_ex_csv;
CREATE TABLE uber_data_ex_csv(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS TEXTFILE
LOCATION '/root/uberdata_csv';
INSERT OVERWRITE TABLE uber_data_ex_csv 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_csv; -- время 216
SELECT COUNT(locationID) FROM uber_data_ex_csv; -- время 8 708
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_csv; -- время 8 660

-- 3) SEQUENCEFILE
DROP TABLE IF EXISTS uber_data_ex_sq;
CREATE TABLE uber_data_ex_sq(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS SEQUENCEFILE
LOCATION '/root/uberdata_sq';
INSERT OVERWRITE TABLE uber_data_ex_sq 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_sq; -- время 232
SELECT COUNT(locationID) FROM uber_data_ex_sq; -- время 30 632
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_sq; -- время 31 747

-- 4) PARQUET
DROP TABLE IF EXISTS uber_data_ex_pq;
CREATE TABLE uber_data_ex_pq(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS PARQUET
LOCATION '/root/uberdata_pq';
INSERT OVERWRITE TABLE uber_data_ex_pq 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_pq; -- время 191
SELECT COUNT(locationID) FROM uber_data_ex_pq; -- время 6 478
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_pq; -- время 5 452

-- 5) PARQUET-SNAPPY

SET parquet.compression=SNAPPY;
DROP TABLE IF EXISTS uber_data_ex_pq_SNAPPY;
CREATE TABLE uber_data_ex_pq_SNAPPY(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS PARQUET
LOCATION '/root/uberdata_pq_SNAPPY';
INSERT OVERWRITE TABLE uber_data_ex_pq_SNAPPY 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_pq_SNAPPY; -- время 209
SELECT COUNT(locationID) FROM uber_data_ex_pq_SNAPPY; -- время 6 787
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_pq_SNAPPY; -- время 5 483

-- 6) PARQUET-GZIP

SET parquet.compression=FALSE;
DROP TABLE IF EXISTS uber_data_ex_pq_GZIP;
CREATE TABLE uber_data_ex_pq_GZIP(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS PARQUET
LOCATION '/root/uberdata_pq_GZIP';
INSERT OVERWRITE TABLE uber_data_ex_pq_GZIP 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_pq_GZIP; -- время 166
SELECT COUNT(locationID) FROM uber_data_ex_pq_GZIP; -- время 6 519
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_pq_GZIP; -- время 6 266

-- 7) ORC
DROP TABLE IF EXISTS uber_data_ex_orc;
CREATE TABLE uber_data_ex_orc(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS ORC
LOCATION '/root/uberdata_orc';
INSERT OVERWRITE TABLE uber_data_ex_orc 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_orc; -- время 238
SELECT COUNT(locationID) FROM uber_data_ex_orc; -- время 6 635
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_orc; -- время 7 433

-- 8) ORC-SNAPPY

SET orc.compression=SNAPPY;
DROP TABLE IF EXISTS uber_data_ex_orc_SNAPPY;
CREATE TABLE uber_data_ex_orc_SNAPPY(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS ORC
LOCATION '/root/uberdata_orc_SNAPPY';
INSERT OVERWRITE TABLE uber_data_ex_orc_SNAPPY 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_orc_SNAPPY; -- время 233
SELECT COUNT(locationID) FROM uber_data_ex_orc_SNAPPY; -- время 7 774
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_orc_SNAPPY; -- время 6 851

-- 9) ORC-GZIP

SET orc.compression=GZIP;
DROP TABLE IF EXISTS uber_data_ex_orc_GZIP;
CREATE TABLE uber_data_ex_orc_GZIP(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS ORC
LOCATION '/root/uberdata_orc_GZIP';
INSERT OVERWRITE TABLE uber_data_ex_orc_GZIP 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_orc_GZIP; -- время 174
SELECT COUNT(locationID) FROM uber_data_ex_orc_GZIP; -- время 6 392
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_orc_GZIP; -- время 7 420

-- 10) AVRO
DROP TABLE IF EXISTS uber_data_ex_avro;
CREATE TABLE uber_data_ex_avro(
	Dispatching_base_num STRING,
	Pickup_date TIMESTAMP,
	Affiliated_base_num STRING,
	locationID INT)
STORED AS AVRO
LOCATION '/root/uberdata_avro';
INSERT OVERWRITE TABLE uber_data_ex_avro 
SELECT * FROM uber_data_ex;

SELECT COUNT(1) FROM uber_data_ex_avro; -- время 109
SELECT COUNT(locationID) FROM uber_data_ex_avro; -- время 36 448
SELECT COUNT(DISTINCT dispatching_base_num) FROM uber_data_ex_avro; -- время 39 440


-- ну и вес таблиц:
/*
root@e07f4c457369:/opt# hdfs dfs -du -h -s /root/uberdata*
526.1 M  /root/uberdata
351.2 M  /root/uberdata_avro
512.5 M  /root/uberdata_csv
36.5 M  /root/uberdata_orc
36.5 M  /root/uberdata_orc_GZIP
36.5 M  /root/uberdata_orc_SNAPPY
50.6 M  /root/uberdata_pq
50.6 M  /root/uberdata_pq_GZIP
66.7 M  /root/uberdata_pq_SNAPPY
682.5 M  /root/uberdata_sq
 */


-- соберём для наглядности результаты в единую сводную
DROP TABLE IF EXISTS uber_res;
CREATE TABLE uber_res(
	name VARCHAR(20),
	`count_*` DOUBLE,
	count_licationID DOUBLE,
	count_dostinct DOUBLE,
	file_weight DOUBLE);

INSERT INTO TABLE uber_res VALUES
	('EXTERNAL TABLE', 5.512, 7.526, 7.511, 526.1),
	('CSV', 0.216, 8.708, 8.660, 512.5),
	('SEQUENCEFILE', 0.232, 30.632, 31.747, 682.5),
	('PARQUET', 0.191, 6.478, 5.452, 50.6),
	('PARQUET-SNAPPY', 0.209, 6.787, 5.483, 66.7),
	('PARQUET-GZIP', 0.166, 6.519, 6.266, 50.6), 
	('ORC', 0.238, 6.635, 7.433, 36.5),
	('ORC-SNAPPY', 0.233, 7.774, 6.851, 36.5),
	('ORC-GZIP', 0.174, 6.392, 7.420, 36.5),
	('AVRO', 0.109, 36.448, 39.44, 351.2)

/*
SELECT * FROM uber_res;
+-----------------+-------------------+----------------------------+--------------------------+-----------------------+
|  uber_res.name  | uber_res.count_*  | uber_res.count_licationid  | uber_res.count_dostinct  | uber_res.file_weight  |
+-----------------+-------------------+----------------------------+--------------------------+-----------------------+
| EXTERNAL TABLE  | 5.512             | 7.526                      | 7.511                    | 526.1                 |
| CSV             | 0.216             | 8.708                      | 8.66                     | 512.5                 |
| SEQUENCEFILE    | 0.232             | 30.632                     | 31.747                   | 682.5                 |
| PARQUET         | 0.191             | 6.478                      | 5.452                    | 50.6                  |
| PARQUET-SNAPPY  | 0.209             | 6.787                      | 5.483                    | 66.7                  |
| PARQUET-GZIP    | 0.166             | 6.519                      | 6.266                    | 50.6                  |
| ORC             | 0.238             | 6.635                      | 7.433                    | 36.5                  |
| ORC-SNAPPY      | 0.233             | 7.774                      | 6.851                    | 36.5                  |
| ORC-GZIP        | 0.174             | 6.392                      | 7.42                     | 36.5                  |
| AVRO            | 0.109             | 36.448                     | 39.44                    | 351.2                 |
+-----------------+-------------------+----------------------------+--------------------------+-----------------------+
*/

