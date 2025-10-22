
# VPS Security Hardening

Коротко — быстрые команды для установки и запуска инсталлятора (one‑liner).

> **ВНИМАНИЕ:** запускать код напрямую из интернета (`curl | sudo bash` / `wget | sudo bash`) удобно, но потенциально рискованно. Рекомендуется сначала просмотреть содержимое скрипта, если вы не полностью доверяете репозиторию.

## Quickstart (one‑line)

Установить и сразу запустить (curl — рекомендуемый):
```bash  
curl -fsSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash  
Установить и сразу запустить (wget):

bash
wget -qO- https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh | sudo bash
Если хотите установить, но пропустить автоматический запуск (install.sh поддерживает флаг --no-run):

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
(Аналогично: wget -qO /tmp/install.sh <URL>.)

Примечания и полезные советы
Не используйте sudo bash <(curl -sSL ...) — этот вариант часто вызывает ошибку No such file or directory из‑за отсутствия /dev/fd/... у процесса sudo. Вместо этого:
используйте curl | sudo bash (pipe), или
если нужен process substitution, запускайте его внутри root‑shell:
sudo bash -c 'bash <(curl -fsSL https://.../install.sh)'
Веб‑интерфейс GitHub при создании файлов может не сохранять бит исполнения (+x). В нашем примере install.sh сам установит основной скрипт в /usr/local/bin и выставит права.
Если скрипт уже установлен, можно запустить его вручную:
bash
sudo /usr/local/bin/security-hardening.sh
Что делает install.sh
Коротко: скачивает security-hardening.sh в /usr/local/bin, ставит права исполнения и (в зависимости от опции) запускает его сразу. Подробности и доступные флаги — внутри самого install.sh.

Безопасность
Всегда проверяйте содержимое и источники перед выполнением кода с правами root.
Тестируйте изменения на тестовом сервере, прежде чем применять в production.
Тестируйте изменения на тестовом сервере, прежде чем применять в production.
Просматривайте и проверяйте скрипты перед запуском в production.
Рекомендуется сначала протестировать на тестовом сервере.
Однострочные установки (curl | sudo bash) удобны, но выполняют код без просмотра — используйте их только для доверенных репозиториев.
