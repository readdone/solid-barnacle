#!/bin/bash

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
