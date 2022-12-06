#!/bin/bash

echo -e "1) создаём пустые файлы и запишем в каждый своё. Ну и посмотрим, что мы в них записали:\n"
STR="Hello, hdfs !"
NUM=1
for i in $STR; do
    echo $i > test_file_$NUM
    let NUM+=1
done
cat test_file_*

echo -e "\n2) положим эти файлы в hdfs в папку под именем dz_2 и уже в ней с помощью -setrep сделаем репликацию = 2 (хотя она вообще-то и так = 2)\n"
hdfs dfs -mkdir dz_2
hdfs dfs -put test_file_* dz_2/
hdfs dfs -setrep 2 dz_2/*

echo -e "\n3) ещё мы инфу из файлов запишем во временный файл templog.txt, здесь будут дата записи ну и сам текст, и прочитаем этот файл:\n"
for i in {1..3}; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') $(hdfs dfs -cat dz_2/test_file_$i)" | awk '{print $1 " " $2 "      " $3}' >> templog.txt
done
cat templog.txt

echo -e "\n4) перемещаем файлы в папку task_2, снесём ненужную теперь папку dz_2, ну и на содержимое папки task_2 посмотрим, а там у нас:\n"
hdfs dfs -mkdir task_2
hdfs dfs -mv dz_2/test_file_* task_2
hdfs dfs -rm -r -skipTrash dz_2
hdfs dfs -du task_2

echo -e "\n5) размеры файлов с их репликациями они вот такие:\n"
hdfs dfs -du task_2/* | awk '{print $2}'

echo -e "\n6) к инфе из файла templog.txt добавим размеры файлов с репликациями и запишем то, что получилось в log.txt"
NUM=1
while read p; do
  echo $p $(hdfs dfs -du task_2/test_file_$NUM | awk '{print $2}' ) | awk '{print $1 " " $2 " " $4 "      " $3}' >> log.txt
  let NUM+=1
done < templog.txt

echo -e "7) и к финалу - выполним 'cat log.txt' и посмотрим, что у нас записалось в файл log.txt, там колонки такие: 1) дата, 2) время, 3) вес с репликациями и 4) содержимое:\n"
cat log.txt

echo -e "\n8) ну всё, наигрались, удаляем все файлы с локалки и hdfs\n"
rm test_file_* *log.txt 
hdfs dfs -rm -r -skipTrash task_2


# Шпаргалка. Что здесь делается:
# 1. сроздаём 3 пустых файлов файла
# 2. Записываем в каждый из них по 1 значению:
# • “Hello,” > test_file_1
# • “ hdfs” > test_file_2
# • “!” > test_file_3
# 3. Кладём файлы в домашнюю директорию в hdfs, ставим репликацию 2 и читаем по очереди, записывая аутпут в log.txt со временем и датой
# 4. Далее на hdfs перемещаем их в папку task_2
# 5. Печатаем размер кажого файла с учётом репликации, записывая аутпут в log.txt.
# 6. После чего удаляем все созданные файлы как на hdfs, так и на локальной машине.
