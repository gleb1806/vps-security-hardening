
# VPS Security Hardening

Quickstart — быстрые команды для установки и запуска инсталлятора (one‑liner).

> **ВНИМАНИЕ:** запускать код напрямую из интернета (`curl | sudo bash`) удобно, но потенциально рискованно. Рекомендуется сначала просмотреть содержимое скрипта, если вы не полностью доверяете репозиторию.

## Quickstart (one‑line)

### Рекомендуемый (curl — pipe)
Установить и сразу запустить:
```bash  
curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash  
Альтернатива (wget — pipe)
Установить и сразу запустить:

bash
wget -qO- https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash
Опционально — process substitution (curl)
Если pipe по каким‑то причинам неудобен, можно выполнить process substitution внутри root‑shell:

bash
sudo bash -c 'bash <(curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh)'
Примечание: запуск sudo bash <(curl ...) напрямую часто даёт ошибку No such file or directory из‑за отсутствия дескриптора /dev/fd/... у процесса sudo. Поэтому, если вам нужен вариант с process substitution, используйте sudo bash -c 'bash <(...)'.

Установить, но не запускать автоматически
install.sh поддерживает флаг --no-run — он установит основной скрипт, но не будет запускать его сразу:

bash
curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash -s -- --no-run
# или с wget
wget -qO- https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash -s -- --no-run
Более безопасный вариант (рекомендуется для незнакомых репозиториев)
Сначала скачайте и просмотрите скрипт, затем запустите:

bash
curl -fsSL -o /tmp/install.sh https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh
less /tmp/install.sh    # просмотреть код
sudo bash /tmp/install.sh
rm -f /tmp/install.sh
(аналогично с wget -qO /tmp/install.sh <URL>)

Полезные заметки
Не используйте sudo bash <(curl -sSL ...) — этот вариант часто вызывает ошибку No such file or directory из‑за отсутствия /dev/fd/... у процесса sudo.
Предпочтительный простой вариант — curl | sudo bash (pipe) или скачивание и запуск вручную.
Веб‑интерфейс GitHub при создании файлов может не сохранять бит исполнения (+x). В нашем примере install.sh сам установит основной скрипт в /usr/local/bin и выставит права исполнения.
Если скрипт уже установлен вручную, запустить его можно так:
bash
sudo /usr/local/bin/security-hardening.sh
Что делает install.sh
Коротко: скачивает security-hardening.sh из репозитория в /usr/local/bin, ставит права исполнения и (в зависимости от опции) запускает его сразу. Подробности и опции — внутри самого install.sh.

Безопасность
Просматривайте и проверяйте скрипты перед запуском в production.
Рекомендуется сначала протестировать на тестовом сервере.
Однострочные установки (curl | sudo bash) удобны, но выполняют код без просмотра — используйте их только для доверенных репозиториев.

Безопасность
Просматривайте и проверяйте скрипты перед запуском в production.
Рекомендуется сначала протестировать на тестовом сервере.
Однострочные установки (curl | sudo bash) удобны, но выполняют код без просмотра — используйте их только для доверенных репозиториев.
