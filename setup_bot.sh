#!/bin/bash

# Установка Python 3.10 на CentOS 9 Stream
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

# Запрос пароля для распаковки
read -s -p "Введите пароль для архива: " password
echo
unzip -P "$password" tgbot.zip
rm tgbot.zip  # Удаление архива после распаковки

# Переход в папку с ботом
cd tgbot || { echo "Ошибка: папка tgbot не найдена"; exit 1; }

# Создание виртуального окружения и установка aiogram
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install aiogram==3.21.0

# Настройка автозапуска через systemd
echo "Создание службы systemd..."
cat <<EOF | sudo tee /etc/systemd/system/tgbot.service > /dev/null
[Unit]
Description=Telegram Bot
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/venv/bin/python3.10 $(pwd)/bot.py
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
