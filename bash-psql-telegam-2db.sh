#!/bin/bash

export PGPASSWORD=''

PROJNAME=                 # Название бэкап проекта.
PORT=6432                    # Кодировка базы данных (utf8).
DBNAME=c_cloud                # Имя базы данных для резервного копирования.
DBNAME1=keycloak                   # Имя базы данных для резервного копирования.
DBFILENAME=c_cloud                 # Имя дампа базы данных.
DBFILENAME1=keycloak                  # Имя дампа базы данных.
ARFILENAME=c_cloud                 # Имя архива с файлами.
ARFILENAME1=keycloak                # Имя архива с файлами.
HOST=                 # Хост PSQL.
USER=backup                       # Имя пользователя базы данных.
DATADIR=/mnt/backup/              #Путь к каталогу где будут храниться резервные копии.
SRCFILES=/mnt/backup/                  # Путь к каталогу файлов для архивирования.
PREFIX=`date +%F`                   # Префикс по дате для структурирования резервных копий.
KEEP_DAU=5                          #  Number of days to store the backup
# Запуск проекта:

echo "[--------------------------------[`date +%F-%H-%M`]--------------------------------]"
echo "[----------][`date +%F--%H-%M`] Запуск бэкап проекта ..."
mkdir $DATADIR/$PREFIX 2> /dev/null
echo "[++--------][`date +%F--%H-%M`] Делаем дамп базы данных..."

# Дамп PSQL
pg_dump -U $USER -h $HOST -p $PORT  $DBNAME  > $DATADIR/$PREFIX/$DBFILENAME-`date +%F--%H-%M`.sql
pg_dump -U $USER -h $HOST -p $PORT  $DBNAME1  > $DATADIR/$PREFIX/$DBFILENAME1-`date +%F--%H-%M`.sql
if [[ $? -gt 0 ]];then
echo "[++--------][`date +%F--%H-%M`] Упс, ошибка создания дампа базы данных."
exit 1
fi
echo "[++++------][`date +%F--%H-%M`] Дамп базы данных [$DBNAME] - успешно выполнен."
echo "[++++------][`date +%F--%H-%M`] Дамп базы данных [$DBNAME1] - успешно выполнен."
echo "[++++++----][`date +%F--%H-%M`] Делаю дамп [$PROJNAME]..."


# Дамп файлов

tar -czf $DATADIR/$PREFIX/$ARFILENAME-`date +%F--%H-%M`.tar.gz $DATADIR/$PREFIX/$DBFILENAME-`date +%F--%H-%M`.sql 2> /dev/null
tar -czf $DATADIR/$PREFIX/$ARFILENAME1-`date +%F--%H-%M`.tar.gz $DATADIR/$PREFIX/$DBFILENAME1-`date +%F--%H-%M`.sql 2> /dev/null
if [[ $? -gt 0 ]];then
echo "[++++++----][`date +%F--%H-%M`] Упс, ошибка при создания дампа файлов."
exit 1
fi
echo "[++++++++--][`date +%F--%H-%M`] Создание резервной копии [$PROJNAME] успешно."
echo "[+++++++++-][`date +%F--%H-%M`] Общий вес каталога: `du -h $DATADIR | tail -n1`"
echo "[+++++++++-][`date +%F--%H-%M`] Свободное место на диске: `df -h /dev/sdb1|tail -n1|awk '{print $4}'`"
echo "[+++++++++-][`date +%F--%H-%M`] Отправляю сообщение в Telegram."

# Очистка файлов

echo "[--------------------------------[`date +%F-%H-%M`]--------------------------------]"
echo "[----------][`date +%F--%H-%M`] Запуск очистки sql ..."
rm $DATADIR/$PREFIX/$DBFILENAME-`date +%F--%H-%M`.sql
rm $DATADIR/$PREFIX/$DBFILENAME1-`date +%F--%H-%M`.sql
find $DATADIR -mtime +$KEEP_DAU -delete
echo "[++--------][`date +%F--%H-%M`] Делаем очистку файлов..."


# Отправляем уведомление в Telegram

TOKEN= # Token telegram бота (получаем у @Botfather)
CHAT_ID= # ID чата куда отправлять сообщение
MESSAGE="[`date +%F-%H-%M`]%0AСоздание резервной копии [$PROJNAME] успешно.%0AСвободное место на диске: `df -h /dev/sdb1|tail -n1|awk '{print $4}'`%0AОбщий вес каталога: `du -h $DATADIR | tail -n1`"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
echo "[++++++++++][`date +%F--%H-%M`] Уведомление в Telegram отправлено."
echo "[++++++++++][`date +%F--%H-%M`] Все операции успешно выполнены."
exit 0;

