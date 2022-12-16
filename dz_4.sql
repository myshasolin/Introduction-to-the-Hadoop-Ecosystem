/*
Задание 1
Подключиться к серверу, ввести команду hive, по очереди выполнить все команды из HSQL_1.sql, заменив student41_35 на своего пользователя. 
Сказать, какие действия мы выполняем в каждом из запросов/команд (на insert не забываем про tablesample). + ответить на вопросы, содержащиеся в HSQL_1.sql.

РЕШЕНИЕ:

Подключиться у меня не получилось ни под Windows, ни под Ubuntu 22.04, вылетает ошибка «Required field 'serverProtocolVersion' is unset!», 
поэтому для работы настроил Докер. Вот поэтапно то, что я сделал для этого:

1. скачал Docker отсюда:
https://github.com/big-data-europe/docker-hive

2. А csv-файл отсюда:
https://ourairports.com/data/ 

3. Развернул Docker так:
C:\Users\Mysha\Desktop\GB\Основное обучение\BigData. Введение в экосистему Hadoop\Урок 4. Hive & HUE\docker-hive-master> docker-compose up -d

4. Положил в него csv-файл в папку root
PS C:\Users\Mysha> docker cp "C:\Users\Mysha\Desktop\GB\Основное обучение\BigData. Введение в экосистему Hadoop\Урок 4. Hive & HUE\Роман Яковлев\airports.csv" docker-hive-master-hive-server-1:./root

5. Запустил контейнер:
PS C:\Users\Mysha\Desktop\GB\Основное обучение\BigData. Введение в экосистему Hadoop\Урок 4. Hive & HUE\docker-hive-master> docker-compose exec hive-server bash

6. в HDFS надо было создать директорию пользователя. Моё имя root
whoami
поэтому и папку назвал root
hdfs dfs -mkdir /user/root
Как проверить – команда hdfs dfs -ls после создания папки находит её и отрабатывать без ошибок
hdfs dfs -ls

7. Положил в HDFS .csv-файл в заготовленную для него папку, дабы не мусорить, дал ему права
hdfs dfs -mkdir dz_4
hdfs dfs -put airports.csv dz_4/
hdfs dfs -chmod 777 dz_4/airports.csv

8. Подключился к Hive. Работать можно через терминал
root@910af09ad5b6:/opt# /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
но это не тру, так как таблица у нас будет большая, а в у Hive я не нашёл приличных инструментов, чтоб такую большую таблицу в терминале нормально отображать 
(как, например, в MySQL, там в конце команды можно поставить DELIMITER не ; а \G). Так что дальнейшие шаги я делаю в dBeaver.
 */

-- грохнули базу если есть
DROP DATABASE IF EXISTS student42_18 CASCADE;

-- создали базу
CREATE DATABASE IF NOT EXISTS student42_18;

-- посмотрели на список баз, что есть сейчас

SHOW DATABASES;

-- ВОПРОС: зачем используем use?
-- ОТВЕТ: чтоб переключиться на работу с этой базой и не писать именя таблиц с названием базы типа SELECT * FROM база.таблица;
USE student42_18;

-- посмотрели на список таблиц в базе
SHOW TABLES;

-- создали EXTERNAL-таблицу, что берёт данные из .csv-файла, лежащего на HDFS. Предварительно грохаем эту таблицу если она есть
DROP TABLE IF EXISTS airport_codes;
CREATE EXTERNAL TABLE IF NOT EXISTS airport_codes(
	id INT,
	ident STRING,
	`type` STRING,
	name STRING,
	latitude_deg STRING,
	longitude_deg STRING,
	elevation_ft STRING,
	continent STRING,
	iso_country STRING,
	iso_region STRING,
	municipality STRING,
	scheduled_service STRING,
	gps_code STRING,
	iata_code STRING,
	local_code STRING,
	home_link STRING,
	wikipedia_link STRING,
	keywords STRING
) ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ','
  STORED AS TEXTFILE
  LOCATION '/root/dz_4/'
  TBLPROPERTIES ('skip.header.line.count'='1');
 
 -- ВОПОС: tblproperties ("skip.header.line.count"="1") --зачем нам эта опция?
 -- ОТВЕТ: для игнора первой строки с загоовками при загрузке .csv-файла в таблицу

 -- ВОПРОС: почему пишем лимит?
 -- ОТВЕТ: ограничение вывода строк
 -- смотрим на 5 строк таблицы (для того и LIMIT)
