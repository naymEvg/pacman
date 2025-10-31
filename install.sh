#!/bin/bash

# Скрипт установки официального MTProxy для Telegram
# Работает на Ubuntu/Debian

set -e

echo "=== Установка MTProxy ==="

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт нужно запускать с правами root (sudo)"
   exit 1
fi

# Настройки (можно изменить)
PROXY_PORT=${PROXY_PORT:-8443}
STATS_PORT=${STATS_PORT:-8888}
WORKERS=${WORKERS:-1}

echo "Обновление системы..."
apt-get update
apt-get upgrade -y

echo "Установка зависимостей..."
apt-get install -y git curl build-essential libssl-dev zlib1g-dev

echo "Клонирование официального репозитория MTProxy..."
cd /opt
if [ -d "MTProxy" ]; then
    rm -rf MTProxy
fi
git clone https://github.com/TelegramMessenger/MTProxy.git
cd MTProxy

echo "Компиляция MTProxy..."
make clean 2>/dev/null || true
make

echo "Установка бинарного файла..."
cp objs/bin/mtproto-proxy /usr/bin/
chmod 755 /usr/bin/mtproto-proxy

echo "Создание директории конфигурации..."
mkdir -p /etc/mtproto-proxy
cd /etc/mtproto-proxy

echo "Загрузка конфигурационных файлов Telegram..."
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

echo "Генерация секретного ключа..."
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "Ваш секрет: $SECRET"

echo "Создание systemd service..."
cat > /etc/systemd/system/mtproxy.service <<EOF
[Unit]
Description=MTProxy Telegram Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/mtproto-proxy
ExecStart=/usr/bin/mtproto-proxy -u nobody -p $STATS_PORT -H $PROXY_PORT -S $SECRET --aes-pwd proxy-secret proxy-multi.conf -M $WORKERS
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Перезагрузка systemd..."
systemctl daemon-reload

echo "Запуск MTProxy..."
systemctl start mtproxy
systemctl enable mtproxy

# Ждем запуска
sleep 2

echo "Проверка статуса..."
if systemctl is-active --quiet mtproxy; then
    echo -e "${GREEN}✓ MTProxy успешно запущен!${NC}"
else
    echo "Ошибка запуска. Проверьте логи: journalctl -u mtproxy -n 50"
    exit 1
fi

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo ""
echo "=========================================="
echo -e "${BLUE}MTProxy установлен и запущен!${NC}"
echo "=========================================="
echo ""
echo "Параметры подключения:"
echo "  IP: $SERVER_IP"
echo "  Порт: $PROXY_PORT"
echo "  Секрет: $SECRET"
echo ""
echo "Ссылка для подключения:"
echo -e "${GREEN}tg://proxy?server=$SERVER_IP&port=$PROXY_PORT&secret=$SECRET${NC}"
echo ""
echo "Управление сервисом:"
echo "  Статус:      systemctl status mtproxy"
echo "  Остановить:  systemctl stop mtproxy"
echo "  Запустить:   systemctl start mtproxy"
echo "  Рестарт:     systemctl restart mtproxy"
echo "  Логи:        journalctl -u mtproxy -f"
echo "  Статистика:  curl localhost:$STATS_PORT/stats"
echo ""
