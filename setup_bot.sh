#!/bin/bash

# Установка 7z (для распаковки архивов)
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

# Распаковка с паролем
read -s -p "Введите пароль для архива: " password
echo
7z x -p"$password" tgbot.zip -otgbot
if [ $? -ne 0 ]; then
    echo "Ошибка распаковки! Проверьте пароль и целостность архива."
    rm -f tgbot.zip
    exit 1
fi
rm -f tgbot.zip

# Проверка папки tgbot
if [ ! -d "tgbot" ]; then
    echo "Ошибка: папка tgbot не найдена после распаковки"
    ls
    exit 1
fi

# Переход в папку с ботом
cd tgbot || exit

# Установка aiogram 3.2.1 и зависимостей
sudo python3.10 -m pip install --upgrade pip
sudo python3.10 -m pip install aiogram==3.2.1

# Настройка автозапуска через systemd
echo "Создание службы systemd..."
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

echo "Бот установлен и запущен. Для просмотра логов: journalctl -u tgbot -f"
