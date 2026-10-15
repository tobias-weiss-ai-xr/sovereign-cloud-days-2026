<!--
SPDX-FileCopyrightText: 2026 SCS Contributors
SPDX-License-Identifier: Apache-2.0
-->

# SCS-Compliant Interruption-Free Update Routine - Part 2
# Rollback Procedures & Change Documentation

**Cluster:** SCS K3s Bare-Metal (node-1, node-2, node-3)  
**Version:** 1.0  
**Date:** 2026-08-24  
**Change ID:** SCS-CHANGE-2026-001  

---

## 6. Rollback Procedures (SCS-Compliant)

### 6.1 Rollback Triggers (Automated)

| Trigger | Condition | Severity | Rollback Scope | Engagement |
|---------|-----------|----------|----------------|------------|
| **SCS-0210** | K8s version outside recency window | CRITICAL | Full cluster | Immediate |
| **SCS-0211** | Default storage class lost | CRITICAL | Storage only | Immediate |
| **SCS-0214** | Node count < 3 | CRITICAL | Full cluster | Immediate |
| **SCS-0217** | Pod Security Baseline enforcement lost | HIGH | Affected namespace | Immediate |
| **SCS-0219** | NetworkPolicy count < 37 | HIGH | Networking | Immediate |
| **SCS-0201** | CNCF conformance < 444/444 | HIGH | Full cluster | Immediate |
| **Ceph** | Health != HEALTH_OK for >5min | CRITICAL | Storage layer | Immediate |
| **API** | API server unavailable for >2min | CRITICAL | Control plane | Immediate |
| **Pods** | >10% pods not Running for >10min | HIGH | Affected nodes | Immediate |
| **etcd** | etcd cluster health failed | CRITICAL | Control plane | Immediate |

### 6.2 Automated Rollback Script

