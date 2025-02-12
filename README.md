# Установка и настройка скрипта

## 1. Получите ключ у автора

Для установки скрипта необходимо получить RSA-ключ у автора и добавить его в соответствующую директорию.

### Директория:
```bash
 ~/.ssh/deploy_key
```

### Установка прав доступа:
```bash
chmod 600 ~/.ssh/deploy_key
```

---

## 2. Запуск установочного скрипта

Чтобы установить marz-bot-shop, используйте команду:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/Aleshinson/install_shop/main/install.sh)
```

## 3. Файл .env

#### После установки все настройки сохраняются в файле:
```bash
sudo nano /home/VPNado/configs/.env
```
### Описание переменных:

| Переменная             | Описание                                     |
|------------------------|----------------------------------------------|
| `BOT_TOKEN`           | Токен бота Telegram                          |
| `YOOKASSA_SHOP_ID`    | ID магазина YooKassa                         |
| `YOOKASSA_SECRET_KEY` | Секретный ключ YooKassa                      |
| `EMAIL`               | Email-адрес для связи                        |
| `MARZBAN_USERNAME`    | Логин для Marzban                            |
| `MARZBAN_PASSWORD`    | Пароль для Marzban                           |
| `MARZBAN_URL`        | URL панели Marzban                           |
| `OWNER_ID_KEY`       | Chat_id telegram админа                      |
| `DB_HOST`            | Хост базы данных                             |
| `DB_PORT`            | Порт базы данных                             |
| `DB_NAME`            | Название базы данных                         |
| `DB_USER`            | Имя пользователя БД                          |
| `DB_PASSWORD`        | Пароль пользователя БД                       |
| `ENABLE_YOOKASSA`    | Включение оплаты через YooKassa (True/False) |
| `ENABLE_STARS`       | Включение системы звезд (True/False)         |
| `URL_SUPPORT`        | Ссылка на поддержку                          |
| `URL_OFERTA`         | Ссылка на оферту                             |
| `URL_CHANEL_NEWS`    | Ссылка на канал новостей                     |
| `TG_BOT`            | Ссылка на Telegram-бота                      |
| `SPECIAL_USERS_CHAT_ID` | Chat_id пользователь со специальными ценами  |

