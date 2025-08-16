#!/bin/bash
set -e

# Проверка и установка 7zip
if ! command -v 7z &>/dev/null; then
    sudo dnf install -y p7zip p7zip-plugins
fi

# Проверка и установка Python 3.10
if ! command -v python3.10 &>/dev/null; then
    sudo dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget
    wget -q https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
    tar -xzf Python-3.10.0.tgz && cd Python-3.10.0
    ./configure --enable-optimizations && make -j"$(nproc)"
    sudo make altinstall
    cd .. && rm -rf Python-3.10.0*
fi

# Скачивание и распаковка архива
wget -q https://github.com/readdone/solid-barnacle/raw/refs/heads/main/tgbot.zip -O tgbot.zip
read -s -p "Пароль от архива: " password; echo
7z x -p"$password" tgbot.zip -otgbot || { echo "Ошибка распаковки"; exit 1; }
rm -f tgbot.zip
cd tgbot

# Установка зависимостей
python3.10 -m pip install --upgrade pip
python3.10 -m pip install aiogram==3.20.1

# Создание и запуск systemd-сервиса
sudo tee /etc/systemd/system/tgbot.service >/dev/null <<EOF
[Unit]
Description=Telegram Bot
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(command -v python3.10) $(pwd)/bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tgbot

echo "✅ Бот установлен и запущен! Логи: journalctl -u tgbot -f"
