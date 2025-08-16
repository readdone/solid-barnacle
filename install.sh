#!/bin/bash
set -e

# ==============================
# Установка архиватора p7zip
# ==============================
if ! command -v 7z &>/dev/null; then
    echo "🔧 Устанавливаю p7zip..."
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --set-enabled crb
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sudo dnf install -y p7zip p7zip-plugins
fi

# ==============================
# Установка Python 3.10
# ==============================
if ! command -v python3.10 &>/dev/null; then
    echo "🔧 Устанавливаю Python 3.10..."
    sudo dnf install -y gcc make wget \
        openssl-devel bzip2-devel libffi-devel zlib-devel
    wget -q https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
    tar -xzf Python-3.10.0.tgz && cd Python-3.10.0
    ./configure --enable-optimizations
    make -j"$(nproc)"
    sudo make altinstall
    cd .. && rm -rf Python-3.10.0*
fi

# ==============================
# Скачивание и распаковка архива бота
# ==============================
echo "📦 Скачиваю tgbot.zip..."
wget -q https://github.com/readdone/solid-barnacle/raw/refs/heads/main/tgbot.zip -O tgbot.zip

read -s -p "Введите пароль для архива: " password; echo

# Создаем папку tgbot для распаковки
mkdir -p tgbot
7z x -p"$password" tgbot.zip -otgbot || { echo "❌ Ошибка распаковки"; exit 1; }
rm -f tgbot.zip

# Переходим в папку tgbot
cd tgbot || { echo "❌ Папка tgbot не найдена после распаковки"; exit 1; }

# ==============================
# Установка зависимостей Python из requirements.txt
# ==============================
echo "📦 Устанавливаю зависимости..."
python3.10 -m pip install --upgrade pip
if [ -f requirements.txt ]; then
    python3.10 -m pip install -r requirements.txt
else
    echo "⚠️ Файл requirements.txt не найден. Устанавливаю aiogram по умолчанию."
    python3.10 -m pip install aiogram==3.20.1
fi

# ==============================
# Настройка systemd-сервиса
# ==============================
echo "⚙️ Создаю службу systemd..."
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

echo "✅ Бот установлен и запущен!"
echo "➡️ Логи: journalctl -u tgbot -f"
