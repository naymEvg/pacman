#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Установка MTProxy ==="

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo "Запускайте с правами root (sudo)"
   exit 1
fi

PROXY_PORT=${PROXY_PORT:-8443}
STATS_PORT=${STATS_PORT:-8888}
WORKERS=${WORKERS:-1}

echo "Обновление системы..."
apt-get update -y -qq
apt-get upgrade -y -qq

echo "Установка зависимостей..."
apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev

echo "Клонирование репозитория MTProxy..."
cd /opt
if [ -d "MTProxy" ]; then
    rm -rf MTProxy
fi
git clone https://github.com/TelegramMessenger/MTProxy.git
cd MTProxy

echo "Исправление Makefile для Ubuntu 22.04..."
# Добавляем -fcommon для совместимости с GCC 10+
sed -i 's/CFLAGS\s*=\s*-O3/CFLAGS = -O3 -fcommon/' Makefile

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

cat > /etc/mtproto-proxy/config.txt <<EOF
PORT=$PROXY_PORT
SECRET=$SECRET
STATS_PORT=$STATS_PORT
WORKERS=$WORKERS
EOF

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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/cron.daily/mtproxy-update <<'EOF'
#!/bin/bash
cd /etc/mtproto-proxy
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
systemctl restart mtproxy
EOF

chmod +x /etc/cron.daily/mtproxy-update

systemctl daemon-reload
systemctl start mtproxy
systemctl enable mtproxy

sleep 3

if systemctl is-active --quiet mtproxy; then
    echo -e "${GREEN}✓ MTProxy успешно запущен!${NC}"
else
    echo "Ошибка запуска. Логи:"
    journalctl -u mtproxy -n 20 --no-pager
    exit 1
fi

SERVER_IP=$(curl -s --max-time 5 ifconfig.me || echo "<YOUR_IP>")

echo ""
echo "=========================================="
echo -e "${BLUE}MTProxy установлен и запущен!${NC}"
echo "=========================================="
echo ""
echo "Ссылка для подключения:"
echo -e "${GREEN}tg://proxy?server=$SERVER_IP&port=$PROXY_PORT&secret=$SECRET${NC}"
echo ""
echo "Альтернативная ссылка:"
echo -e "${GREEN}https://t.me/proxy?server=$SERVER_IP&port=$PROXY_PORT&secret=$SECRET${NC}"
echo ""
echo "Управление:"
echo "  systemctl status mtproxy"
echo "  systemctl restart
