# CSE636 VM Migration Runbook — "My First Project" → cse636-capstone-iac

Context: the default auto-created GCP project (`project-8c1a75fc-3921-4d5c-ae0`,
"My First Project") held `cse636-lab-vm` (CSE636 coursework: Docker, Jenkins,
full weeks 0-7 material) in `us-central1-a`. This billing account has a
project-linking quota of 3 (not the standard 5), which blocked creating and
billing-linking the new `kuldeep-cse644-lab` project. Rather than requesting
a quota increase, the old default project was retired by migrating its VM
into the existing `cse636-capstone-iac` project (also freeing it from
`us-central1`, which had hit capacity issues previously), then deleting the
now-empty old project to free a billing slot.

## 1. Create an image from the source VM's boot disk

VM was already stopped (`TERMINATED`) before this step — required for a
consistent disk image.

```
gcloud compute images create cse636-lab-vm-image \
  --source-disk=cse636-lab-vm \
  --source-disk-zone=us-central1-a \
  --project=project-8c1a75fc-3921-4d5c-ae0
```

Verify:
```
gcloud compute images list --project=project-8c1a75fc-3921-4d5c-ae0 --no-standard-images
```

## 2. Grant cross-project image access

Not strictly required when both projects are owned by the same account
(gcloud created the VM in step 3 without needing this), but good practice
for clarity/explicitness, and necessary if source/destination projects ever
belong to different identities:

```
gcloud compute images add-iam-policy-binding cse636-lab-vm-image \
  --project=project-8c1a75fc-3921-4d5c-ae0 \
  --member="user:kuldeepjainphotos@gmail.com" \
  --role="roles/compute.imageUser"
```

## 3. Create the new VM in the destination project (new region)

Moved from `us-central1-a` to `us-west1-b` in the same step:

```
gcloud compute instances create cse636-lab-vm \
  --project=cse636-capstone-iac \
  --zone=us-west1-b \
  --machine-type=e2-small \
  --image=projects/project-8c1a75fc-3921-4d5c-ae0/global/images/cse636-lab-vm-image
```

Verify:
```
gcloud compute instances list --project=cse636-capstone-iac
```

## 4. Verify data integrity

```
gcloud compute ssh cse636-lab-vm --project=cse636-capstone-iac --zone=us-west1-b
```

Inside the VM:
```
ls -la ~
docker ps -a
docker images
df -h /
```

Confirmed: full CSE636/ course tree, cse636-coursework/, example-voting-app/,
lab-data/, running cstu-jenkins container, and images all present and intact.

## 5. Stop the new VM (not needed running continuously)

```
gcloud compute instances stop cse636-lab-vm --project=cse636-capstone-iac --zone=us-west1-b
```

## 6. Confirm no other resources exist in the destination project

```
gcloud storage buckets list --project=cse636-capstone-iac
gcloud iam service-accounts list --project=cse636-capstone-iac
```

(Bucket from earlier capstone Terraform work was empty/already destroyed;
`terraform-iac-demo` service account confirmed present as expected.)

## 7. Delete the old project (frees a billing-account project slot)

```
gcloud projects delete project-8c1a75fc-3921-4d5c-ae0
```

30-day undo window: `gcloud projects undelete project-8c1a75fc-3921-4d5c-ae0`
(image and original VM inside it are effectively gone in practice — the
working copy in cse636-capstone-iac is the one to rely on going forward).

## 8. Link billing for the new CSE644 lab project

```
gcloud billing projects link kuldeep-cse644-lab --billing-account=0145B6-36A787-56BB0E
```

## Result

- `cse636-lab-vm` now lives in `cse636-capstone-iac`, zone `us-west1-b`,
  stopped, data verified intact.
- `project-8c1a75fc-3921-4d5c-ae0` deleted.
- `kuldeep-cse644-lab` created and billing-linked, ready for the CSE644
  single-VM Terraform build.

## 9. Post-migration verification of kuldeep-cse644-lab (new project)

Before starting the CSE644 Terraform build, verified state from scratch
rather than assuming anything carried over cleanly:

```
gcloud config list
gcloud billing projects describe kuldeep-cse644-lab
gcloud services list --enabled --project=kuldeep-cse644-lab | grep compute
gcloud compute instances list --project=kuldeep-cse644-lab
gcloud compute networks list --project=kuldeep-cse644-lab
```

All confirmed clean: billing enabled, Compute API enabled, config pointed
at project=kuldeep-cse644-lab/region=us-west1/zone=us-west1-b, zero
instances. GCP had auto-created a `default` VPC network (standard on
project creation with Compute API enabled) with its usual auto-generated
firewall rules (`default-allow-icmp`, `default-allow-internal`,
`default-allow-rdp`, `default-allow-ssh`) and routes.

## 10. Removed the auto-created default VPC (kept the project to only what
Terraform manages)

Confirmed no dependencies first (no instances on it, only auto-generated
firewall rules/routes, no custom resources):

```
gcloud compute instances list --project=kuldeep-cse644-lab --filter="networkInterfaces.network:default"
gcloud compute firewall-rules list --project=kuldeep-cse644-lab --filter="network:default"
gcloud compute routes list --project=kuldeep-cse644-lab --filter="network:default"
```

Then deleted the firewall rules (required before the network itself can be
deleted; routes are auto-removed with the network):

```
gcloud compute firewall-rules delete default-allow-icmp default-allow-internal default-allow-rdp default-allow-ssh --project=kuldeep-cse644-lab --quiet
gcloud compute networks delete default --project=kuldeep-cse644-lab
```

Verified empty afterward:

```
gcloud compute networks list --project=kuldeep-cse644-lab
```

Note: this only ever targeted `kuldeep-cse644-lab`'s own `default` VPC —
entirely separate from and with zero effect on `cse636-lab-vm` or its
network in `cse636-capstone-iac`.