SELECT * FROM airport_codes LIMIT 5;

-- смотрим на DDL-запрос при создании таблицы, он немного отличается от того, что мы написали
SHOW CREATE TABLE airport_codes;

-- ВОПОС: что делаем в этих запросах?
-- ОТВЕТ: ну сдесь вот считаем уникальное значение в столбце `type`
SELECT COUNT(DISTINCT `type`) FROM airport_codes;
-- а здесь выводил эти значения
SELECT DISTINCT `type` FROM airport_codes;

-- создаём партиционированную таблицу по столбцу `type`, предварительно грохнув её, если она есть
DROP TABLE IF EXISTS airport_codes_part;
CREATE TABLE IF NOT EXISTS airport_codes_part(
	id INT,
	ident STRING,
	name STRING,
	latitude_deg STRING,
	longitude_deg STRING,
	elevation_ft STRING,
	continent STRING,
	iso_country STRING,
	iso_region STRING,
	municipality STRING,
	scheduled_service STRING,
	gps_code STRING,
	iata_code STRING,
	local_code STRING,
	home_link STRING,
	wikipedia_link STRING,
	keywords STRING
) PARTITIONED BY (`type` STRING)
  ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
  STORED AS TEXTFILE
  LOCATION '/root/airport_codes_part';

-- код DDL-команды создания таблицы
SHOW CREATE TABLE airport_codes_part;
 
-- без определения hive.exec.dynamic.partition.mode=nonstric при заливке данных в таблицу вылетела ошибка, так что вот

SET hive.exec.dynamic.partition.mode=nonstric;

-- заливаем данные в airport_codes_part из airport_codes 1000 рандомных строк
INSERT INTO TABLE airport_codes_part 
PARTITION(`type`)
SELECT 
	id,	ident, name, latitude_deg, longitude_deg, elevation_ft,
	continent, iso_country, iso_region, municipality, scheduled_service,
	gps_code, iata_code, local_code, home_link, wikipedia_link,	keywords,
	`type`
FROM airport_codes
TABLESAMPLE (1000 rows);

-- любуемся результатом
SELECT * FROM airport_codes_part LIMIT 10;
-- смотрим уникальные `type`
SELECT DISTINCT `type` FROM airport_codes_part;

-- так можем посчитать и посмотреть количество строк в каждом `type`
SELECT 
	`type`, COUNT(1) AS `count`
FROM airport_codes_part 
GROUP BY `type`
ORDER BY `count` DESC;

-- ВОПОРС: теперь посмотри в path таблицы через hdfs dfs -ls/-du и скажи, что заметил и почему там всё так
-- ОТВЕТ:
-- мы можем зайти в одну из папок, которая создаётся для партиций и полный путь к которой можно увидеть в DDL-команде в LOCATION
-- например, вот у меня путь до одной из папок:
-- hdfs dfs -ls hdfs://namenode:8020/root/airport_codes_part/type=%22balloonport%22
-- а в ней файл
-- -rwxr-xr-x   3 root supergroup       5464 2022-11-28 01:31 hdfs://namenode:8020/root/airport_codes_part/type=%22balloonport%22/000000_0
-- если добавить новый файл аналогичной структуры, то в таблице значения из него отображаться не будут, так как этого файла нет в метаданных Hive Metastore
-- добавить его туда можно так:
MSCK REPAIR TABLE airport_codes_part;

