# Network Configuration & FIP Assignment

**Scope:** SCS bare-metal K3s cluster (node-1/07/08), university data centre / IT operations.
**Status:** As recorded 2026-08-13; verify live via `kubectl get svc -A` (see below).

## Networks

| Network | Subnet | Interface/VLAN | Purpose |
|---------|--------|----------------|---------|
| mgmt-zone mgmt | 192.0.2.0/24 | `ens3f0` untagged | Node mgmt (SSH only), TrueNAS `.2`, same L2 as fip-zone |
| fip-zone (FIP) | 203.0.113.0/24 | `ens3f0` VLAN 3 | Public services (FIP pool) |
| Internal | 198.51.100.0/18 | `vlan424` | K3s node IPs `.6/.7/.8` |
| K3s pods | 10.42.0.0/16 | Flannel VXLAN (8472/UDP) | Pod IPs |
| K3s services | 10.43.0.0/16 | — | ClusterIP/NodePort |

## FIP Pool

- **16 FIPs from fip-zone:** `203.0.113.181 – 203.0.113.196`
- Reachable on same L2 as mgmt-zone (no router hop).
- **Assignment mechanism:** MetalLB (L2 mode) assigns a FIP to each `LoadBalancer`-type Service. HTTP(S) services behind a HAProxy ingress for which the FIP is `loadBalancerIP` of the `haproxy-ingress` Service (`.181`).

## Current FIP Assignments

| FIP | Service | Notes |
|-----|---------|-------|
| 203.0.113.181 | haproxy-ingress | Front for `cloud/mail/id/chat/matrix/admin.home.openedusuite.org` |
| 203.0.113.182 | argocd | ArgoCD UI/API |
| 203.0.113.183 | stalwart (mail) | 25/587/465/143/993/8080 |
| 203.0.113.184 | dkimpy | DKIM signing |
| 203.0.113.185 | postfix | SMTP relay |
| 203.0.113.186 | openldap | 389/636 |

Remaining FIPs (`.187–.196`) are unassigned in the K3s stack.

> **Superseded history:** the earlier OpenStack/OVN test-VM phase used `.181` (test-vm), `.182` (test-vm5), `.184` (test-vm-new), `.196` (SNAT), plus manual ARP workarounds for an OVN 25.03.1 bug. The bare-metal K3s deployment replaced this; those VM assignments no longer apply.

## Verify Live State

```bash
# 1. Services and their assigned external IPs
kubectl --context scs-k3s get svc -A -o wide | grep -E 'EXTERNAL-IP|203.0.113'

# 2. MetalLB pool config (if needed)
kubectl -n metallb-system get ipaddresspool, l2advertisement
```

## Notes / Caveats

- Firewall (`SCS-FIREWALL` chain on `ens3f0`) permits 80/443/22/5001/31080/31443/123/ICMP and drops 6443/10250/8472 on the mgmt interface.
- mgmt-zone is **not** used for FIPs — management traffic only, via SSH tunnel (`~/.kube/start-scs-tunnel.sh`).
