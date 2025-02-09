#!/bin/bash

# ------------------------------------------------
# Функция для отображения баннера
# ------------------------------------------------
banner_marz_bot_shop() {
    echo
    echo "███╗   ███╗ █████╗ ██████╗ ███████╗     ██████╗  ██████╗ ████████╗   ███████╗██╗  ██╗ ██████╗ ██████╗ "
    echo "████╗ ████║██╔══██╗██╔══██╗╚══███╔╝     ██╔══██╗██╔═══██╗╚══██╔══╝   ██╔════╝██║  ██║██╔═══██╗██╔══██╗"
    echo "██╔████╔██║███████║██████╔╝  ███╔╝█████╗██████╔╝██║   ██║   ██║█████╗███████╗███████║██║   ██║██████╔╝"
    echo "██║╚██╔╝██║██╔══██║██╔══██╗ ███╔╝ ╚════╝██╔══██╗██║   ██║   ██║╚════╝╚════██║██╔══██║██║   ██║██╔═══╝ "
    echo "██║ ╚═╝ ██║██║  ██║██║  ██║███████╗     ██████╔╝╚██████╔╝   ██║      ███████║██║  ██║╚██████╔╝██║     "
    echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝     ╚═════╝  ╚═════╝    ╚═╝      ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     "
    echo
    echo
}

# Очистка экрана
clear

# Вывод баннера
banner_marz_bot_shop

# =============================================
# Скрипт установки VPNado из приватного Git-репозитория + Webhook + Nginx + SSL
# =============================================

clear
echo "======================================="
echo "         VPNado Installer"
echo "======================================="
echo

# -------------------------------
# 0. Подготовка: установка зависимостей
# -------------------------------
sudo apt-get update

# git
if ! command -v git &> /dev/null
then
    echo "Устанавливаем git..."
    sudo apt-get install -y git
fi

# Python3 + venv
if ! command -v python3 &> /dev/null
then
    echo "Устанавливаем python3, python3-venv, python3-pip..."
    sudo apt-get install -y python3 python3-venv python3-pip
else
    if ! python3 -m venv --help &> /dev/null
    then
        echo "Устанавливаем python3-venv..."
        sudo apt-get install -y python3-venv
    fi
fi

# MySQL client
if ! command -v mysql &> /dev/null
then
    echo "Устанавливаем MySQL client..."
    sudo apt-get install -y mysql-client
fi

# -------------------------------
# 1. Запрос GitHub Personal Access Token
# -------------------------------
echo "Для клонирования приватного репозитория требуется GitHub Personal Access Token (classic)."
read -p "Введите GITHUB_TOKEN: " GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Ошибка: Вы не ввели токен. Скрипт не может продолжить."
  exit 1
fi

# URL приватного репозитория
REPO_URL="https://${GITHUB_TOKEN}@github.com/Aleshinson/VPNado.git"
REPO_DIR="/home/VPNado"

# -------------------------------
# 2. Клонирование/обновление репозитория
# -------------------------------
if [ -d "$REPO_DIR" ]; then
    echo "Директория $REPO_DIR уже существует. Обновляем репозиторий..."
    cd "$REPO_DIR" || { echo "Не удалось перейти в $REPO_DIR"; exit 1; }
    git pull || { echo "Ошибка обновления репозитория"; exit 1; }
else
    echo "Клонирование репозитория из $REPO_URL в $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR" || { echo "Ошибка клонирования репозитория"; exit 1; }
    cd "$REPO_DIR" || { echo "Не удалось перейти в $REPO_DIR"; exit 1; }
fi

# -------------------------------
# 3. Создание директории для конфигураций
# -------------------------------
CONFIGS_DIR="$REPO_DIR/configs"
mkdir -p "$CONFIGS_DIR"
ENV_FILE="$CONFIGS_DIR/.env"

echo "Файл конфигурации .env будет создан по пути: $ENV_FILE"
echo

# -------------------------------
# 4. Запрос переменных для бота
# -------------------------------
read -p "Введите BOT_TOKEN: " BOT_TOKEN

