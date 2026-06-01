# Лабораторна робота №4 — IaC. Terraform. Ansible

Проєкт — веб-застосунок **Task Tracker** з автоматизованим розгортанням на двох віртуальних машинах за допомогою Terraform та Ansible.

---
### Лебедєва Софія ІМ-44
---

## Варіант індивідуального завдання

**Номер варіанту:** N = 13

| Параметр | Формула | Значення | Опис |
|----------|---------|----------|------|
| V2 | (13 % 2) + 1 | **2** | Файл конфігурації `/etc/mywebapp/config.json`, БД — PostgreSQL |
| V3 | (13 % 3) + 1 | **2** | Тип застосунку — Task Tracker |
| V5 | (13 % 5) + 1 | **4** | Порт застосунку — `8000` |

---

## Архітектура системи
```text
         +--------------VM1 (worker)---------------+       +---VM2 (db)---+
client → | nginx (reverse proxy) → web application |   →   | SQL database |
         +-----------------------------------------+       +--------------+
```

| Компонент | Адреса | Порт |
|-----------|--------|------|
| nginx | 0.0.0.0 | 80 |
| web app | 127.0.0.1 | 8000 |
| PostgreSQL | 192.168.56.11 | 5432 |

---

## Структура репозиторію

```
deployment-course-lab-4/
├── ansible/
│   ├── ansible.cfg                          # Конфігурація Ansible
│   ├── inventory.ini                        # Inventory файл (workers та db групи)
│   ├── site.yml                             # Головний playbook
│   └── roles/
│       ├── common/                          # Загальне налаштування всіх VM
│       │   └── tasks/main.yml
│       ├── db/                              # Налаштування PostgreSQL
│       │   ├── handlers/main.yml
│       │   ├── tasks/main.yml
│       │   └── vars/main.yml
│       ├── webapp/                          # Розгортання застосунку
│       │   ├── handlers/main.yml
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       └── config.json.j2           # Шаблон конфігурації застосунку
│       └── nginx/
│           ├── handlers/main.yml
│           ├── tasks/main.yml
│           └── templates/
│               └── mywebapp.conf.j2         # Шаблон конфігурації nginx
├── terraform/
│   ├── main.tf                              # Опис інфраструктури
│   ├── variables.tf                         # Змінні
│   ├── outputs.tf                           # Вивід IP адрес
│   ├── cloud-init/
│   │   ├── worker.yaml                      # cloud-init для VM1
│   │   └── db.yaml                          # cloud-init для VM2
│   └── scripts/
│       ├── create_vm.sh                     # Скрипт створення VM
│       ├── destroy_vm.sh                    # Скрипт видалення VM
│       └── make_iso.sh                      # Скрипт створення cloud-init ISO
├── migrations/
│   └── 001_init.sql                         # SQL міграція
├── src/
│   └── mywebapp/                            # Вихідний код C# застосунку (.NET 10)
├── Dockerfile                               # Образ застосунку для Docker (Лаб. 2)
├── docker-compose.yml                       # Docker Compose (Лаб. 2)
└── README.md
```

---