```bash
#!/bin/bash
# File: scripts/scs-rollback.sh
# Purpose: Automated SCS-compliant rollback procedure
# 
# Usage: ./scs-rollback.sh [TRIGGER] [SCOPE]
# 
# TRIGGER: SCS-0210|SCS-0211|SCS-0214|SCS-0217|SCS-0219|SCS-0201|ceph|api|pods|etcd
# SCOPE: full|node|storage|networking|control-plane

set -e

TRIGGER=${1:-manual}
SCOPE=${2:-full}
LOG_FILE="/var/log/scs/rollback-$TRIGGER-$SCOPE-$(date +%Y%m%d-%H%M%S).log"
ROLLBACK_DIR="/var/backups/scs/rollback-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$ROLLBACK_DIR"
mkdir -p /var/log/scs

echo "=== SCS Automated RollbackProcedure ===" | tee -a "$LOG_FILE"
echo "Trigger: $TRIGGER" | tee -a "$LOG_FILE"
echo "Scope: $SCOPE" | tee -a "$LOG_FILE"
echo "Start Time: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to log and execute
log_and_exec() {
    echo "EXEC: $1" | tee -a "$LOG_FILE"
    eval "$1" | tee -a "$LOG_FILE"
}

# Function to notify
notify() {
    local severity=$1
    local message=$2
    
    echo "[$severity] $message" | tee -a "$LOG_FILE"
    
    # Send to Slack if configured
    if [ -f /etc/scs/slack-webhook ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[SCS ROLLBACK] [$severity] $message\"}" \
            $(cat /etc/scs/slack-webhook) 2>/dev/null || true
    fi
    
    # Send email if configured
    if [ -f /etc/scs/email-recipients ]; then
        echo "[SCS ROLLBACK] [$severity] $message" | \
            mail -s "[SCS ROLLBACK] $severity" $(cat /etc/scs/email-recipients) 2>/dev/null || true
    fi
}

# Function to emergency drain all nodes
emergency_drain_all() {
    echo "Emergency: Draining all nodes..." | tee -a "$LOG_FILE"
    
    for NODE in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        echo "Draining $NODE..." | tee -a "$LOG_FILE"
        kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 2>&1 | tee -a "$LOG_FILE" || true
    done
}

# Function to rollback k3s
rollback_k3s() {
    local node=$1
    local target_version=$2
    
    echo "Rolling back k3s on $node to $target_version..." | tee -a "$LOG_FILE"
    
    # Uninstall k3s
    ssh "$node" "/usr/local/bin/k3s-uninstall.sh 2>&1" | tee -a "$LOG_FILE" || true
    
    # Reinstall with previous version
    ssh "$node" "curl -sfL https://get.k8s.io | INSTALL_K3S_VERSION=$target_version sh -s - server \
        --cluster-init \
        --disable traefik \
        --disable servicelb \
        --tls-san kubernetes \
        --tls-san node-1 \
        --tls-san 127.0.0.1 \
        --tls-san 198.51.100.11 \
        --tls-san 198.51.100.1 \
        --flannel-iface=vlan424 \
        --node-label topology.kubernetes.io/region=fip-zone \
        --node-label topology.kubernetes.io/zone=fip-zone-a 2>&1" | tee -a "$LOG_FILE"
    
    # Wait for API to be healthy
    local RETRIES=30
    local COUNT=0
    while [ $COUNT -lt $RETRIES ]; do
        if kubectl get --raw /healthz 2>/dev/null | grep -q "ok"; then
            echo "✅ k3s rollback on $node completed" | tee -a "$LOG_FILE"
            return 0
        fi
        sleep 10
        COUNT=$((COUNT+1))
    done
    
    echo "❌ k3s rollback on $node failed" | tee -a "$LOG_FILE"
    return 1
}

# Function to rollback Ceph
rollback_ceph() {
    local node=$1
    local target_version=$2
    
    echo "Rolling back Ceph on $node to $target_version..." | tee -a "$LOG_FILE"
    
    ssh "$node" "sudo nix-env -iA nixpkgs.ceph-$target_version --force 2>&1" | tee -a "$LOG_FILE"
    ssh "$node" "sudo systemctl restart ceph-* 2>&1" | tee -a "$LOG_FILE"
    
    echo "✅ Ceph rollback on $node completed" | tee -a "$LOG_FILE"
    return 0
}

# Function to verify rollback
verify_rollback() {
    echo "Verifying rollback..." | tee -a "$LOG_FILE"
    
    # Check k3s version
    local K8S_VERSION=$(kubectl version --short 2>/dev/null | grep 'Server Version' | awk '{print $3}')
    echo "k3s version: $K8S_VERSION" | tee -a "$LOG_FILE"
    
    # Check Ceph health
    local CEPH_HEALTH=$(kubectl exec -n backup deploy/rook-ceph-operator -- ceph health 2>/dev/null | grep -oP 'health: \K\w+' || echo "UNKNOWN")
    echo "Ceph health: $CEPH_HEALTH" | tee -a "$LOG_FILE"
    
    # Check SCS compliance
    if ./scs-pre-update-check.sh 2>/dev/null; then
        echo "✅ Rollback verification PASSED" | tee -a "$LOG_FILE"
        notify "INFO" "SCS Rollback verification PASSED - Cluster is healthy"
        return 0
    else
        echo "❌ Rollback verification FAILED" | tee -a "$LOG_FILE"
        notify "CRITICAL" "SCS Rollback verification FAILED - Manual intervention required"
        return 1
    fi
}

# Main rollback logic
echo "Starting rollback procedure..." | tee -a "$LOG_FILE"

case $SCOPE in
    "full")
        notify "CRITICAL" "Full cluster rollback initiated - Trigger: $TRIGGER"
        
        # Emergency drain all nodes
        emergency_drain_all
        
        # Save current state
        kubectl get all --all-namespaces -o yaml > "$ROLLBACK_DIR/cluster-state.yaml" 2>&1 || true
        
        # Rollback Ceph first (storage layer)
        for NODE in node-3 node-2 node-1; do
            rollback_ceph "$NODE" "18.2.8" || true
        done
        
        # Rollback workers
        for NODE in node-3 node-2; do
            rollback_k3s "$NODE" "v1.36.3+k3s1" || true
        done
        
        # Rollback control plane
        rollback_k3s "node-1" "v1.36.3+k3s1" || true
        
        # Verify
        if ! verify_rollback; then
            notify "CRITICAL" "Full rollback failed - Manual intervention required"
            exit 1
        fi
        
        notify "INFO" "Full rollback completed successfully"
        ;;

    "storage")
        notify "HIGH" "Storage rollback initiated - Trigger: $TRIGGER"
        
        for NODE in node-3 node-2 node-1; do
            rollback_ceph "$NODE" "18.2.8" || true
        done
        
        if ! verify_rollback; then
            notify "CRITICAL" "Storage rollback failed - Escalating to full rollback"
            $0 "$TRIGGER" "full"
            exit 1
        fi
        
        notify "INFO" "Storage rollback completed successfully"
        ;;

    "node")
        notify "HIGH" "Node rollback initiated - Trigger: $TRIGGER"
        
        # Rollback the problematic node (identify from logs)
        # This would need to be enhanced to identify the problematic node
        for NODE in node-3 node-2 node-1; do
            rollback_k3s "$NODE" "v1.36.3+k3s1" || true
        done
        
        if ! verify_rollback; then
            notify "CRITICAL" "Node rollback failed - Escalating to full rollback"
            $0 "$TRIGGER" "full"
            exit 1
        fi
        
        notify "INFO" "Node rollback completed successfully"
        ;;

    "control-plane")
        notify "CRITICAL" "Control plane rollback initiated - Trigger: $TRIGGER"
        
        # Rollback control plane
        rollback_k3s "node-1" "v1.36.3+k3s1" || true
        
        if ! verify_rollback; then
            notify "CRITICAL" "Control plane rollback failed - Manual intervention required"
            exit 1
        fi
        
        notify "INFO" "Control plane rollback completed successfully"
        ;;

    "manual")
        notify "INFO" "Manual rollback initiated"
        
        # Run pre-update check to see what's wrong
        echo "Running SCS compliance check..." | tee -a "$LOG_FILE"
        ./scs-pre-update-check.sh 2>&1 | tee -a "$LOG_FILE"
        
        echo "Manual rollback requires specific scope and trigger." | tee -a "$LOG_FILE"
        echo "Usage: $0 <TRIGGER> <SCOPE>" | tee -a "$LOG_FILE"
        exit 1
        ;;

    *)
        notify "ERROR" "Invalid rollback scope: $SCOPE"
        exit 1
        ;;
esac

echo "" | tee -a "$LOG_FILE"
echo "✅ Rollback procedure completed" | tee -a "$LOG_FILE"
echo "End Time: $(date)" | tee -a "$LOG_FILE"

notify "INFO" "SCS Rollback procedure completed - Trigger: $TRIGGER, Scope: $SCOPE"
```

