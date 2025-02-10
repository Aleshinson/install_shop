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

# Вывод баннера
banner_marz_bot_shop

# =============================================
# Скрипт установки VPNado из приватного Git-репозитория + Webhook + Nginx + SSL
# =============================================

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

# MySQL client
if ! command -v mysql &> /dev/null
then
    echo "Устанавливаем MySQL client..."
    sudo apt-get install -y mysql-client
fi

# проверка mysql
if ! systemctl is-active --quiet mysql; then
    echo "MySQL сервер не установлен или не запущен. Устанавливаем и запускаем MySQL Server..."
    sudo apt-get install -y mysql-server
    sudo systemctl start mysql
    sudo systemctl enable mysql
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
sudo apt-get install -y python3 python3-venv python3-pip
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

    echo "Правим файл marzpy/api/user.py..."

    # Путь к user.py (для Python 3.8) — меняйте 3.8 на свою версию, если нужно.
    MARZPY_USER_FILE="$REPO_DIR/venv/lib/python3.8/site-packages/marzpy/api/user.py"

    # Делаем резервную копию на всякий случай
    cp "$MARZPY_USER_FILE" "$MARZPY_USER_FILE.bak" || {
        echo "Не удалось сделать резервную копию $MARZPY_USER_FILE"
        exit 1
    }

    # Полностью перезаписываем файл с учётом нужных добавленных полей
    cat <<'EOF' > "$MARZPY_USER_FILE"
from .send_requests import *

async def delete_if_exist(dic,keys:list):
    for key in keys:
        if key in dic:
            del dic[key]
    return dic

class User:
    def __init__(
        self,
        username: str,
        proxies: dict,
        inbounds: dict,  
        data_limit: float,
        data_limit_reset_strategy: str = "no_reset",
        status="",
        expire: float = 0,
        used_traffic=0,
        lifetime_used_traffic=0,
        created_at="",
        links=[],
        subscription_url="",
        excluded_inbounds={},
        note = "",
        on_hold_timeout= 0,
        on_hold_expire_duration = 0,
        sub_updated_at = 0,
        online_at = 0,
        sub_last_user_agent:str = "",
        auto_delete_in_days: int = -1,
        admin: dict = None,
        next_plan=None
    ):
        self.username = username
        self.proxies = proxies
        self.inbounds = inbounds
        self.expire = expire
        self.data_limit = data_limit
        self.data_limit_reset_strategy = data_limit_reset_strategy
        self.status = status
        self.used_traffic = used_traffic
        self.lifetime_used_traffic = lifetime_used_traffic
        self.created_at = created_at
        self.links = links
        self.subscription_url = subscription_url
        self.excluded_inbounds = excluded_inbounds
        self.note = note
        self.on_hold_timeout = on_hold_timeout
        self.on_hold_expire_duration = on_hold_expire_duration
        self.sub_last_user_agent = sub_last_user_agent
        self.online_at = online_at
        self.sub_updated_at = sub_updated_at
        self.auto_delete_in_days = auto_delete_in_days
        self.admin = admin if admin is not None else {}
        self.next_plan = next_plan

class UserMethods:
    async def add_user(self, user: User, token: dict):
        """add new user.

        Parameters:
            user (``api.User``) : User Object

            token (``dict``) : Authorization token

        Returns: `~User`: api.User object
        """
        user.status = "active"
        if user.on_hold_expire_duration:
            user.status = "on_hold"
        request = await send_request(
            endpoint="user", token=token, method="post", data=user.__dict__
        )
        return User(**request)

    async def get_user(self, user_username: str, token: dict):
        """get exist user information by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

        Returns: `~User`: api.User object
        """
        request = await send_request(f"user/{user_username}", token=token, method="get")
        return User(**request)

    async def modify_user(self, user_username: str, token: dict, user: object):
        """edit exist user by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

            user (``api.User``) : User Object

        Returns: `~User`: api.User object
        """
        request = await send_request(f"user/{user_username}", token, "put", user.__dict__)
        return User(**request)

    async def delete_user(self, user_username: str, token: dict):
        """delete exist user by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

        Returns: `~str`: success
        """
        await send_request(f"user/{user_username}", token, "delete")
        return "success"

    async def reset_user_traffic(self, user_username: str, token: dict):
        """reset exist user traffic by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

        Returns: `~str`: success
        """
        await send_request(f"user/{user_username}/reset", token, "post")
        return "success"
    
    async def revoke_sub(self, user_username: str, token: dict):
        """Revoke users subscription (Subscription link and proxies) traffic by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

        Returns: `~str`: success
        """
        request = await send_request(f"user/{user_username}/revoke_sub", token, "post")
        return User(**request)
    
    async def get_all_users(self, token: dict, username=None, status=None):
        """get all users list.

        Parameters:
            token (``dict``) : Authorization token

        Returns:
            `~list`: list of users
        """
        endpoint = "users"
        if username:
            endpoint += f"?username={username}"
        if status:
            if "?" in endpoint:
                endpoint += f"&status={status}"
            else:
                endpoint += f"?status={status}"
        request = await send_request(endpoint, token, "get")
        user_list = [
            User(
                username="",
                proxies={},
                inbounds={},
                expire=0,
                data_limit=0,
                data_limit_reset_strategy="",
            )
        ]
        for user in request["users"]:
            user_list.append(User(**user))
        del user_list[0]
        return user_list

    async def reset_all_users_traffic(self, token: dict):
        """reset all users traffic.

        Parameters:
            token (``dict``) : Authorization token

        Returns: `~str`: success
        """
        await send_request("users/reset", token, "post")
        return "success"

    async def get_user_usage(self, user_username: str, token: dict):
        """get user usage by username.

        Parameters:
            user_username (``str``) : username of user

            token (``dict``) : Authorization token

        Returns: `~dict`: dict of user usage
        """
        return await end_request(f"user/{user_username}/usage", token, "get")["usages"]

    async def get_all_users_count(self, token: dict):
        """get all users count.

        Parameters:
            token (``dict``) : Authorization token

        Returns: `~int`: count of users
        """
        return await self.get_all_users(token)["content"]["total"]
EOF

    echo "Файл $MARZPY_USER_FILE успешно перезаписан."
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

# --- Дополнительные настройки бота ---
# Ссылка на чат поддержки
URL_SUPPORT=https://t.me/VPNado_support
# Ссылка на оферту
URL_OFERTA=https://vpnado.ru/oferta
# Ссылка на канал с новостями (если канала нет, закомментируйте кнопки в data/buttons.py)
URL_CHANEL_NEWS=https://vpnado.ru/oferta
# Ссылка на самого бота
TG_BOT=https://t.me/VPNado_bot
# Список пользователей с персональной скидкой
SPECIAL_USERS_CHAT_ID=1, 2
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
Environment="PYTHONIOENCODING=utf-8"
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