## Передумови на хост-машині (Windows)
1. **VirtualBox 7.x** — [virtualbox.org](https://www.virtualbox.org)
2. **Terraform** — [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform/install)
3. **WSL2 з Ubuntu** — для запуску Ansible
4. **Ansible** — встановлюється в WSL: `sudo apt install -y ansible`
5. **genisoimage** — встановлюється в WSL: `sudo apt install -y genisoimage`
6. **.NET SDK 10.0** — встановлюється в WSL для збірки застосунку

### SSH ключ
```bash
ssh-keygen -t ed25519 -f ~/.ssh/deployment_lab4 -N ""
```

Публічний ключ з `~/.ssh/deployment_lab4.pub` має бути вказаний у:
- `terraform/cloud-init/worker.yaml`
- `terraform/cloud-init/db.yaml`

---

## Розгортання

### Крок 1 — Визначити IP хосту Windows з WSL

```bash
ip route | grep default | awk '{print $3}'
```

Отриманий IP підставити в `ansible/inventory.ini` замість `172.17.112.1`.

### Крок 2 — Зібрати застосунок

```bash
dotnet publish src/mywebapp/mywebapp.csproj \
  -c Release -r linux-x64 --self-contained true \
  -o ansible/roles/webapp/files/
```

### Крок 3 — Terraform (створення VM)

```bash
cd terraform
terraform init
terraform apply
```

Terraform створить дві VM:
- **lab4-worker** — 192.168.56.10, NAT SSH порт 2222
- **lab4-db** — 192.168.56.11, NAT SSH порт 2223

Дочекатись поки VM завантажаться (2-3 хвилини).

### Крок 4 — Ansible (налаштування VM)

```bash
cd ansible
ansible-playbook site.yml
```

Ansible виконає:
- Встановлення та налаштування PostgreSQL на db VM
- Розгортання застосунку на worker VM
- Налаштування nginx як reverse proxy
- Створення користувачів (teacher, app, operator)

---

## Перевірка роботи

### 1. Головна сторінка

Linux / macOS / WSL:
```bash
curl -H "Accept: text/html" http://192.168.56.10/
```

PowerShell:
```powershell
curl.exe -H "Accept: text/html" http://192.168.56.10/
```

Має відобразитися HTML-сторінка зі списком API-ендпоінтів.

### 2. Перевірка списку задач

Linux / macOS / WSL:
```bash
curl http://192.168.56.10/tasks
```

PowerShell:
```powershell
curl.exe http://192.168.56.10/tasks
```

Має відобразитися порожня таблиця.

### 3. Створення задачі

Linux / macOS / WSL:
```bash
curl -X POST http://192.168.56.10/tasks \
     -H "Content-Type: application/json" \
     -d '{"title": "Тестова задача"}'
```

PowerShell:
```powershell
curl.exe -X POST http://192.168.56.10/tasks `
     -H "Content-Type: application/json" `
     -d '{\"title\": \"Тестова задача\"}'
```

Відповідь:
```json
{
  "id": 1,
  "title": "Тестова задача",
  "status": "pending",
  "created_at": "2026-06-01T22:08:22Z"
}
```

### 4. Позначення задачі як виконаної

Linux / macOS / WSL:
```bash
curl -X POST http://192.168.56.10/tasks/1/done
```

PowerShell:
```powershell
curl.exe -X POST http://192.168.56.10/tasks/1/done
```

У відповіді має повернутись JSON зі зміненим статусом `"status": "done"`.

### 5. Перевірка що health-ендпоінти закриті ззовні

Linux / macOS / WSL:
```bash
curl http://192.168.56.10/health/alive  # має повернути 404
curl http://192.168.56.10/health/ready  # має повернути 404
```

PowerShell:
```powershell
curl.exe http://192.168.56.10/health/alive
curl.exe http://192.168.56.10/health/ready
```

### 6. Перевірка health/ready напряму на VM

Linux / macOS / WSL:
```bash
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 \
  "curl -s http://127.0.0.1:8000/health/ready"
```

PowerShell:
```powershell
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 `
  "curl -s http://127.0.0.1:8000/health/ready"
```

Має повернути `OK`.

### 7. Перевірка статусу сервісів

Linux / macOS / WSL:
```bash
# На worker VM
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 \
  "sudo systemctl status mywebapp nginx --no-pager"

# На db VM
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.11 \
  "sudo systemctl status postgresql --no-pager"
```

PowerShell:
```powershell
# На worker VM
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 `
  "sudo systemctl status mywebapp nginx --no-pager"

# На db VM
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.11 `
  "sudo systemctl status postgresql --no-pager"
```

Всі сервіси повинні бути `active (running)`.

### 8. Перевірка користувачів

Linux / macOS / WSL:
```bash
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 \
  "getent passwd teacher app operator && sudo cat /etc/sudoers.d/operator"
```

PowerShell:
```powershell
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 `
  "getent passwd teacher app operator && sudo cat /etc/sudoers.d/operator"
```

### 9. Перевірка файлу gradebook

Linux / macOS / WSL:
```bash
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 \
  "cat /home/teacher/gradebook"
```

PowerShell:
```powershell
ssh -i ~/.ssh/deployment_lab4 ansible@192.168.56.10 `
  "cat /home/teacher/gradebook"
```

Має вивести: `13`

---

## Користувачі системи

| Користувач | VM | Пароль | Права |
|------------|-----|--------|-------|
| `ansible` | всі | SSH ключ | sudo без пароля |
| `teacher` | всі | `12345678` | sudo з паролем. Зміна пароля при першому вході. |
| `app` | worker | — | системний, запускає застосунок |
| `operator` | worker | `12345678` | обмежений sudo (тільки mywebapp та nginx). Зміна пароля при першому вході. |

---

## Зупинка VM

```bash
# Зберегти стан і зупинити
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "lab4-worker" savestate
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "lab4-db" savestate
```

```bash
# Видалити VM повністю
cd terraform
terraform destroy
```