### 6.3 Manual Rollback Procedure

#### **Full Cluster Rollback**

1. **Trigger**: Any CRITICAL SCS compliance failure
2. **Execute**:
   ```bash
   cd /opt/scs/scripts
   ./scs-rollback.sh CRITICAL full
   ```

3. **Manual Steps if Automated Fails**:
   ```bash
   # On each node:
   /usr/local/bin/k3s-uninstall.sh
   
   # Reinstall previous version on control plane:
   curl -sfL https://get.k8s.io | INSTALL_K3S_VERSION=v1.36.3+k3s1 sh -s - server \
       --cluster-init \
       --disable traefik \
       --disable servicelb \
       --tls-san kubernetes \
       --tls-san node-1 \
       --tls-san 127.0.0.1 \
       --tls-san 198.51.100.11 \
       --tls-san 198.51.100.1 \
       --flannel-iface=vlan424
   
   # Reinstall previous version on workers:
   curl -sfL https://get.k8s.io | INSTALL_K3S_VERSION=v1.36.3+k3s1 sh -s - agent \
       --server https://198.51.100.11:6443 \
       --token $(cat /var/lib/rancher/k3s/server/node-token)
   ```

4. **Verify**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ./scs-pre-update-check.sh
   ```

#### **Storage Layer Rollback**

1. **Trigger**: Ceph health != HEALTH_OK for >5 minutes
2. **Execute**:
   ```bash
   cd /opt/scs/scripts
   ./scs-rollback.sh ceph storage
   ```

3. **Manual Steps if Automated Fails**:
   ```bash
   # On each node:
   sudo nix-env -iA nixpkgs.ceph-18.2.8 --force
   sudo systemctl restart ceph-*
   
   # Verify:
   kubectl exec -n backup deploy/rook-ceph-operator -- ceph health
   ```

#### **Control Plane Rollback**

1. **Trigger**: API server unavailable for >2 minutes
2. **Execute**:
   ```bash
   cd /opt/scs/scripts
   ./scs-rollback.sh api control-plane
   ```

3. **Manual Steps if Automated Fails**:
   ```bash
   # On node-1:
   /usr/local/bin/k3s-uninstall.sh
   curl -sfL https://get.k8s.io | INSTALL_K3S_VERSION=v1.36.3+k3s1 sh -s - server \
       --cluster-init \
       --disable traefik \
       --disable servicelb
   
   # Verify API:
   kubectl get --raw /healthz
   ```

---

## 7. Change Documentation Template

### 7.1 Change Request Form

**File:** `/docs/operations/changes/SCS-CHANGE-2026-001.yaml`

```yaml
# SCS Change Request
# Change ID: SCS-CHANGE-2026-001
# Status: DRAFT | PENDING | APPROVED | REJECTED | DEFERRED | IMPLEMENTED | ROLLED_BACK

