# MoonTrader Core Installer

[English](#english) | [Русский](#русский)

Official MoonTrader website: [moontrader.com](https://moontrader.com)  
Contact: Telegram [@Ruzor](https://t.me/Ruzor)

Unofficial project. This installer is not an official MoonTrader installation script. It was created by the author for personal use.

Неофициальный проект. Это не официальный скрипт установки MoonTrader; он сделан автором для собственного использования.

## English

Automatic MoonTrader Core installer for Ubuntu 22.04+ x86_64 VPS.

The script automates the manual Linux VPS setup flow: it updates the system, installs required libraries, creates compatibility files for `libtommath.so.0` and `libncurses.so.5`, downloads the x86-64 archive, unpacks the core, and starts `./MTCore` inside `tmux`.

After installation, the script creates a systemd service. This means MTCore will automatically start again inside the `mt` tmux session after a VPS reboot.

### Requirements

- Ubuntu 22.04+ x86_64 VPS.
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

- The script is intended only for Ubuntu 22.04+ x86_64.
- The script does not store or request MoonTrader API keys.
- The script downloads the MoonTrader archive from MoonTrader CDN.
- If you close SSH after installation, reconnect with `tmux a -t mt`.

## Русский

Автоматическая установка ядра MoonTrader на Ubuntu 22.04+ x86_64 VPS.

Скрипт автоматизирует ручную установку на Linux VPS: обновляет систему, ставит нужные библиотеки, создает совместимые файлы `libtommath.so.0` и `libncurses.so.5`, скачивает x86-64 архив, распаковывает ядро и запускает `./MTCore` внутри `tmux`.

После установки создается systemd-сервис, поэтому после перезапуска VPS ядро снова стартует в `tmux`-сессии `mt`.

### Требования

- Ubuntu 22.04+ x86_64 VPS.
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

- Скрипт рассчитан только на Ubuntu 22.04+ x86_64.
- Скрипт не хранит и не запрашивает API-ключи MoonTrader.
- Скрипт скачивает архив MoonTrader с CDN MoonTrader.
- Если после установки вы закрыли SSH, вернуться к ядру можно командой `tmux a -t mt`.

## License

MIT. MoonTrader and its binary files are not included in this repository and belong to their respective rights holders.
