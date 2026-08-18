# Live Demo Guide — Assignment 01 (Docker)

A tight, ordered script for a live walkthrough. Total time: roughly 12-15 minutes including talk time. Each step includes what to say, the command, and what the reviewer should see.

## Before you start (do this ~2 minutes before the demo)

Start the VM ahead of time — boot + SSH readiness takes ~30-60 seconds, don't eat demo time waiting on this:

```bash
gcloud compute instances start cse644-lab-vm --project=kuldeep-cse644-lab --zone=us-west1-b
gcloud compute instances describe cse644-lab-vm --project=kuldeep-cse644-lab --zone=us-west1-b --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
```

SSH in and confirm you're in the right place:
```bash
ssh testuser@<external-ip>
cd ~/cse644-cloud-lab
git pull   # make sure you're demoing the latest committed state
git log --oneline -5
```

## 1. Infrastructure — "this runs on real cloud infra, not a local VM" (~2 min)

Say: *"This assignment runs on a GCP VM provisioned entirely through Terraform — not a manually clicked-together instance."*

```bash
cd terraform/single-vm
cat compute.tf   # show the VM resource definition briefly
terraform state list   # show the 6 managed resources
```

Point out: dedicated VPC, firewall rules scoped to your admin IP only, `e2-standard-4` sizing.

## 2. Docker Hub authentication (~1 min)

Say: *"CLI authentication to Docker Hub, generating an access-token-based login rather than a password."*

```bash
docker login -u kuldeepjain1920
# (already logged in from earlier in the session is fine — shows cached auth)
docker info | grep Username
```

## 3. Custom Nginx image (~2 min)

```bash
cd ~/cse644-cloud-lab/app-nginx
cat Dockerfile
docker build -t cse644-nginx-custom .
docker run -d --name nginx-custom -p 8080:80 cse644-nginx-custom
sleep 2
curl http://localhost:8080
```
Point out: custom `index.html` is served, not the default Nginx welcome page.

## 4. Python 8888 web server (~1 min)

```bash
cd ~/cse644-cloud-lab/app-python8888
docker run -d --name python-webserver -p 8888:8888 cse644-python-webserver
sleep 2
curl http://localhost:8888
```

## 5. HAProxy reverse proxy (~2 min)

Say: *"HAProxy fronting the same Nginx image, demonstrating service discovery by container name over a user-defined bridge network — no hardcoded IPs anywhere in this config."*

```bash
cd ~/cse644-cloud-lab/haproxy
cat haproxy.cfg   # show the backend references nginx-backend by name, not IP
docker compose up -d
sleep 3
curl http://localhost:8000
```

## 6. Persistent volume (~1.5 min)

```bash
docker volume create cse644-data
docker run --rm -v cse644-data:/data busybox sh -c "echo 'Persistent Hello CSE644' > /data/test.txt"
docker run --rm -v cse644-data:/data busybox cat /data/test.txt
```
Say: *"Two completely separate containers — the data survives because it lives in the volume, not either container's filesystem."*

## 7. Networking modes (~3 min)

**Bridge:**
```bash
docker network create cse644-bridge
docker run -d --name web1 --network cse644-bridge nginx
docker run -it --rm --network cse644-bridge busybox ping -c 3 web1
```

**Host:**
```bash
docker run -d --name web-host --network host nginx
curl http://localhost:80
```

**Isolated (the payoff moment):**
```bash
docker network create cse644-isolated
docker run -d --name web2 --network cse644-isolated nginx
sleep 2
docker run -it --rm --network cse644-bridge busybox ping -c 3 web2
```
Say clearly before running this last one: *"This is expected to fail — that's the point. It proves network isolation."* Don't let a failed ping look like something went wrong.

## 8. Docker Hub — the actual pushed images (~1 min)

Open in a browser (or just state it, if screen-sharing only the terminal):
- https://hub.docker.com/r/kuldeepjain1920/cse644-nginx-custom
- https://hub.docker.com/r/kuldeepjain1920/cse644-python-webserver

## 9. Wrap-up (~1 min)

Say: *"Everything shown here is documented command-by-command in the repo's docs folder, including issues hit and resolved along the way, and this same infrastructure is what Assignments 02 and 03 will build on directly — no re-platforming needed."*

Point to the repo: `github.com/kuldeepjain1920/cse644-cloud-lab`

## After the demo — cleanup and stop

```bash
cd ~/cse644-cloud-lab/haproxy
docker compose down
docker rm -f web1 web2 web-host nginx-custom python-webserver
docker network rm cse644-bridge cse644-isolated
docker volume rm cse644-data
exit
```
```bash
gcloud compute instances stop cse644-lab-vm --project=kuldeep-cse644-lab --zone=us-west1-b
```

## If something doesn't work live

- **`curl` fails right after `docker run -d`**: known race condition (container still starting) — wait 2-3 seconds and retry. Don't panic, this happened during the original build too and is noted in the runbook.
- **Port already in use / container name conflict**: a previous demo run's containers weren't cleaned up. Run `docker ps -a` and `docker rm -f <name>` for anything stale before restarting the sequence.
- **SSH connection refused right after VM start**: normal, wait another 15-20 seconds — GCP's SSH key propagation lags slightly behind "RUNNING" status.