-- а вот удалять вайлы партиций просто так не стоит, это поломает таблицу. Удалять их можно через ALTER TABLT вот так:
ALTER TABLE airport_codes_part DROP IF EXISTS PARTITION(TYPE='new_type');

-- вот всё что удалили взяло такое и удалилось, можем проверить:
SELECT DISTINCT `type` FROM airport_codes_part;

-- ВОПРОС: --что такое temporary table и когда лучше использовать?
-- ОТВЕТ: аременная таблица, которая живёт только во время сессии (так и во время сессии можно удалить)
-- сплошные преимущества от неё - долго не хранится, пространство имён для нас сохраняет, идеальная для всяких промежуточных вычислений и вытягивания данных

-- ВОПРОС: --что будет с содержимым таблицы, если колонки, по которым партиционируем, будут стоять не последними в селекте?
-- ОТВЕТ: код отработает без ошибки, однако партиции создадутся то тому столбцу, который будет указан последним.
-- Тем самым мы поломаем таблицу. Вот почему так важно следить за порядком следования столбцов

-- ВОПРОС:
--STREAMING
--выполни в баше это и скажи, что мы тут делаем:
--    seq 0 9 > col_1 && seq 10 19 > col_2
--    paste -d'|' col_1 col_2 | hdfs dfs -appendToFile - test_tab/test_tab.csv
-- ОТВЕТ:
-- создаём 2 файла c цифрами от 0 до 9 в col_1 и от 10 до 19 в col_2
-- seq 0 9 > col_1 && seq 10 19 > col_2 с выводом цифр
-- с помощью "paste -d'|'" "склеиваем" эти файлы, далее перенаправляем поток в HDFS
-- "-appendToFile" может "приклеить" какой-то локальный файл к имеющемуся файлу в HDFS, но мы не указали никакого файла в HSDF, а поставили -
-- ==> "-appendToFile -" отработает, так, что bash будет брать данные из команд, написанных до перенаправления в HDFS
-- test_tab/test_tab.csv - результат сложится сюда. Если этих папки и файла ещё нет, создадутся

-- создаём TEMPORARY EXTERNAL таблицу, предварительно грохнув её, если она уже есть, записываем в неё данные из test_tab.csv
DROP TABLE IF EXISTS my_test_lab;
CREATE TEMPORARY EXTERNAL TABLE IF NOT EXISTS my_test_lab (
	col_1 INT, 
	col_2 INT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY "|" 
LOCATION "/root/test_tab/test_tab.csv";

-- вот она
SELECT * FROM my_test_lab;

-- ВОПРОС: --что тут произошло и как это можно использовать ещё?
SELECT 
	TRANSFORM(col_1, col_2) USING "awk '{print $1+$2}'" AS my_sum
FROM my_test_lab;
-- ОТВЕТ: это т.н. Hive Streaming, при котором мы можем писать код на любом языке, а данные будут подаваться в универсальномм текстовом виде
-- скрипт на вход будет принимать данные, как-то обрабатывать их и возвращать. В TRANSFORM передаются нужные для скрипта колонки, 
-- а в USING пишется вызов функции. В примере для простоты в USING обрабатывает bash-комвнда awk '{print...}' и скадываются значения строк

-- альтернатива хранимым процедурам в Hive - запуск скрипта с командами:
-- hive -f файл.hql
-- альтернатива функциям в Hive: 
--
-- 1) писать на JAVA или Scala и вызывать функцию:
-- add jar /путь/до/файла.jar
-- CREATE TEMPORARY FUNCTION название AS 'ссылка.на.скрпт.из.файла';
-- SELECT название (аргументы) FROM таблица;
--
-- 2) использовать Hive Streaming (о нём выше)

