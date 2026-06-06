# 🚀 VPS & DevOps Commands Quick Reference (Comprehensive Cheat Sheet)

This file contains an extensive, detailed table of all the commands you need to manage your VPS infrastructure, check system stats, configure firewalls, interact with PostgreSQL databases inside Kubernetes, debug microservices, run Ansible playbooks, and coordinate Git/Jenkins workflows.

---

### 1. Connection & System Diagnostics

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Connection** | Log in to the VPS via SSH | `ssh -i ~/.ssh/skillprof_vps root@167.86.100.54` | Connects securely to the VPS using your SSH private key. |
| **System Info** | Check OS Release / Version | `cat /etc/os-release` | Displays the operating system name and version (e.g., Ubuntu). |
| **System Info** | Check system uptime | `uptime` | Shows how long the VPS has been running and system load averages. |
| **Resources** | Check RAM usage | `free -h` | Shows total, used, and free RAM in human-readable sizes (MB/GB). |
| **Resources** | Check Disk Space | `df -h` | Shows total and free storage space on all hard disk drives. |
| **Resources** | Check CPU specifications | `lscpu` | Displays info about the CPU cores, speed, and architecture. |
| **Resources** | Monitor real-time processes | `top` or `htop` | Opens an interactive task manager showing CPU and RAM usage per process. |
| **Network** | List all listening ports on VPS | `netstat -tunlp` or `ss -tunlp` | Shows all active ports and the specific services listening on them. |
| **Network** | Test Gateway locally on VPS | `curl -s http://localhost:30000/api/app-version` | Sends a local health check to verify gateway-service routing. |

---

### 2. Firewall Management (UFW)

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Firewall** | Check Firewall Status | `ufw status verbose` | Shows if UFW is active and lists all open port rules. |
| **Firewall** | Allow SSH access port | `ufw allow 22/tcp` | Opens port 22 (SSH). **Always run this first to prevent lockouts.** |
| **Firewall** | Allow Jenkins access port | `ufw allow 8080/tcp` | Opens port 8080 for the Jenkins UI dashboard. |
| **Firewall** | Allow API Gateway access | `ufw allow 30000/tcp` | Opens port 30000 for client-app connections. |
| **Firewall** | Allow Grafana access | `ufw allow 4000/tcp` | Opens port 4000 for your Grafana charts. |
| **Firewall** | Allow Prometheus access | `ufw allow 9090/tcp` | Opens port 9090 for the Prometheus raw query UI. |
| **Firewall** | Allow K3s Pod virtual range | `ufw allow from 10.42.0.0/16` | Allows internal pods to communicate with other pods. |
| **Firewall** | Allow K3s Service virtual range | `ufw allow from 10.43.0.0/16` | Allows K3s internal service DNS resolving. |
| **Firewall** | Enable Packet Forwarding | `sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw` | Allows packet forwarding required by the Kubernetes CNI. |
| **Firewall** | Enable Firewall | `ufw --force enable` | Activates UFW rules. |
| **Firewall** | Disable Firewall | `ufw disable` | Turns off UFW completely. |

---

### 3. Kubernetes (K3s) Orchestration & Debugging

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Orchestration** | Check K3s service status | `systemctl status k3s` | Checks if the main Kubernetes orchestrator daemon is running. |
| **Orchestration** | Restart K3s engine | `systemctl restart k3s` | Restarts the entire K3s control plane on the VPS. |
| **Orchestration** | List all Kubernetes Pods | `kubectl get pods -o wide` | Lists all deployed microservices, their status, IPs, and restart counts. |
| **Orchestration** | List Kubernetes Deployments | `kubectl get deployments` | Shows state and availability status of all microservice structures. |
| **Orchestration** | List K8s Services & Ports | `kubectl get svc` | Shows the active internal and external ports (like the NodePort `30000`). |
| **Orchestration** | Restart K8s Deployment | `kubectl rollout restart deployment/<name>` | Forces a rolling update to load the latest Docker images. |
| **Orchestration** | Describe a Pod configuration | `kubectl describe pod <pod_name>` | Shows events, status, mounting volumes, and error logs for a pod. |
| **Orchestration** | View K8s cluster info | `kubectl cluster-info` | Displays master and service endpoints status. |
| **Orchestration** | View K8s node resources | `kubectl top node` | Displays CPU and memory utilization across the node cluster. |

---

### 4. Microservice Logs & Host Docker

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Docker** | Check Docker daemon status | `systemctl status docker` | Verifies if the Docker engine is running. |
| **Docker** | List Host Containers | `docker ps -a` | Displays all containers (Jenkins, Prometheus, Grafana), active ports, and status. |
| **Docker** | List Host Images | `docker images` | Displays all docker images built or pulled on the host machine. |
| **Docker** | View Container Logs | `docker logs <container_name_or_id>` | Prints runtime stdout logs of a host container (e.g. `docker logs jenkins`). |
| **Docker** | Restart Jenkins container | `docker restart jenkins` | Restarts the Jenkins dashboard container. |
| **Logs** | View Service Pod Logs | `kubectl logs <pod_name>` | Prints logs for a specific microservice pod. |
| **Logs** | Stream Pod Logs live | `kubectl logs -f <pod_name>` | Follows and prints logs in real-time. |
| **Logs** | View last N lines of Pod logs | `kubectl logs <pod_name> --tail=<N>` | Displays only the last `N` lines of log outputs. |

---

### 5. Database Interactivity (PostgreSQL inside K3s)

Use these commands to log directly into your database pods to check schemas, verify credentials, and query records.

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Database** | Log in to the PostgreSQL pod | `kubectl exec -it deployment/identity-db -- psql -U skilluser -d identity_db` | Connects interactively to the PostgreSQL database on the K3s pod. |
| **Database** | List all databases | `\l` (inside psql client) | Lists all databases running on the PostgreSQL server. |
| **Database** | List all tables | `\dt` (inside psql client) | Displays all database tables for the active database. |
| **Database** | Select all registered users | `SELECT * FROM "user";` (inside identity_db) | Returns a table of all registered users, roles, and status. |
| **Database** | Quit PostgreSQL client | `\q` (inside psql client) | Exits the interactive psql terminal session. |

---

### 6. Ansible Playbook Automation

Execute these commands from your **local machine** (within `c:\SkillSwapPrro`) to manage VPS deployments.

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Ansible** | Provision VPS dependencies | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/install_dependencies.yml` | Installs system updates, Git, Docker, Docker Compose, and directories. |
| **Ansible** | Deploy application microservices | `ansible-playbook -i ansible/hosts.ini ansible/playbooks/deploy_app.yml` | Clones repository, sets folder permissions, and spins up local docker compose. |

---

### 7. Git Workflow (Local Workspace)

Run these commands inside your local repository folder to push changes to GitHub.

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Git** | Check modified files status | `git status` | Shows staged, unstaged, and untracked files in the workspace. |
| **Git** | Add files to stage | `git add <file_path>` | Stages modified files for commit (e.g. `git add Jenkinsfile`). |
| **Git** | Commit changes | `git commit -m "Commit message"` | Saves your staged changes locally with a descriptive message. |
| **Git** | Push changes to GitHub | `git push origin main` | Uploads local commits to the GitHub repository main branch. |
| **Git** | Pull updates from GitHub | `git pull origin main` | Fetches and merges updates from the remote GitHub branch. |
