#!/bin/bash

# Скрипт установки официального MTProxy для Telegram
# Работает на Ubuntu/Debian

set -e

# Отключение интерактивных запросов
export DEBIAN_FRONTEND=noninteractive

echo "=== Установка MTProxy ==="

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт нужно запускать с правами root (sudo)"
   exit 1
fi

# Настройки (можно изменить через переменные окружения)
PROXY_PORT=${PROXY_PORT:-8443}
STATS_PORT=${STATS_PORT:-8888}
WORKERS=${WORKERS:-1}

echo "Обновление системы..."
apt-get update -y -qq
apt-get upgrade -y -qq

echo "Установка зависимостей..."
apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev

echo "Клонирование официального репозитория MTProxy..."
cd /opt
if [ -d "MTProxy" ]; then
    echo "Удаление старой версии..."
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

# Сохранение конфигурации
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

echo "Настройка автообновления конфигурации..."
cat > /etc/cron.daily/mtproxy-update <<'EOF'
#!/bin/bash
cd /etc/mtproto-proxy
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
systemctl restart mtproxy
EOF

chmod +x /etc/cron.daily/mtproxy-update

echo "Перезагрузка systemd..."
systemctl daemon-reload

echo "Запуск MTProxy..."
systemctl start mtproxy
systemctl enable mtproxy

# Ждем запуска
sleep 3

echo "Проверка статуса..."
if systemctl is-active --quiet mtproxy; then
    echo -e "${GREEN}✓ MTProxy успешно запущен!${NC}"
else
    echo -e "${YELLOW}⚠ Возможная ошибка запуска. Проверьте логи: journalctl -u mtproxy -n 50${NC}"
    journalctl -u mtproxy -n 20 --no-pager
    exit 1
fi

# Получаем IP сервера
echo "Определение внешнего IP..."
SERVER_IP=$(curl -s --max-time 5 ifconfig.me || curl -s --max-time 5 icanhazip.com || curl -s --max-time 5 api.ipify.org)

if [ -z "$SERVER_IP" ]; then
    SERVER_IP="<YOUR_SERVER_IP>"
    echo -e "${YELLOW}⚠ Не удалось автоматически определить IP. Замените <YOUR_SERVER_IP> на реальный IP сервера.${NC}"
fi

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
echo "Альтернативная ссылка (t.me):"
echo -e "${GREEN}https://t.me/proxy?server=$SERVER_IP&port=$PROXY_PORT&secret=$SECRET${NC}"
echo ""
echo "Управление сервисом:"
echo "  Статус:      systemctl status mtproxy"
echo "  Остановить:  systemctl stop mtproxy"
echo "  Запустить:   systemctl start mtproxy"
echo "  Рестарт:     systemctl restart mtproxy"
echo "  Логи:        journalctl -u mtproxy -f"
echo "  Статистика:  curl localhost:$STATS_PORT/stats"
echo ""
echo "Конфигурация сохранена в: /etc/mtproto-proxy/config.txt"
echo "Автообновление серверов Telegram: ежедневно через cron"
echo ""