# Настройка YooKassa
read -p "Вы хотите принимать платежи через YooKassa? (y/n): " yookassa_choice
if [[ "$yookassa_choice" =~ ^[Yy]$ ]]; then
    ENABLE_YOOKASSA=True
    read -p "Введите YOOKASSA_SHOP_ID: " YOOKASSA_SHOP_ID
    read -p "Введите YOOKASSA_SECRET_KEY: " YOOKASSA_SECRET_KEY
    read -p "Введите EMAIL: " EMAIL
else
    ENABLE_YOOKASSA=False
    YOOKASSA_SHOP_ID=""
    YOOKASSA_SECRET_KEY=""
    EMAIL=""
fi

# Настройка приема оплаты звездами
read -p "Вы хотите принимать оплату звездами? (y/n): " stars_choice
if [[ "$stars_choice" =~ ^[Yy]$ ]]; then
    ENABLE_STARS=True
else
    ENABLE_STARS=False
fi

# Данные для Marzban
read -p "Введите MARZBAN_USERNAME: " MARZBAN_USERNAME
read -p "Введите MARZBAN_PASSWORD: " MARZBAN_PASSWORD
read -p "Введите MARZBAN_URL: " MARZBAN_URL

# Телеграм ID админа
read -p "Введите Telegram ID админа: " OWNER_ID_KEY

# -------------------------------
# 5. Настройка и создание MySQL базы/пользователя/таблиц
# -------------------------------
echo
echo "=== Настройки базы данных ==="
read -p "Введите MySQL host (по умолчанию localhost): " DB_HOST
DB_HOST="${DB_HOST:-localhost}"

read -p "Введите MySQL порт (по умолчанию 3306): " DB_PORT
DB_PORT="${DB_PORT:-3306}"

# root-доступ в MySQL (для создания базы и пользователя)
read -p "Введите MySQL root-пользователя (по умолчанию root): " MYSQL_ROOT_USER
MYSQL_ROOT_USER="${MYSQL_ROOT_USER:-root}"

echo -n "Введите пароль MySQL для пользователя $MYSQL_ROOT_USER (может быть пустым): "
read -s MYSQL_ROOT_PASSWORD
echo

# Данные для новой базы и пользователя
read -p "Введите название новой базы данных: " DB_NAME
read -p "Введите имя нового пользователя БД: " DBUSER_NAME
echo -n "Введите пароль для пользователя $DBUSER_NAME: "
read -s DBUSER_PASSWORD
echo

echo
echo "Создаём базу данных '$DB_NAME', пользователя '$DBUSER_NAME' и необходимые таблицы..."

mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS '$DBUSER_NAME'@'%' IDENTIFIED BY '$DBUSER_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DBUSER_NAME'@'%';
FLUSH PRIVILEGES;

