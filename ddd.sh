#!/bin/bash
set -e

# ==============================
# Скачивание архива
# ==============================
ARCHIVE_URL="https://github.com/readdone/solid-barnacle/raw/refs/heads/main/tgbot.zip"
ARCHIVE_NAME="tgbot.zip"
DEST_DIR="tgbot"

if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📦 Скачиваю tgbot.zip..."
    wget -q "$ARCHIVE_URL" -O "$ARCHIVE_NAME"
fi

# ==============================
# Ввод пароля и распаковка архива через Python
# ==============================
read -s -p "Введите пароль для архива: " PASSWORD
echo

mkdir -p "$DEST_DIR"

# ==============================
cd "$DEST_DIR"

if [ -f requirements.txt ]; then
    echo "📦 Устанавливаю зависимости из requirements.txt..."
    python3 -m pip install --upgrade pip
    python3 -m pip install -r requirements.txt
fi

# ==============================
# Настройка systemd
# ==============================
SERVICE_NAME="tgbot"
if [ ! -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "⚙️ Создаю службу systemd..."
    sudo tee /etc/systemd/system/$SERVICE_NAME.service >/dev/null <<EOF
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
    sudo systemctl enable --now $SERVICE_NAME
else
    echo "ℹ️ Служба systemd уже существует. Просто перезапустим её."
    sudo systemctl restart $SERVICE_NAME
fi

echo "✅ Бот установлен и запущен!"
echo "➡️ Логи: journalctl -u $SERVICE_NAME -f"