/*
Задание 2
Сказать какие особенности, касающиеся синтаксиса HiveQL надо учитывать, создавая таблицу с партиционированием и при инсерте в неё. Зачем нам нужно партиционирование?

РЕШЕНИЕ:
Партиционирование – это инструмент оптимизации хранения данных, благодаря которому может существенно вырасти скорость обработки запросов. 
За счёт партиционирования SELECT-запросу не придётся сканировать всю таблицу сверху вниз, но только ту её часть, которая может быть для нас интересна и которая указана в условии WHERE.

При партиционировании создаются папки с т.н. партициями, в них складываются данные по условию партиционирования. 

Партиционирование правильно делать на значения, которые можно более-менее крупно и равномерно группировать и распределять по папкам. 
Иначе насоздаётся много папок в HDFS (и это с и без того блочным-то устройством памяти) и всё будет только тормозить.

Партиционирование нужно выстраивать исходя из наиболее часто ожидаемых запросов к данным в будущем, чтоб от него действительно была польза.

При создании таблиц с партиционированием важно внимательно следить за синтаксисом и логикой запроса, 
т.к. в Hive может быть много синтаксических «подводных камней», при которых ошибки вроде и не будет, но данные испортятся.

Бывает по разному, но обычно партиции создаются где-то в папке warehouse . Если же в запросе явно указать в LOCATION ‘сюда/’ папку, то по этому пути и будут создаваться партиции.

На каждую партицию в HDFS лучше создавать свою папку, чтоб ничего нигде не запуталось и не законфликтовало, т.к. в каждую такую папку может складываться много батчей.

Общий синтаксис создания таблицы с партиционированием в SQL устроен так, что нужно создать таблицу, перечислив все столбцы, 
но убрав при этом из перечисления тот столбец, по которому будет осуществляться партиционирование. Его же нужно указать ниже в PARTITIONED BY.

Во многих SQL можно настроить специальную транзакцию, а в ней настроить партиционирование по первому дню месяца, тогда партиции будут создаваться по месяцам. 
В большинстве SQL ещё можно добавить какое-то условие, к примеру, «партиционировать по колонке «дата» каждые 30 дней». У Hive такой тонкой настройки нет.

Можно организовать партиционирование по нескольким параметрам. Получится такая вот вложенная структура с папками в папках. 
Тогда столбцы или параметры, по которым будет производиться партиционирование, перечисляются друг за другом через запятую.

При INSERT может вылетать ошибка, у меня вот вылетала. Тогда до него нужно установить параметр для hive.exec.dynamic.partition.mode=nonstric

Ещё в INSERT таблицы с партициями перечисляются сначала PARTITION(здесь) партиции, а уже после перечисляются остальные столбцы, 
последний из которых – это столбец, по которому партиция будет производиться (его обязательно указываем последним).

При INSETR INTO SELECT-запросто просто указать SELECT * FROM можно только в том случае, если мы знаем, что столбец, по котором будет производиться 
партицирование, среди всех столбцов действительно стоит последним. И вообще, порядок следования столбцов крайне важен, за этим нужно внимательно следить.
 */


/*
Задание 3
Переписать «select …» в команде «create temporary table» используя “with” для объявления t2; пример:
Hive WITH clause example with the SELECT statement
WITH t1 as (SELECT 1),
t2 as (SELECT 2),
t3 as (SELECT 3)
SELECT * from t1
UNION ALL
SELECT * from t2
UNION ALL
SELECT * from t3;
*/

-- вот так, к примеру, можно выбрать 3 случайных аэропорта разного типа
DROP TABLE IF EXISTS random_airport_sample;
CREATE TEMPORARY TABLE IF NOT EXISTS random_airport_sample AS
WITH 
	t1 AS
		(SELECT 
			ident, name, `type`, continent, iso_region, gps_code, iata_code, local_code 
		FROM airport_codes 
		WHERE `type` LIKE '%small%' 
		ORDER BY RAND() LIMIT 1), -- один случайный маленький аэропорт 
	t2 AS 
		(SELECT 
			ident, name, `type`, continent, iso_region, gps_code, iata_code, local_code 
		FROM airport_codes 
		WHERE `type` LIKE '%medium%' 
		ORDER BY RAND() LIMIT 1), -- один случайный средний аэропорт 
	t3 AS 
		(SELECT 
			ident, name, `type`, continent, iso_region, gps_code, iata_code, local_code 
		FROM airport_codes 
		WHERE `type` LIKE '%seaplane%' 
		ORDER BY RAND() LIMIT 1) -- одина случайная база гидросамолётов
