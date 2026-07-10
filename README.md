# MoonTrader Core Installer

Автоматическая установка ядра MoonTrader на Ubuntu x86_64 VPS.

Скрипт повторяет шаги из официальной инструкции MoonTrader для Linux VPS: обновляет систему, ставит нужные библиотеки, создает совместимые файлы `libtommath.so.0` и `libncurses.so.5`, скачивает x86-64 архив, распаковывает ядро и запускает `./MTCore` внутри `tmux`.

После установки создается systemd-сервис, поэтому после перезапуска VPS ядро снова стартует в `tmux`-сессии `mt`.

Официальная инструкция: <https://docs.moontrader.com/ru/ustanovka-yadra-linux-vps>

## Требования

- Ubuntu x86_64/amd64 VPS.
- Пользователь с `sudo` или запуск от `root`.
- systemd.
- Доступ в интернет для скачивания архива MoonTrader.

## Быстрая установка

Скачайте репозиторий или один файл `install.sh`, затем запустите:

```bash
bash install.sh
```

По умолчанию ядро ставится в:

```text
~/MoonTrader
```

После установки скрипт автоматически откроет `tmux` с запущенным:

```bash
./MTCore
```

Дальше можно выполнить первичную настройку ядра MoonTrader прямо в открывшейся сессии.

## Подключение к ядру после выхода из SSH

```bash
tmux a -t mt
```

Отключиться от `tmux`, не останавливая ядро:

```text
Ctrl+B, затем D
```

## Автозапуск после перезагрузки VPS

Установщик создает и включает сервис:

```text
moontrader-core.service
```

Проверить статус:

```bash
sudo systemctl status moontrader-core.service
```

Перезапустить ядро:

```bash
sudo systemctl restart moontrader-core.service
```

Остановить ядро:

```bash
sudo systemctl stop moontrader-core.service
```

## Полезные варианты запуска

Не делать `apt upgrade`, только `apt update` и установку зависимостей:

```bash
bash install.sh --skip-upgrade
```

Установить в другую папку:

```bash
bash install.sh --dir /opt/MoonTrader
```

Запускать ядро от конкретного пользователя:

```bash
bash install.sh --user ubuntu
```

Скачать и распаковать ядро заново:

```bash
bash install.sh --force-reinstall
```

Установить, но не запускать ядро сразу:

```bash
bash install.sh --no-start
```

Запустить ядро, но не открывать `tmux` автоматически:

```bash
bash install.sh --no-attach
```

## Переменные окружения

Можно настроить установку через переменные:

```bash
MOONTRADER_DIR=/opt/MoonTrader \
RUN_USER=ubuntu \
TMUX_SESSION=mt \
SERVICE_NAME=moontrader-core \
bash install.sh
```

Доступные переменные:

| Переменная | Значение по умолчанию | Назначение |
| --- | --- | --- |
| `MOONTRADER_DIR` | `~/MoonTrader` | Папка установки |
| `RUN_USER` | текущий пользователь | Пользователь, от которого запускается `MTCore` |
| `TMUX_SESSION` | `mt` | Имя `tmux`-сессии |
| `SERVICE_NAME` | `moontrader-core` | Имя systemd-сервиса |
| `DO_SYSTEM_UPGRADE` | `1` | Делать `apt upgrade`; поставьте `0`, чтобы пропустить |
| `FORCE_REINSTALL` | `0` | Скачать и распаковать ядро заново |

## Удаление

Остановить ядро, отключить автозапуск и удалить systemd-сервис:

```bash
bash uninstall.sh
```

Папка `~/MoonTrader` при этом останется на месте.

Удалить сервис и папку MoonTrader:

```bash
bash uninstall.sh --purge-files
```

## Что важно знать

- Скрипт рассчитан только на Ubuntu x86_64/amd64.
- Скрипт не хранит и не запрашивает API-ключи MoonTrader.
- Скрипт скачивает официальный архив MoonTrader по адресу из документации.
- Если после установки вы закрыли SSH, вернуться к ядру можно командой `tmux a -t mt`.

## Лицензия

MIT. Сам MoonTrader и его бинарные файлы не входят в этот репозиторий и принадлежат их правообладателям.