USE \`$DB_NAME\`;

-- Таблица users
CREATE TABLE IF NOT EXISTS users (
  username varchar(255) DEFAULT NULL,
  chat_id bigint NOT NULL,
  PRIMARY KEY (chat_id),
  UNIQUE KEY chat_id (chat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Таблица payments
CREATE TABLE IF NOT EXISTS payments (
  chat_id bigint DEFAULT NULL,
  username varchar(255) DEFAULT NULL,
  id_pay varchar(255) DEFAULT NULL,
  amount varchar(255) DEFAULT NULL,
  pay_method varchar(255) DEFAULT NULL,
  status varchar(255) DEFAULT NULL,
  pay_date datetime DEFAULT NULL,
  KEY chat_id (chat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Таблица referral
CREATE TABLE IF NOT EXISTS referral (
  chat_id bigint NOT NULL,
  referral_code text,
  referral_link text,
  referral_source_code text,
  paid_count int DEFAULT 0,
  trial_count int DEFAULT 0,
  paid_use int DEFAULT 0,
  trial_use int DEFAULT 0,
  PRIMARY KEY (chat_id),
  CONSTRAINT referral_ibfk_1 FOREIGN KEY (chat_id) REFERENCES users (chat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Таблица subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
  chat_id bigint NOT NULL,
  subscription_date date DEFAULT NULL,
  expiry_date date DEFAULT NULL,
  is_notified tinyint DEFAULT NULL,
  PRIMARY KEY (chat_id),
  CONSTRAINT subscriptions_ibfk_1 FOREIGN KEY (chat_id) REFERENCES users (chat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
EOF

if [ $? -ne 0 ]; then
  echo "Ошибка при создании базы данных или таблиц!"
  exit 1
fi

echo "База данных '$DB_NAME' и таблицы успешно созданы."
echo

# -------------------------------
# 6. Создание и настройка виртуального окружения Python для бота
# -------------------------------
echo "Создаём виртуальное окружение Python в $REPO_DIR/venv..."
python3 -m venv "$REPO_DIR/venv"

if [ ! -d "$REPO_DIR/venv" ]; then
  echo "Ошибка: не удалось создать виртуальное окружение."
  exit 1
fi

# Активируем окружение и устанавливаем зависимости
source "$REPO_DIR/venv/bin/activate"

if [ -f "$REPO_DIR/requirements.txt" ]; then
    echo "Устанавливаем зависимости из requirements.txt..."
    pip install --upgrade pip
    pip install -r "$REPO_DIR/requirements.txt"
fi

deactivate

# -------------------------------
# 7. Запись ВСЕХ переменных в файл .env
# -------------------------------
cat <<EOF > "$ENV_FILE"
BOT_TOKEN=$BOT_TOKEN
YOOKASSA_SHOP_ID=$YOOKASSA_SHOP_ID
YOOKASSA_SECRET_KEY=$YOOKASSA_SECRET_KEY
EMAIL=$EMAIL

MARZBAN_USERNAME=$MARZBAN_USERNAME
MARZBAN_PASSWORD=$MARZBAN_PASSWORD
MARZBAN_URL=$MARZBAN_URL

OWNER_ID_KEY=$OWNER_ID_KEY

DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DBUSER_NAME
DB_PASSWORD=$DBUSER_PASSWORD

ENABLE_YOOKASSA=$ENABLE_YOOKASSA
ENABLE_STARS=$ENABLE_STARS
EOF

# -------------------------------
# 8. Создание systemd-сервиса для бота (vpnadobot)
# -------------------------------
SERVICE_FILE="/etc/systemd/system/vpnadobot.service"
echo "Создаём systemd unit-файл $SERVICE_FILE..."

cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=VPNado bot
After=syslog.target
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$REPO_DIR
Environment="PYTHONPATH=$REPO_DIR/venv/lib/python3.8/site-packages"
ExecStart=$REPO_DIR/venv/bin/python3 $REPO_DIR/main.py
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vpnadobot.service
sudo systemctl start vpnadobot.service

echo
echo "Systemd-сервис vpnadobot.service создан и запущен."
echo "Проверка статуса: sudo systemctl status vpnadobot.service"
echo

# -------------------------------
# 9. Создание systemd-сервиса для вебхука (webhook.service)
# -------------------------------
echo "Теперь настроим webhook.service (Flask-приложение)."
echo
echo "Убедитесь, что у вас есть рабочий каталог и virtualenv для webhook: /home/vpn/fapi-venv"
echo "  - файл webhook.py внутри /home/vpn/fapi-venv/"
echo "  - python3 в /home/vpn/fapi-venv/bin/python3"
echo
read -p "Продолжить создание webhook.service? (y/n): " webhook_choice

if [[ "$webhook_choice" =~ ^[Yy]$ ]]; then
    WEBHOOK_SERVICE="/etc/systemd/system/webhook.service"
    echo "Создаём systemd unit-файл $WEBHOOK_SERVICE..."

    cat <<EOF | sudo tee "$WEBHOOK_SERVICE" > /dev/null
[Unit]
Description=My Flask Webhook Service
After=network.target

[Service]
User=root
WorkingDirectory=/home/vpn/fapi-venv
ExecStart=/home/vpn/fapi-venv/bin/python3 /home/vpn/fapi-venv/webhook.py
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable webhook.service
    sudo systemctl start webhook.service

    echo
    echo "Systemd-сервис webhook.service создан и запущен."
    echo "Проверка статуса: sudo systemctl status webhook.service"
    echo
else
    echo "Пропускаем создание webhook.service."
fi

# -------------------------------
# 10. Настройка Nginx (опционально)
# -------------------------------
echo "Настроим Nginx для обратного проксирования и (по желанию) получим SSL-сертификат."
read -p "Установить и настроить Nginx? (y/n): " nginx_choice

if [[ "$nginx_choice" =~ ^[Yy]$ ]]; then
    # Установим Nginx, если не установлен
    if ! command -v nginx &> /dev/null
    then
        echo "Устанавливаем Nginx..."
        sudo apt-get install -y nginx
    fi
    
    # Запросим домен
    echo
    read -p "Введите ваш домен (например: vpnado.ru): " SERVER_DOMAIN
    if [ -z "$SERVER_DOMAIN" ]; then
      echo "Домен не указан, пропускаем настройку Nginx."
    else
      # Создадим конфиг Nginx
      NGINX_CONF="/etc/nginx/sites-available/${SERVER_DOMAIN}.conf"
      
      cat <<EOF | sudo tee "$NGINX_CONF" > /dev/null
server {
    root /var/www/${SERVER_DOMAIN}/html;
    index index.html index.htm index.nginx-debian.html;
    server_name ${SERVER_DOMAIN} www.${SERVER_DOMAIN};

    # Пример проксирования /webhook_yookassa -> 127.0.0.1:6000
    location /webhook_yookassa {
        proxy_pass http://127.0.0.1:6000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Пример проксирования /oferta -> 127.0.0.1:7000
    location /oferta {
        proxy_pass http://127.0.0.1:7000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 80;
    listen [::]:80;
}
EOF

      # Создадим директорию для /var/www/домен
      sudo mkdir -p /var/www/${SERVER_DOMAIN}/html
      echo "<h1>Hello from $SERVER_DOMAIN</h1>" | sudo tee /var/www/${SERVER_DOMAIN}/html/index.html

      # Включим конфиг
      sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/"
      sudo nginx -t && sudo systemctl reload nginx

      echo
      echo "Nginx сконфигурирован для домена ${SERVER_DOMAIN} (HTTP)."
      echo "Проверяем: http://${SERVER_DOMAIN}/"

      # Установка SSL (Certbot)
      read -p "Получить SSL-сертификат для домена ${SERVER_DOMAIN} через Certbot? (y/n): " ssl_choice
      if [[ "$ssl_choice" =~ ^[Yy]$ ]]; then
         if ! command -v certbot &> /dev/null
         then
             echo "Устанавливаем certbot и python3-certbot-nginx..."
             sudo apt-get install -y certbot python3-certbot-nginx
         fi

         echo "Запускаем certbot для ${SERVER_DOMAIN} и www.${SERVER_DOMAIN}..."
         sudo certbot --nginx -d "${SERVER_DOMAIN}" -d "www.${SERVER_DOMAIN}" --non-interactive --agree-tos -m "admin@${SERVER_DOMAIN}"

         if [ $? -eq 0 ]; then
           echo "SSL успешно настроен. Проверьте https://${SERVER_DOMAIN}/"
         else
           echo "Ошибка получения SSL-сертификата. Проверьте логи certbot."
         fi
      else
         echo "Пропускаем настройку SSL."
      fi
    fi
else
    echo "Пропускаем установку и настройку Nginx."
fi

echo
echo "Все шаги установки завершены!"
echo
echo "Параметры сохранены в $ENV_FILE"
echo "Репозиторий: $REPO_DIR"
echo
echo "VPNado Bot запущен как vpnadobot.service."
[ "$webhook_choice" = "y" ] && echo "Webhook запущен как webhook.service."
echo
echo "Установка завершена. Приятной работы!"
