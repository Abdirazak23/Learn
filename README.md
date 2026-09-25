[Developer Commits Code]
       │
       ▼
1. Pull Request (CI Phase)
       ├─ Pre-Commit Hooks (Workstation)
       ├─ Fast Unit Tests (<10m Execution)
       └─ Security & Static Analysis Gates
       │
       ▼
2. Build & Package (Immutability Gate)
       ├─ Compile & Produce Signed Artifact (SHA Tagged)
       └─ Generate SBOM (Supply Chain Compliance)
       │
       ▼
3. CD Phase: Staging Slot Deployment (Data Isolation Gate)
       ├─ Execute Non-Breaking DB Migrations (Expand Phase)
       ├─ Deploy Artifact + Inject Key Vault References
       ├─ Deep Health Probe (/healthz - DB/Cache check)
       └─ Synthetic Integration Tests
       │
       ▼
4. Production Swap & Automated Resiliency
       ├─ App Initialization (Warm-Up Routine)
       ├─ Instant VIP Swap (App Settings Verification)
       ├─ Post-Swap Health Gate
       └─ Fallback: Auto-Rollback Engine (10-Second Recovery)