change_id: SCS-CHANGE-2026-001
cluster: scs-k3s
folder: /docs/operations/changes/SCS-CHANGE-2026-001

# Change Metadata
category: Maintenance  # Maintenance | Security | Feature | Emergency
title: "SCS-Compliant Cluster Update: K3s v1.36.4 + Ceph 18.2.15"
description: |
  Zero-downtime update of SCS KaaS cluster to latest patch versions.
  
  **Components:**
  - K3s: v1.36.3+k3s1 → v1.36.4+k3s1
  - Ceph: 18.2.8 → 18.2.15 (Quincy patch)
  
  **Impact:** Minimal application downtime during control plane update
  **SCS Compliance:** Maintains 6/6 SCS standard compliance

requester:
  name: Tobias Weiss
  role: SCS Operator
  email: tobias@tobias-weiss.org
  date: 2026-08-24T10:00:00Z

# Change Details
priority: High  # Low | Medium | High | Critical
risk_level: Medium  # Low | Medium | High | Critical

# Impact Assessment
application_impact: Minimal
  # None | Minimal | Moderate | Significant | Critical

operational_impact: Low
  # None | Low | Medium | High

downtime_expected: false
downtime_duration: PT5M  # ISO 8601 duration (e.g., PT5M = 5 minutes)
maintenance_window:
  start: 2026-08-31T02:00:00Z
  end: 2026-08-31T06:00:00Z
  duration: PT4H

# Components Affected
components:
  - name: k3s
    current_version: v1.36.3+k3s1
    target_version: v1.36.4+k3s1
    nodes: [node-1, node-2, node-3]
    
  - name: ceph
    current_version: 18.2.8
    target_version: 18.2.15
    nodes: [node-1, node-2, node-3]
    osds: 8
    
  - name: containerd
    current_version: 2.3.3
    target_version: 2.3.3 (no change)
    
  - name: docker
    current_version: 29.7.2
    target_version: 29.7.2 (no change)

# SCS Compliance
scs_compliance:
  standards_affected:
    - SCS-0210-v2  # Kubernetes Version Policy
    - SCS-0211-v2  # Default Storage Class
  
  pre_update_compliance: 6/6 PASS
  post_update_compliance: 6/6 PASS (expected)
  
  verification_required: true

# Rollback Plan
rollback:
  enabled: true
  automated: true
  script: /opt/scs/scripts/scs-rollback.sh
  
  triggers:
    - condition: SCS compliance test failure (any of 6 standards)
      severity: CRITICAL
      action: full_rollback
      
    - condition: Ceph health != HEALTH_OK for >5 minutes
      severity: CRITICAL
      action: storage_rollback
      
    - condition: API server unavailable for >2 minutes
      severity: CRITICAL
      action: control_plane_rollback
      
    - condition: >10% of application pods not Running for >10 minutes
      severity: HIGH
      action: node_rollback
  
  procedure:
    automated:
      - Execute: ./scs-rollback.sh <TRIGGER> <SCOPE>
      - Timeout: 30 minutes
      
    manual:
      - Revert to previous package versions
      - Restore from backup if needed
      - See: /docs/operations/SCS-COMPLIANT-UPDATE-ROUTINE.md Section 6

# Test Plan
test_plan:
  pre_update_tests:
    - name: SCS Compliance Check
      script: ./scs-pre-update-check.sh
      expected: 6/6 PASS
      
    - name: Ceph Health Check
      command: kubectl exec -n backup deploy/rook-ceph-operator -- ceph health
      expected: HEALTH_OK
      
    - name: Application Health Check
      script: ./verify-application-health.sh
      expected: All applications healthy
  
  post_update_tests:
    - name: SCS Compliance Verification
      script: ./scs-post-update-verification.sh
      expected: 6/6 PASS
      
    - name: CNCF Conformance Test
      command: sonobuoy run --mode=conformance
      expected: 444/444 Passed
      
    - name: Application Functionality Test
      script: ./test-application-functionality.sh
      expected: All applications functional

# Approvals
approvals:
  - role: Change Manager
    name: Tobias Weiss
    date: null
    status: pending  # pending | approved | rejected
    comments: null
    
  - role: SCS Compliance Officer
    name: Tobias Weiss
    date: null
    status: pending
    comments: null
    
  - role: CAB Chair
    name: Cluster Lead
    date: null
    status: pending
    comments: null
    
  - role: Datenschutzbeauftragter
    name: TBD
    date: null
    status: pending
    comments: null

