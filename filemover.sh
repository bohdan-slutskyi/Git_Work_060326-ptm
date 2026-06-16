#!/bin/bash

#1. Запрос исходной и целевой директории у пользователя

read -p "Введите исходную директорию: " source_directory
echo "Исходная директория: $source_directory"

read -p "Введите целевую директорию: " target_directory
echo "Целевая директория: $target_directory"

#2. Проверка существования исходной директории и целевой директории

if [ ! -d "$source_directory" ]
then
    echo "Ошибка: исходная директория не существует!"
    exit 1
fi

if [ ! -r "$source_directory" ] || [ ! -x "$source_directory" ]
then
    echo "Ошибка: исходная директория недоступна!"
    exit 1
fi

if [ ! -d "$target_directory" ]
then
    mkdir -p "$target_directory"
fi

if [ ! -w "$target_directory" ] || [ ! -x "$target_directory" ]
then
    echo "Ошибка: целевая директория недоступна!"
    exit 1
fi


#3. Запрос расширения файлов, которые нужно скопировать

read -p "Request file extension to copy: " file_extension
#echo $file_extension

#4. Запросить новое расширение для файлов.

read -p "Enter new file extension: "  new_file_extension

echo "You chose: $new_file_extension"

#5. Проверка, есть ли файлы с указанным расширением в исходной директории
files=$(find "$source_directory" -type f -name "*.$file_extension")
if [ -z "$files" ]; then
	echo "Ошибка, в дериктории '$source_directory' с расширением  '.$file_extension' не найдено."
	exit 1
fi

#6. Копирование файлов с указанным расширением в целевую директорию
#for file in "$source_directory"/*."$file_extension"
#do
#  echo $(basename "${file%.*}")
#  cp "$file" "$target_directory"/$(basename "${file%.*}")."$new_file_extension"
#  echo "Файл $(basename "$file") скопирован как $(basename "${file%.*}")."$new_file_extension""
#done

for file in "$source_directory"/*."$file_extension"; do
    filename_without_extension=$(basename "${file%.*}")

    cp "$file" "$target_directory/$filename_without_extension.$new_file_extension"
    echo "Скопирован файл: $file -> $filename_without_extension.$new_file_extension"
done

#7. Архивация исходных файлов.

echo -e "\n=== Шаг 7: Архивирование и очистка ==="

# Текущая дата в формате YYYY-MM-DD
current_date=$(date +%Y-%m-%d)
archive_name="old_files_${current_date}.tar.gz"
archive_path="${target_directory}/${archive_name}"

# Путь к файлу лога в целевой директории
log_file="${target_directory}/archive_process_${current_date}.log"

# Записываем в лог заголовок и начало процесса
echo "[$(date '+%Y-%m-%d %H:%M:%S')] НАЧАЛО ПРОЦЕССА АРХИВАЦИИ" >> "$log_file"
echo "Исходная директория: $source_directory" >> "$log_file"
echo "Целевая директория: $target_directory" >> "$log_file"
echo "Расширение файлов: *.$file_extension" >> "$log_file"
echo "Список файлов для архивации:" >> "$log_file"

# Записываем имена архивируемых файлов в лог для отчетности
find "$source_directory" -maxdepth 1 -type f -name "*.${file_extension}" -exec basename {} \; >> "$log_file"

echo "Создание архива исходных файлов..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Запуск tar..." >> "$log_file"

# Архивируем файлы. Флаг -C позволяет перейти в папку и упаковать файлы без сохранения абсолютных путей
find "$source_directory" -maxdepth 1 -type f -name "*.${file_extension}" -exec basename {} \; | \
    tar -czf "$archive_path" -C "$source_directory" -T - 2>> "$log_file"

if [ $? -eq 0 ]; then
    echo "Архив '$archive_name' успешно создан в целевой директории."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] УСПЕХ: Архив $archive_name успешно создан." >> "$log_file"
    
    echo "Удаление исходных файлов с расширением *.${file_extension} из исходной директории..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Удаление исходных файлов..." >> "$log_file"
    
    # Удаляем и пишем статус в лог
    find "$source_directory" -maxdepth 1 -type f -name "*.${file_extension}" -delete 2>> "$log_file"
    
    echo "Исходные файлы удалены."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ЗАВЕРШЕНО: Файлы удалены из исходной директории." >> "$log_file"
else
    echo "Ошибка при создании архива! Исходные файлы не будут удалены."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА: Не удалось создать архив. Удаление файлов отменено." >> "$log_file"
    exit 1
fi

echo "Лог-файл сохранен по пути: $log_file"
