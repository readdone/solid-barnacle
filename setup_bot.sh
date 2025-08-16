#!/bin/bash

# Установка p7zip для работы с современными архивами
if ! command -v 7z &> /dev/null; then
    echo "Установка p7zip..."
    sudo dnf install -y p7zip p7zip-plugins
fi

# Установка Python 3.10
if ! command -v python3.10 &> /dev/null; then
    echo "Установка Python 3.10..."
    sudo dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget
    wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
    tar -xzf Python-3.10.0.tgz
    cd Python-3.10.0 || exit
    ./configure --enable-optimizations
    make -j$(nproc)
    sudo make altinstall
    cd ..
    rm -rf Python-3.10.0.tgz Python-3.10.0
fi

# Скачивание архива
echo "Скачивание tgbot.zip..."
wget https://github.com/readdone/solid-barnacle/raw/refs/heads/main/tgbot.zip -O tgbot.zip

# Проверка скачивания
if [ ! -f tgbot.zip ]; then
    echo "Ошибка: не удалось скачать архив"
    exit 1
fi

# Распаковка с помощью 7z
read -s -p "Введите пароль для архива: " password
echo
7z x -p"$password" tgbot.zip -otgbot_temp

# Проверка результата распаковки
if [ $? -ne 0 ]; then
    echo "Ошибка распаковки! Возможные причины:"
    echo "1. Неверный пароль"
    echo "2. Поврежденный архив"
    echo "3. Неподдерживаемый метод сжатия"
    rm -f tgbot.zip
    exit 1
fi

# Проверка содержимого
if [ ! -d "tgbot_temp" ]; then
    echo "Ошибка: папка не была создана"
    echo "Содержимое текущей директории:"
    ls
    rm -f tgbot.zip
    exit 1
fi

# Переименование папки (если нужно)
mv tgbot_temp tgbot 2>/dev/null || true

# Проверка целевой папки
if [ ! -d "tgbot" ]; then
    echo "Ошибка: не найдена папка с ботом"
    echo "Попробуйте вручную:"
    echo "1. unzip -P ваш_пароль tgbot.zip"
    echo "2. Или 7z x -pваш_пароль tgbot.zip"
    rm -f tgbot.zip
    exit 1
fi

# Установка зависимостей
cd tgbot || exit
sudo python3.10 -m pip install --upgrade pip
sudo python3.10 -m pip install aiogram==3.2.1

# Настройка автозапуска
cat <<EOF | sudo tee /etc/systemd/system/tgbot.service > /dev/null
[Unit]
Description=Telegram Bot
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/python3.10 $(pwd)/bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Запуск службы
sudo systemctl daemon-reload
sudo systemctl enable tgbot
sudo systemctl start tgbot

echo "Бот успешно установлен!"
echo "Для просмотра логов: journalctl -u tgbot -f"