# CAB Decision
cab_decision:
  date: null
  decision: pending  # pending | approved | rejected | deferred
  meeting_minutes: null
  quorum_met: false
  votes:
    - member: Cluster Lead
      vote: null  # approve | reject | abstain
      
    - member: Tobias Weiss
      vote: null
      
    - member: TBD (DSB)
      vote: null
      
    - member: network team
      vote: null
      
    - member: IT-Sicherheit
      vote: null

# Implementation
implementation:
  start_time: null
  end_time: null
  duration: null
  
  phases:
    - phase: 1
      name: Ceph Storage Update
      start: null
      end: null
      status: pending  # pending | in_progress | completed | failed
      script: ./update-ceph.sh
      
    - phase: 2
      name: Worker Node Update
      start: null
      end: null
      status: pending
      nodes: [node-3, node-2]
      script: ./update-worker.sh
      
    - phase: 3
      name: Control Plane Update
      start: null
      end: null
      status: pending
      node: node-1
      script: ./update-control-plane.sh
      
    - phase: 4
      name: Application Layer Update
      start: null
      end: null
      status: pending
      script: ./update-applications.sh
      
    - phase: 5
      name: SCS Compliance Verification
      start: null
      end: null
      status: pending
      script: ./scs-post-update-verification.sh

# Post-Implementation
post_implementation:
  verification_status: null  # not_started | in_progress | passed | failed
  verification_date: null
  verification_logs: null
  
  issues_encountered: []
  lessons_learned: null
  
  sign_off:
    - role: Implementer
      name: null
      date: null
      
    - role: Verifier
      name: null
      date: null

# Rollback (if applicable)
rollback:
  triggered: false
  trigger: null
  scope: null
  start_time: null
  end_time: null
  
  reason: null
  success: null
  
  rollback_logs: null
  lessons_learned: null

# Change History
change_history:
  - action: created
    author: Tobias Weiss
    timestamp: 2026-08-24T10:00:00Z
    description: Initial change request created
    
  # Additional entries added as change progresses
```

---

## 8. Monitoring & Alerting

### 8.1 Monitoring Dashboard (Prometheus + Grafana)

**SCS Compliance Dashboard:**
```yaml
# File: k8s/monitoring/scs-compliance-dashboard.yaml
# Apply: kubectl apply -f k8s/monitoring/scs-compliance-dashboard.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: scs-compliance-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  scs-compliance.json: |
    {
      "title": "SCS Compliance Monitoring",
      "panels": [
        {
          "title": "SCS-0210: Kubernetes Version",
          "type": "stat",
          "targets": [
            {
              "expr": "kube_version{type=\"server\"}",
              "instant": true
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "red", "value": 1}
            ]
          }
        },
        {
          "title": "SCS-0211: Default Storage Class",
          "type": "stat",
          "targets": [
            {
              "expr": "kube_storageclass_info{storageclass=\"ceph-rbd\"}",
              "instant": true
            }
          ]
        },
        {
          "title": "SCS-0214: Node Count",
          "type": "stat",
          "targets": [
            {
              "expr": "count(kube_node_status_condition{condition=\"Ready\",status=\"true\"})",
              "instant": true
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "orange", "value": 2},
              {"color": "red", "value": 1}
            ]
          }
        },
        {
          "title": "SCS-0217: Pod Security Baseline Namespaces",
          "type": "stat",
          "targets": [
            {
              "expr": "count(kube_namespace_labels{pod_security_enforce=\"baseline\"})",
              "instant": true
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "orange", "value": 7},
              {"color": "red", "value": 6}
            ]
          }
        },
        {
          "title": "SCS-0219: NetworkPolicy Count",
          "type": "stat",
          "targets": [
            {
              "expr": "count(kube_networkpolicy_created)",
              "instant": true
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "orange", "value": 36},
              {"color": "red", "value": 35}
            ]
          }
        },
        {
          "title": "SCS-0201: CNCF Conformance (Last Run)",
          "type": "stat",
          "targets": [
            {
              "expr": "scs_conformance_last_passed",
              "instant": true
            }
          ]
        },
        {
          "title": "Ceph Health",
          "type": "stat",
          "targets": [
            {
              "expr": "ceph_health_status",
              "instant": true
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "red", "value": 1}
            ]
          }
        },
        {
          "title": "Ceph OSD Count",
          "type": "stat",
          "targets": [
            {
              "expr": "ceph_osd_count",
              "instant": true
            }
          ]
        },
        {
          "title": "Node Status",
          "type": "table",
          "targets": [
            {
              "expr": "kube_node_status_condition{condition=\"Ready\"}",
              "instant": true
            }
          ]
        }
      ]
    }
