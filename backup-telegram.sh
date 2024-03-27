#!/bin/bash

export PGPASSWORD=""

PROJNAME=stopus                     # Название бэкап проекта.
PORT=                          # Кодировка базы данных (utf8).
ARFILENAME=stopus                   # Имя архива с файлами.
HOST=                  # Хост PSQL.
USER=postgres                       # Имя пользователя базы данных.
DATADIR=/mnt/backup/                # Путь к каталогу где будут храниться резервные копии.
SRCFILES=/mnt/backup/               # Путь к каталогу файлов для архивирования.
PREFIX=`date +%F`                   # Префикс по дате для структурирования резервных копий.
KEEP_DAU=5                          # Number of days to store the backup
OLD=*   

# Запуск проекта:

echo "[--------------------------------[`date +%F-%H-%M`]--------------------------------]"
echo "[----------][`date +%F--%H-%M`] Запуск бэкап проекта ..."
mkdir $DATADIR/$PREFIX 2> /dev/null
echo "[++--------][`date +%F--%H-%M`] Делаем дамп базы данных..."

# Дамп PSQL
DBLIST=`sudo -u postgres psql -Upostgres -lt | grep -v : | cut -d \| -f 1 | grep -v template | grep -v -e '^\s*$' | sed -e 's/  *$//'|  tr '\n' ' '`
for d in $DBLIST
do
  echo "Dumping $d";
  pg_dump -U $USER -h $HOST -p $PORT $d > $DATADIR/$PREFIX/$d.`date +%F--%H-%M`.sql
done
if [[ $? -gt 0 ]];then
echo "[++--------][`date +%F--%H-%M`] Упс, ошибка создания дампа базы данных."
exit 1
fi
echo "[++++------][`date +%F--%H-%M`] Дамп базы данных [$d] - успешно выполнен."
echo "[++++++----][`date +%F--%H-%M`] Делаю дамп [$PROJNAME]..."


# Дамп файлов

tar -czf $DATADIR/$PREFIX/$ARFILENAME-`date +%F--%H-%M`.tar.gz $DATADIR/$PREFIX/*.sql 2> /dev/null
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
rm $DATADIR/$PREFIX/$OLD.sql
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
