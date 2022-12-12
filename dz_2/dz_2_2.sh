пример curl

1) подключаемся

PS C:\Users\Mysha> ssh -L 8088:bigdataanalytics-head-0.mcs.local:8088 -i "C:\Users\Mysha\Desktop\GB\Основное обучение\BigData. Введение в экосистему Hadoop\MobaXterm\id_rsa_student42_18.pem" student42_18@37.139.41.176
Last login: Tue Dec  6 01:36:30 2022 from 78.129.253.9

2) качаем Маленького принца в HDFS

[student42_18@bigdataanalytics-worker-3 ~]$ curl -sS https://www.6lib.ru/download/malen_kii_princ-24175.txt | hdfs dfs -put -f - princ.txt

3) читаем, наслаждаемся

[student42_18@bigdataanalytics-worker-3 ~]$ hdfs dfs -cat princ.txt | head -10
<!doctype html>
<html lang="ru">
<head>
        <title>Маленький Принц скачать в формате txt бесплатно для android, iphone, ipad</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="robots" content="index, follow" />
        <meta name="description" content="Маленький Принц скачать в формате txt бесплатно для android, iphone, ipad без регистрации и смс" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />

        <link rel="apple-touch-icon" sizes="57x57" href="/images/icons/apple-touch-icon-57x57.png">
[student42_18@bigdataanalytics-worker-3 ~]$