```

### 8.2 Alert Rules (Prometheus)

```yaml
# File: k8s/monitoring/scs-alert-rules.yaml
# Apply: kubectl apply -f k8s/monitoring/scs-alert-rules.yaml

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: scs-compliance-alerts
  namespace: monitoring
  labels:
    role: alert-rules
spec:
  groups:
  - name: scs-compliance.rules
    rules:
    
    # SCS-0210: Kubernetes Version Policy
    - alert: SCS0210VersionNonCompliant
      expr: kube_version{type="server"} != 1
      for: 5m
      labels:
        severity: critical
        category: scs-compliance
        standard: SCS-0210-v2
      annotations:
        summary: "SCS-0210: Kubernetes version outside recency window"
        description: "Kubernetes version is outside the SCS recency window"
        impact: "Cluster may fail SCS certification"
        action: "Rollback to previous version or update to SCS-approved version"
    
    # SCS-0211: Default Storage Class
    - alert: SCS0211StorageClassNonCompliant
      expr: kube_storageclass_info{storageclass="ceph-rbd",is_default!="true"} == 1
      for: 5m
      labels:
        severity: critical
        category: scs-compliance
        standard: SCS-0211-v2
      annotations:
        summary: "SCS-0211: ceph-rbd is not the default storage class"
        description: "Default storage class has changed from ceph-rbd"
        impact: "Storage provisioning may fail SCS requirements"
        action: "Restablish ceph-rbd as default storage class"
    
    # SCS-0214: Node Distribution
    - alert: SCS0214NodeCountLow
      expr: count(kube_node_status_condition{condition="Ready",status="true"}) < 3
      for: 5m
      labels:
        severity: critical
        category: scs-compliance
        standard: SCS-0214-v2
      annotations:
        summary: "SCS-0214: Insufficient ready nodes (< 3)"
        description: "Number of ready nodes has dropped below 3"
        impact: "Cluster does not meet minimum node requirements"
        action: "Investigate node failures, restore nodes to ready state"
    
    # SCS-0217: Pod Security Standards
    - alert: SCS0217PodSecurityBaselineLow
      expr: count(kube_namespace_labels{pod_security_enforce="baseline"}) < 8
      for: 5m
      labels:
        severity: warning
        category: scs-compliance
        standard: SCS-0217-v1
      annotations:
        summary: "SCS-0217: Pod Security Baseline enforcement dropped (< 8 namespaces)"
        description: "Number of namespaces with baseline Pod Security has dropped"
        impact: "Security posture degraded"
        action: "Investigate namespace configuration, re-enable baseline enforcement"
    
    # SCS-0219: Networking
    - alert: SCS0219NetworkPolicyCountLow
      expr: count(kube_networkpolicy_created) < 37
      for: 5m
      labels:
        severity: warning
        category: scs-compliance
        standard: SCS-0219-v1
      annotations:
        summary: "SCS-0219: NetworkPolicy count below minimum (37)"
        description: "Number of NetworkPolicies has dropped below 37"
        impact: "Network isolation may be compromised"
        action: "Investigate missing NetworkPolicies, redeploy as needed"
    
    # SCS-0201: CNCF Conformance
    - alert: SCS0201ConformanceFailed
      expr: scs_conformance_last_passed == 0
      for: 5m
      labels:
        severity: critical
        category: scs-compliance
        standard: SCS-0201-v1
      annotations:
        summary: "SCS-0201: CNCF conformance test failed"
        description: "Last CNCF conformance test did not pass"
        impact: "Cluster does not meet Kubernetes conformance requirements"
        action: "Investigate conformance failures, remediate issues"
    
    # Ceph Health
    - alert: CephHealthCritical
      expr: ceph_health_status{severity="HEALTH_WARN"} == 1 or ceph_health_status{severity="HEALTH_ERR"} == 1
      for: 5m
      labels:
        severity: critical
        category: storage
      annotations:
        summary: "Ceph cluster health is degraded"
        description: "Ceph health status is {{ \$value }} (not HEALTH_OK)"
        impact: "Storage operations may be affected"
        action: "Investigate Ceph health, check OSDs, MONs, MGRs"
    
    # API Server Health
    - alert: APIServerUnavailable
      expr: up{job="apiserver"} == 0
      for: 2m
      labels:
        severity: critical
        category: control-plane
      annotations:
        summary: "Kubernetes API server is unavailable"
        description: "API server has been down for more than 2 minutes"
        impact: "Cluster management operations impossible"
        action: "Investigate control plane, check API server logs"
    
    # Pod Status
    - alert: HighPodFailureRate
      expr: (sum(kube_pod_status_phase{phase="Running"} or kube_pod_status_phase{phase="Succeeded"}) by (namespace) / on(namespace) count(kube_pod_status_phase) by (namespace)) < 0.9
      for: 10m
      labels:
        severity: warning
        category: applications
      annotations:
        summary: "High pod failure rate in namespace {{ \$labels.namespace }}"
        description: "Less than 90% of pods are in Running/Succeeded state in namespace {{ \$labels.namespace }}"
        impact: "Application functionality may be degraded"
        action: "Investigate failing pods, check logs, restart as needed"
    
    # Node Status
    - alert: NodeNotReady
      expr: kube_node_status_condition{condition="Ready",status="false"} == 1
      for: 5m
      labels:
        severity: warning
        category: nodes
      annotations:
        summary: "Node {{ \$labels.node }} is not ready"
        description: "Node {{ \$labels.node }} has been in NotReady state for more than 5 minutes"
        impact: "Applications may be scheduled away from this node"
        action: "Investigate node status, check kubelet, restart if needed"
