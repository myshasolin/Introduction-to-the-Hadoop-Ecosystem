USE student42_18;

-- рейтинг Spotify за 2020-2021 гг., датасет отсюда: https://www.kaggle.com/datasets/dhruvildave/spotify-charts
DROP TABLE IF EXISTS spotify_charts;
CREATE TEMPORARY EXTERNAL TABLE spotify_charts(
	title STRING, `rank` INT, `date` DATE, artist STRING,
	url STRING, region STRING, chart STRING, trend STRING, streams INT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/root/spotify'
TBLPROPERTIES ('skip.header.line.count'='1');

-- русские артисты
DROP TABLE IF EXISTS spotify_charts_russia;
CREATE TABLE spotify_charts_russia(
	title STRING, `rank` INT, `date` DATE, artist STRING,
	url STRING, region STRING, chart STRING, trend STRING, streams INT
) STORED AS ORC LOCATION '/root/spotify';
INSERT OVERWRITE TABLE spotify_charts_russia 
SELECT * FROM spotify_charts WHERE region='Russia';

-- вот они
SELECT * FROM spotify_charts_russia;

-- топы по стримам в 2020-м году MORGENSHTERN, BTS, SLAVA MARLOW
SELECT
	artist,	title, `rank`, streams,	trend, `date`
FROM spotify_charts_russia
WHERE YEAR(`date`) = 2020
ORDER BY streams DESC;

-- а в 2021-м году INSTASAMKA прям вырвалась вперёд
SELECT
	artist,	title, `rank`, streams,	trend, `date`
FROM spotify_charts_russia
WHERE YEAR(`date`) = 2021
ORDER BY streams DESC;

--ну и вот пример JOIN - соединяем 2 таблицы, топ-артист оттуда, топ-артист отсюда
DROP TABLE IF EXISTS top_2020;
CREATE TEMPORARY TABLE IF NOT EXISTS top_2020 AS
SELECT
	artist,	title, `rank`, streams, trend, `date`
FROM spotify_charts_russia 
WHERE YEAR(`date`) = 2020
ORDER BY streams DESC;

DROP TABLE IF EXISTS top_2021;
CREATE TEMPORARY TABLE IF NOT EXISTS top_2021 AS
SELECT
	artist,	title, `rank`, streams, trend, `date`
FROM spotify_charts_russia 
WHERE YEAR(`date`) = 2021
ORDER BY streams DESC;


SELECT 
	top_2020.`date`, top_2020.artist, top_2020.title, top_2020.streams,
	top_2021.`date`, top_2021.artist, top_2021.title, top_2021.streams
FROM top_2020
JOIN top_2021 ON top_2020.trend = top_2021.trend
WHERE YEAR(top_2020.`date`) = 2020 AND YEAR(top_2021.`date`) = 2021
LIMIT 1;

