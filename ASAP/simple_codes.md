# 🚀 VPS Commands Quick Reference

This file contains the exact vertical layout and commands from the official **`VPS_Commands_Quick_Reference_Table.pdf`**.

---

| Category | Feature / Metric | Command(s) | Description |
| :--- | :--- | :--- | :--- |
| **Connection & Diagnostics** | SSH Login | `ssh -i ~/.ssh/skillprof_vps root@167.86.100.54` | Log in to VPS host |
| | RAM & CPU | `free -h` <br> `lscpu` | View memory & CPU |
| | Disk Space | `df -h` | View disk space |
| | Listening Ports | `ss -tunlp` | List active ports |
| | Local Health Test | `curl -s http://localhost:30000/api/app-version` | Test API gateway |
| **Firewall (UFW)** | SSH Port | `ufw allow 22/tcp` | Open SSH |
| | Jenkins Port | `ufw allow 8080/tcp` | Open Jenkins |
| | API Gateway | `ufw allow 30000/tcp` | Open Gateway |
| | Grafana | `ufw allow 4000/tcp` | Open Grafana |
| | Prometheus | `ufw allow 9090/tcp` | Open Prometheus |
| | K3s Internal | `ufw allow from 10.42.0.0/16` <br> `ufw allow from 10.43.0.0/16` | Allow K3s traffic |
| | Forward Policy | `sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw` | Enable forwarding |
| **Kubernetes (K3s)** | Pods List | `kubectl get pods -o wide` | Show pods |
| | Deployments | `kubectl get deployments` | Show deployments |
| | Services | `kubectl get svc` | Show services |
| | Describe Pod | `kubectl describe pod` | Inspect pod |
| | Restart | `kubectl rollout restart deployment/` | Restart deployment |
| **Docker** | Containers | `docker ps -a` | List containers |
| | Images | `docker images` | List images |
| | Logs | `docker logs` | View logs |
| | Restart Jenkins | `docker restart jenkins` | Restart Jenkins |
| **Microservice Logs** | Standard | `kubectl logs` | View logs |
| | Follow | `kubectl logs -f` | Live logs |
| | Tail | `kubectl logs --tail=` | Last N lines |
| **PostgreSQL** | psql Login | `kubectl exec -it deployment/identity-db -- psql -U skilluser -d identity_db` | Connect DB |
| | List DBs | `\l` | Show databases |
| | List Tables | `\dt` | Show tables |
| | Query Users | `SELECT * FROM "user";` | View users |
| | Exit | `\q` | Exit |
| **Ansible & Git** | Provision | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/install_dependencies.yml` | Install deps |
| | Deploy | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/deploy_app.yml` | Deploy app |
| | Git Stage | `git add` | Stage |
| | Git Commit | `git commit -m "msg"` | Commit |
| | Git Push | `git push origin main` | Push |