```

---

## 9. Implementation Checklist

### 9.1 Pre-Implementation Checklist

- [ ] **Change Request Created**
  - [ ] File: `/docs/operations/changes/SCS-CHANGE-2026-001.yaml`
  - [ ] All metadata fields completed
  - [ ] SCS compliance sections filled
  
- [ ] **CAB Approval Obtained**
  - [ ] All required members approved
  - [ ] Quorum met (minimum 3 members)
  - [ ] Meeting minutes documented
  
- [ ] **Scripts Prepared**
  - [ ] `scs-pre-update-check.sh` tested and working
  - [ ] `update-ceph.sh` tested in staging
  - [ ] `update-worker.sh` tested in staging
  - [ ] `update-control-plane.sh` reviewed
  - [ ] `update-applications.sh` reviewed
  - [ ] `scs-post-update-verification.sh` tested and working
  - [ ] `scs-rollback.sh` tested
  
- [ ] **Backup Verified**
  - [ ] K8up backups completed
  - [ ] Backup restorability tested
  - [ ] Off-cluster mirror verified
  
- [ ] **Monitoring Configured**
  - [ ] SCS compliance dashboard deployed
  - [ ] Alert rules deployed
  - [ ] Notification channels tested
  
- [ ] **Stakeholders Notified**
  - [ ] Maintenance window communicated (48h in advance)
  - [ ] Status page updated
  - [ ] Contact information provided
  
- [ ] **Rollback Procedure Verified**
  - [ ] Rollback scripts tested
  - [ ] Rollback documentation reviewed
  - [ ] Rollback contact list confirmed
  
- [ ] **Go/No-Go Meeting Held**
  - [ ] Final review of all preparations
  - [ ] Risk assessment confirmed
  - [ ] Go/No-Go decision documented

### 9.2 Implementation Checklist

**Phase 1: Ceph Storage Update (T+00:00 - T+00:45)**
- [ ] Pre-update SCS compliance check passed
- [ ] Node node-3 drained and updated
- [ ] Ceph health verified on node-3
- [ ] Node node-3 uncordoned and Ready
- [ ] Node node-2 drained and updated
- [ ] Ceph health verified on node-2
- [ ] Node node-2 uncordoned and Ready
- [ ] Node node-1 drained and updated
- [ ] Ceph health verified on node-1
- [ ] Node node-1 uncordoned and Ready
- [ ] Full Ceph cluster verification passed

**Phase 2: Worker Node Update (T+00:45 - T+01:30)**
- [ ] Worker node-3 drained
- [ ] k3s updated on node-3
- [ ] k3s-agent service verified on node-3
- [ ] Node node-3 uncordoned
- [ ] Node node-3 Ready
- [ ] Pod Security Standards verified
- [ ] SCS compliance quick check passed
- [ ] Worker node-2 drained
- [ ] k3s updated on node-2
- [ ] k3s-agent service verified on node-2
- [ ] Node node-2 uncordoned
- [ ] Node node-2 Ready
- [ ] Pod Security Standards verified
- [ ] SCS compliance quick check passed

**Phase 3: Control Plane Update (T+01:30 - T+02:00)**
- [ ] k3s data backed up
- [ ] Control plane node cordoned
- [ ] k3s updated on node-1
- [ ] API server healthy
- [ ] Control plane uncordoned
- [ ] All nodes Ready
- [ ] Rollback triggers monitored for 5 minutes
- [ ] Control plane health verified
- [ ] SCS compliance quick check passed

**Phase 4: Application Layer Update (T+02:00 - T+02:30)**
- [ ] ArgoCD updated
- [ ] ArgoCD rollout verified
- [ ] ArgoCD applications synced
- [ ] Application health verified

**Phase 5: SCS Compliance Verification (T+02:30 - T+03:00)**
- [ ] Full SCS compliance check passed
- [ ] CNCF conformance test passed (444/444)
- [ ] All alerts silent
- [ ] Cluster health confirmed

### 9.3 Post-Implementation Checklist

- [ ] **Verification Completed**
  - [ ] SCS compliance: 6/6 standards PASS
  - [ ] Ceph health: HEALTH_OK
  - [ ] All nodes: Ready
  - [ ] All pods: Running or Succeeded
  - [ ] Applications: Functional
  
- [ ] **Documentation Updated**
  - [ ] Change request updated with actual times
  - [ ] Implementation phases documented
  - [ ] Any issues encountered documented
  - [ ] Lessons learned documented
  
- [ ] **Stakeholders Notified**
  - [ ] Maintenance window completion announced
  - [ ] Any downtime explained
  - [ ] Status page updated
  
- [ ] **Post-Implementation Review**
  - [ ] Review meeting scheduled
  - [ ] Review meeting held
  - [ ] Review minutes documented
  - [ ] Action items identified
  
- [ ] **Sign-Off Obtained**
  - [ ] Implementer sign-off
  - [ ] Verifier sign-off
  - [ ] Change Manager sign-off

---

## 10. File Structure

```
/docs/operations/
├── SCS-COMPLIANT-UPDATE-ROUTINE.md          # This document (Part 1)
├── SCS-COMPLIANT-UPDATE-ROUTINE-PART2.md     # This document (Part 2)
│
├── changes/
│   └── SCS-CHANGE-2026-001.yaml             # Change request for this update
│
└── scripts/
    ├── scs-pre-update-check.sh              # Pre-update compliance check
    ├── update-ceph.sh                        # Ceph update procedure
    ├── update-worker.sh                      # Worker node update procedure
    ├── update-control-plane.sh              # Control plane update procedure
    ├── update-applications.sh                # Application layer update procedure
    ├── scs-post-update-verification.sh      # Post-update compliance verification
    └── scs-rollback.sh                       # Automated rollback procedure

