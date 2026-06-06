# 🚀 VPS Commands Quick Reference (Cheat Sheet)

This file contains a complete table of all the commands you need to manage your VPS, check your system status, configure firewalls, and monitor your Docker and Kubernetes (K3s) orchestration.

---

| Category | Goal / Purpose | Command | Explanation |
| :--- | :--- | :--- | :--- |
| **Connection** | Log in to the VPS via SSH | `ssh -i ~/.ssh/skillprof_vps root@167.86.100.54` | Connects securely to the VPS using your SSH private key. |
| **System Info** | Check OS Release / Version | `cat /etc/os-release` | Displays the operating system name and version. |
| **Resources** | Check RAM usage | `free -h` | Shows total, used, and free RAM in human-readable sizes (MB/GB). |
| **Resources** | Check Disk Space | `df -h` | Shows total and free storage space on all hard disk drives. |
| **Resources** | Check CPU specifications | `lscpu` | Displays info about the CPU cores, speed, and architecture. |
| **Resources** | Monitor real-time processes | `top` or `htop` | Opens an interactive task manager showing CPU and RAM usage per process. |
| **Firewall** | Check Firewall Status | `ufw status verbose` | Shows if UFW is active and lists all open port rules. |
| **Firewall** | Allow SSH access port | `ufw allow 22/tcp` | Opens port 22 (SSH). **Always run this first.** |
| **Firewall** | Allow Jenkins access port | `ufw allow 8080/tcp` | Opens port 8080 for the Jenkins UI dashboard. |
| **Firewall** | Allow API Gateway access | `ufw allow 30000/tcp` | Opens port 30000 for client-app connections. |
| **Firewall** | Allow Grafana access | `ufw allow 4000/tcp` | Opens port 4000 for your Grafana charts. |
| **Firewall** | Allow Prometheus access | `ufw allow 9090/tcp` | Opens port 9090 for the Prometheus raw query UI. |
| **Firewall** | Allow K3s Pod virtual range | `ufw allow from 10.42.0.0/16` | Allows internal pods to communicate with other pods. |
| **Firewall** | Allow K3s Service virtual range | `ufw allow from 10.43.0.0/16` | Allows K3s internal service DNS resolving. |
| **Firewall** | Enable Firewall | `ufw --force enable` | Activates UFW rules. |
| **Orchestration** | Check K3s service status | `systemctl status k3s` | Checks if the main Kubernetes orchestrator daemon is running. |
| **Orchestration** | List all Kubernetes Pods | `kubectl get pods -o wide` | Lists all deployed microservices, their status, IPs, and restart counts. |
| **Orchestration** | List Kubernetes Deployments | `kubectl get deployments` | Shows state and availability status of all microservice structures. |
| **Orchestration** | List K8s Services & Ports | `kubectl get svc` | Shows the active internal and external ports (like the NodePort `30000`). |
| **Orchestration** | Restart K8s Deployment | `kubectl rollout restart deployment/<name>` | Forces a rolling update to load the latest Docker images. |
| **Docker** | Check Docker daemon status | `systemctl status docker` | Verifies if the Docker engine is running. |
| **Docker** | List Host Containers | `docker ps -a` | Displays all containers (Jenkins, Prometheus, Grafana), active ports, and status. |
| **Docker** | List Host Images | `docker images` | Displays all docker images built or pulled on the host machine. |
| **Docker** | View Container Logs | `docker logs <container_name_or_id>` | Prints runtime stdout logs of a host container (e.g. `docker logs jenkins`). |
| **Logs** | View Service Pod Logs | `kubectl logs <pod_name>` | Prints logs for a specific microservice pod. |
| **Logs** | Stream Pod Logs live | `kubectl logs -f <pod_name>` | Follows and prints logs in real-time. |
| **Logs** | View last N lines of Pod logs | `kubectl logs <pod_name> --tail=<N>` | Displays only the last `N` lines of log outputs. |
