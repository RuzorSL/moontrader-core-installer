# MoonTrader Core Installer

[Русский](#русский) | [English](#english)

Contact: Telegram [@Ruzor](https://t.me/Ruzor)

## Русский

Автоматическая установка ядра MoonTrader на Ubuntu x86_64 VPS.

Скрипт повторяет шаги из официальной инструкции MoonTrader для Linux VPS: обновляет систему, ставит нужные библиотеки, создает совместимые файлы `libtommath.so.0` и `libncurses.so.5`, скачивает x86-64 архив, распаковывает ядро и запускает `./MTCore` внутри `tmux`.

После установки создается systemd-сервис, поэтому после перезапуска VPS ядро снова стартует в `tmux`-сессии `mt`.

Официальная инструкция: <https://docs.moontrader.com/ru/ustanovka-yadra-linux-vps>

### Требования

- Ubuntu x86_64/amd64 VPS.
- Пользователь с `sudo` или запуск от `root`.
- systemd.
- Доступ в интернет для скачивания архива MoonTrader.

### Быстрая установка

Скачать установщик напрямую с GitHub и запустить:

```bash
wget -O install.sh https://raw.githubusercontent.com/RuzorSL/moontrader-core-installer/main/install.sh
bash install.sh
```

Или скачайте репозиторий и запустите файл вручную:

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

### Подключение к ядру после выхода из SSH

```bash
tmux a -t mt
```

Отключиться от `tmux`, не останавливая ядро:

```text
Ctrl+B, затем D
```

### Автозапуск после перезагрузки VPS

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

### Полезные варианты запуска

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

### Переменные окружения

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

### Удаление

Остановить ядро, отключить автозапуск и удалить systemd-сервис:

```bash
bash uninstall.sh
```

Папка `~/MoonTrader` при этом останется на месте.

Удалить сервис и папку MoonTrader:

```bash
bash uninstall.sh --purge-files
```

### Что важно знать

- Скрипт рассчитан только на Ubuntu x86_64/amd64.
- Скрипт не хранит и не запрашивает API-ключи MoonTrader.
- Скрипт скачивает официальный архив MoonTrader по адресу из документации.
- Если после установки вы закрыли SSH, вернуться к ядру можно командой `tmux a -t mt`.
- Контакт автора: Telegram [@Ruzor](https://t.me/Ruzor).

## English

Automatic MoonTrader Core installer for Ubuntu x86_64 VPS.

The script follows the official MoonTrader Linux VPS guide: it updates the system, installs required libraries, creates compatibility files for `libtommath.so.0` and `libncurses.so.5`, downloads the x86-64 archive, unpacks the core, and starts `./MTCore` inside `tmux`.

After installation, the script creates a systemd service. This means MTCore will automatically start again inside the `mt` tmux session after a VPS reboot.

Official guide: <https://docs.moontrader.com/ru/ustanovka-yadra-linux-vps>

### Requirements

- Ubuntu x86_64/amd64 VPS.
- A user with `sudo`, or a `root` session.
- systemd.
- Internet access to download the MoonTrader archive.

### Quick Install

Download the installer directly from GitHub and run it:

```bash
wget -O install.sh https://raw.githubusercontent.com/RuzorSL/moontrader-core-installer/main/install.sh
bash install.sh
```

Or download the repository and run the file manually:

```bash
bash install.sh
```

By default, the core is installed to:

```text
~/MoonTrader
```

After installation, the script automatically opens `tmux` with:

```bash
./MTCore
```

Continue the initial MoonTrader Core setup in that tmux session.

### Reconnect After Leaving SSH

```bash
tmux a -t mt
```

Detach from `tmux` without stopping MTCore:

```text
Ctrl+B, then D
```

### Autostart After VPS Reboot

The installer creates and enables this service:

```text
moontrader-core.service
```

Check status:

```bash
sudo systemctl status moontrader-core.service
```

Restart MTCore:

```bash
sudo systemctl restart moontrader-core.service
```

Stop MTCore:

```bash
sudo systemctl stop moontrader-core.service
```

### Useful Options

Skip `apt upgrade` and only run `apt update` plus dependency installation:

```bash
bash install.sh --skip-upgrade
```

Install to another directory:

```bash
bash install.sh --dir /opt/MoonTrader
```

Run MTCore as a specific user:

```bash
bash install.sh --user ubuntu
```

Download and unpack MTCore again:

```bash
bash install.sh --force-reinstall
```

Install only, without starting MTCore immediately:

```bash
bash install.sh --no-start
```

Start MTCore, but do not automatically attach to `tmux`:

```bash
bash install.sh --no-attach
```

### Environment Variables

You can configure installation with environment variables:

```bash
MOONTRADER_DIR=/opt/MoonTrader \
RUN_USER=ubuntu \
TMUX_SESSION=mt \
SERVICE_NAME=moontrader-core \
bash install.sh
```

Available variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `MOONTRADER_DIR` | `~/MoonTrader` | Installation directory |
| `RUN_USER` | current user | User that runs `MTCore` |
| `TMUX_SESSION` | `mt` | tmux session name |
| `SERVICE_NAME` | `moontrader-core` | systemd service name |
| `DO_SYSTEM_UPGRADE` | `1` | Run `apt upgrade`; set to `0` to skip |
| `FORCE_REINSTALL` | `0` | Download and unpack MTCore again |

### Uninstall

Stop MTCore, disable autostart, and remove the systemd service:

```bash
bash uninstall.sh
```

The `~/MoonTrader` directory will be kept.

Remove the service and the MoonTrader directory:

```bash
bash uninstall.sh --purge-files
```

### Notes

- The script is intended only for Ubuntu x86_64/amd64.
- The script does not store or request MoonTrader API keys.
- The script downloads the official MoonTrader archive from the URL used in the documentation.
- If you close SSH after installation, reconnect with `tmux a -t mt`.
- Author contact: Telegram [@Ruzor](https://t.me/Ruzor).

## License

MIT. MoonTrader and its binary files are not included in this repository and belong to their respective rights holders.