/k8s/monitoring/
├── scs-compliance-dashboard.yaml           # Grafana dashboard
└── scs-alert-rules.yaml                    # Prometheus alerting rules

/k8s/
└── namespaces.yaml                          # Pod Security Standards configuration
```

---

## 11. References

### 11.1 SCS Standards
- [SCS-0210-v2: K8s Version Policy](https://docs.scs.community/standards/scs-0210-v2-k8s-version-policy)
- [SCS-0211-v2: Default Storage Class](https://docs.scs.community/standards/scs-0211-v2-kaas-default-storage-class)
- [SCS-0214-v2: Node Distribution](https://docs.scs.community/standards/scs-0214-v2-k8s-node-distribution)
- [SCS-0217-v1: Cluster Hardening](https://docs.scs.community/standards/scs-0217-v1-cluster-hardening)
- [SCS-0219-v1: KaaS Networking](https://docs.scs.community/standards/scs-0219-v1-kaas-networking)
- [SCS-0201-v1: CNCF Conformance](https://docs.scs.community/standards/scs-0201-v1-cncf-conformance)

### 11.2 Internal Documentation
- [SCS KaaS Compliance Report](scs-kaas-compliance-report.md)
- [SCS Contribution Artifacts](scs-contribution-artifacts.md)
- [SCS.md](SCS.md)

---

## 12. Contact Information

| Role | Name | Email | Phone |
|------|------|-------|-------|
| **SCS Operator** | Tobias Weiss | tobias@tobias-weiss.org | [phone] |
| **IT Management** | Cluster Lead | cluster-lead@example.edu | [phone] |
| **Datenschutzbeauftragter** | TBD | dpo@example.edu | [phone] |
| **IT-Sicherheit** | Stabsstelle | security@example.edu | [phone] |

**Emergency Contact:**
- **Primary:** Tobias Weiss - tobias@tobias-weiss.org
- **Secondary:** Cluster Lead - cluster-lead@example.edu

---

*Document created: 2026-08-24*  
*Last updated: 2026-08-24*  
*Version: 1.0*  
*Change ID: SCS-CHANGE-2026-001*
