# 🚀 VPS Commands Horizontal Quick Reference (Grid Layout)

This file contains your VPS commands formatted in a structured horizontal grid layout, matching your report formatting template style.

---

### 1. Connection & System Diagnostics

| Feature / Metric | SSH Login | RAM & CPU | Disk Space | Listening Ports | Local Health Test |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Diagnostics** | `ssh -i ~/.ssh/skillprof_vps root@167.86.100.54` | `free -h` <br> `lscpu` | `df -h` | `ss -tunlp` | `curl -s http://localhost:30000/api/app-version` |
| **Description** | Log in to the VPS host | View free memory & CPU cores | View remaining disk space | List open TCP ports | Test API gateway routing |

---

### 2. Firewall Settings (UFW)

| Feature / Metric | SSH Port | Jenkins Port | API Gateway Port | Grafana Port | Prometheus Port | CNI Pod Ranges |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Ports** | `ufw allow 22/tcp` | `ufw allow 8080/tcp` | `ufw allow 30000/tcp` | `ufw allow 4000/tcp` | `ufw allow 9090/tcp` | `ufw allow from 10.42.0.0/16` <br> `10.43.0.0/16` |
| **Description** | Open SSH access | Open Jenkins dashboard | Open Gateway NodePort | Open Grafana charts | Open Prometheus UI | Allow internal K3s traffic |

*(Note: Run `sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw` to enable K3s forwarding before executing `ufw --force enable`).*

---

### 3. Kubernetes (K3s) Orchestration

| Feature / Metric | Pods List | Deployments | Services & Ports | Pod Description | Rollout Restart |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Orchestration** | `kubectl get pods -o wide` | `kubectl get deployments` | `kubectl get svc` | `kubectl describe pod <name>` | `kubectl rollout restart deployment/<name>` |
| **Description** | List all microservices status | Show active deployment sets | Show services internal ports | Inspect container launch logs | Trigger zero-downtime update |

---

### 4. Docker & Host Containers

| Feature / Metric | List Containers | List Images | Container Logs | Restart Jenkins |
| :--- | :--- | :--- | :--- | :--- |
| **Containers** | `docker ps -a` | `docker images` | `docker logs <container>` | `docker restart jenkins` |
| **Description** | Show all host containers | Show all built docker images | Print host container logs | Restart Jenkins dashboard |

---

### 5. Microservice Log Streaming

| Feature / Metric | Standard Logs | Follow Live Logs | Tail Logs |
| :--- | :--- | :--- | :--- |
| **Log Commands** | `kubectl logs <pod_name>` | `kubectl logs -f <pod_name>` | `kubectl logs <pod_name> --tail=<N>` |
| **Description** | View stdout of a service pod | Stream logs continuously | View last N lines of logs |

---

### 6. PostgreSQL Database Client (Inside K3s)

| Feature / Metric | psql Client Login | List Databases | List Tables | Query Users | Exits Client |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `kubectl exec -it deployment/identity-db -- psql -U skilluser -d identity_db` | `\l` | `\dt` | `SELECT * FROM "user";` | `\q` |
| **Description** | Log in interactively to db pod | List databases on server | List tables in active DB | View registered users | Exit database psql terminal |

---

### 7. Ansible & Git DevOps Workflows

| Feature / Metric | Ansible Provision | Ansible Deploy | Git Stage | Git Commit | Git Push |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DevOps** | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/install_dependencies.yml` | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/deploy_app.yml` | `git add <file>` | `git commit -m "msg"` | `git push origin main` |
| **Description** | Configure host system packages | Deploy latest git codebase | Add files to git index | Save changes locally | Upload changes to GitHub |