SELECT * FROM t1 
UNION ALL
SELECT * FROM t2
UNION ALL 
SELECT * FROM t3;

-- ля что получлось:
SELECT * FROM random_airport_sample;

/*
Задание 4
*Создать таблицу airport_codes_part_2 c партиционированием по 2 колонкам: type и iso_country. 
Вставить в неё 1000 строк, запросом select вывести самую популярную связку type iso_country используя оконную функцию row_number 
*/

-- создаём
DROP TABLE IF EXISTS airport_codes_part_2;
CREATE TABLE IF NOT EXISTS airport_codes_part_2(
	id INT,
	ident STRING,
	name STRING,
	latitude_deg STRING,
	longitude_deg STRING,
	elevation_ft STRING,
	continent STRING,
	iso_region STRING,
	municipality STRING,
	scheduled_service STRING,
	gps_code STRING,
	iata_code STRING,
	local_code STRING,
	home_link STRING,
	wikipedia_link STRING,
	keywords STRING
) PARTITIONED BY (`type` STRING, iso_country STRING)
  ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
  STORED AS TEXTFILE
  LOCATION '/root/airport_codes_part_2';

-- код DDL-команды создания таблицы

SHOW CREATE TABLE airport_codes_part_2;
 
-- без определения hive.exec.dynamic.partition.mode=nonstric при заливке данных в таблицу вылетела ошибка, так что вот

SET hive.exec.dynamic.partition.mode=nonstric;

-- заливаем данные в airport_codes_part_2 из airport_codes 1000 рандомных строк
INSERT INTO TABLE airport_codes_part_2 
PARTITION(`type`, iso_country)
SELECT 
	id,	ident, name, latitude_deg, longitude_deg, elevation_ft,
	continent, iso_region, municipality, scheduled_service,
	gps_code, iata_code, local_code, home_link, wikipedia_link,	keywords,
	`type`, iso_country
FROM airport_codes
TABLESAMPLE (1000 rows);

-- считаем строки и смотрим на них, любуемся
SELECT
	id, `type`, name,
	COUNT(*) OVER() AS `total score`
FROM airport_codes_part_2
ORDER BY id;

-- насколько я понял задание, то речь о том, что нужно найти самую повторяемую пару "type-iso_country"
-- если так, то эта пара "smail-airport"-"US", она в моей выборке встречается 534 раза
SELECT 
	`type`,
	iso_country,
	ROW_NUMBER() OVER(PARTITION BY `type` ORDER BY iso_country) AS counter
FROM airport_codes_part_2
ORDER BY counter DESC LIMIT 1;

-- вот так результат тот же, но через COUNT()
SELECT 
	`type`,
	iso_country,
	COUNT() OVER(PARTITION BY `type` ORDER BY iso_country) AS counter
FROM airport_codes_part_2
ORDER BY counter DESC LIMIT 1;

-- 3 строчки, на самом деле, лежат в другом месте, они и не сортируются как положено, но в общем подсчёте участвуют
-- это подтверждается и подсчётом кол-ва строк в файле-партиции
-- путь до нео смотрим здесь:
SHOW CREATE TABLE airport_codes_part_2;

-- а строки считаем через wc
/*
root@e07f4c457369:/opt# hdfs dfs -cat hdfs://namenode:8020/root/airport_codes_part_2/type=%22small_airport%22/iso_country=%22US%22/000000_0 | wc -l
531
*/ 


