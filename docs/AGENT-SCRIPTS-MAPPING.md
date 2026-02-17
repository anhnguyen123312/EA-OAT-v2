# Agent → Scripts Mapping

Quick reference cho việc sử dụng scripts trong workflow của từng agent.

---

## 📊 Scripts by Agent

### **Em (Team Lead)**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before work | Get latest from all agents |
| `git_workflow.sh sync "msg"` | After work | Commit optimization tasks |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Read results, create OPTIMIZATION_TASK.md
cat results/*/journal.md
nano tasks/OPTIMIZATION_TASK.md
nano brain/optimization_log.md

# END
./scripts/git_workflow.sh sync "Em: Iteration 2 optimization task - add session filters"
```

---

### **Researcher**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before research | Get latest journals, logs |
| `git_workflow.sh sync "msg"` | After research | Commit research findings |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Research, write findings
cat brain/optimization_log.md
cat experience/backtest_journal.md
nano brain/strategy_research.md

# END
./scripts/git_workflow.sh sync "Researcher: PA+SR confluence research complete"
```

---

### **PM (Project Manager)**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before planning | Get latest research |
| `git_workflow.sh sync "msg"` | After planning | Commit implementation plan |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Read research, create plan
cat brain/strategy_research.md
nano brain/implementation_plan.md

# END
./scripts/git_workflow.sh sync "PM: Implementation plan v1 - SMC with confluence"
```

---

### **Technical Analyst**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before specs | Get latest plan |
| `validate_config.sh` | When creating config | Validate .ini format |
| `git_workflow.sh sync "msg"` | After specs | Commit CODER_TASK |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Read plan, create specs
cat brain/implementation_plan.md
cat experience/mql5_patterns.md
nano tasks/CODER_TASK.md

# Validate config template
./scripts/validate_config.sh config/active/autobacktest.ini

# END
./scripts/git_workflow.sh sync "Technical Analyst: CODER_TASK v1 ready for review"
```

---

### **Reviewer**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before review | Get all Phase 1 outputs |
| `git_workflow.sh sync "msg"` | After review | Commit review log |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Review all outputs
cat brain/strategy_research.md
cat brain/implementation_plan.md
cat tasks/CODER_TASK.md
nano brain/review_log.md

# END - if APPROVED
./scripts/git_workflow.sh sync "Reviewer: Phase 1 APPROVED - proceed to coding"

# END - if REJECTED
./scripts/git_workflow.sh sync "Reviewer: Phase 1 REJECTED - PM needs to fix parameter ranges"
```

---

### **Coder** ⭐ (Most Scripts)

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before work | Get latest task, brain, experience |
| `compile_ea.sh` | After coding | Compile EA source |
| `validate_config.sh` | Before backtest | Validate config |
| `run_backtest_native.sh` | Run backtest | Launch MT5 |
| `collect_backtest_results.sh` | After backtest | Collect CSV + logs |
| `restore_mt5_login.sh` | When login lost | Restore credentials |
| `git_workflow.sh sync "msg"` | After results | Commit code + results |

**Full Workflow:**
```bash
# ===== STEP 1: SETUP =====
./scripts/git_workflow.sh pull

# Read task
cat tasks/CODER_TASK.md
cat brain/implementation_plan.md
cat experience/compile_issues.md

# Mark IN_PROGRESS
nano tasks/CODER_TASK.md  # Status: IN_PROGRESS

# ===== STEP 2: IMPLEMENT =====
nano code/experts/AdvancedEA.mq5

# ===== STEP 3: COMPILE =====
./scripts/compile_ea.sh AdvancedEA

# If errors:
#   - Read error from output
#   - Update experience/compile_issues.md
#   - Fix code
#   - Re-run compile
#   - Repeat until 0 errors

# ===== STEP 4: VALIDATE CONFIG =====
./scripts/validate_config.sh config/active/autobacktest.ini

# If errors:
#   - Fix config
#   - Re-validate

# ===== STEP 5: BACKTEST =====
./scripts/run_backtest_native.sh

# Wait for MT5 to complete (ShutdownTerminal=1)
# Or close manually if needed

# ===== STEP 6: COLLECT RESULTS =====
./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5

# Check CSV exists
ls -la results/2026-02-17_AdvancedEA_XAUUSD_M5.csv

# ===== STEP 7: UPDATE EXPERIENCE =====
# If new compile issues found:
nano experience/compile_issues.md

# If new runtime issues:
nano experience/backtest_setup.md

# ===== STEP 8: MARK DONE =====
nano tasks/CODER_TASK.md  # Status: DONE
mkdir -p tasks/archive
mv tasks/CODER_TASK.md tasks/archive/2026-02-17_AdvancedEA_v1.md

# ===== STEP 9: SYNC =====
./scripts/git_workflow.sh sync "Coder: AdvancedEA v1 backtest complete"
```

**Troubleshooting:**

```bash
# Login lost for Model=4 (real ticks)
./scripts/restore_mt5_login.sh

# Re-compile after fix
./scripts/compile_ea.sh AdvancedEA

# Check Wine paths
ls -la "$WINEPREFIX/drive_c/users/"  # Find correct username for CSV path
```

---

### **Backtester**

| Script | When | Purpose |
|--------|------|---------|
| `git_workflow.sh pull` | Before analysis | Get latest results |
| `git_workflow.sh sync "msg"` | After analysis | Commit journal |

**Workflow:**
```bash
# START
./scripts/git_workflow.sh pull

# Work: Analyze results, classify trades
cat results/2026-02-17_AdvancedEA_XAUUSD_M5.csv
cat brain/implementation_plan.md
cat code/experts/AdvancedEA.mq5

# Write journal
nano results/2026-02-17_AdvancedEA_journal.md

# Update persistent lessons
nano experience/backtest_journal.md

# END
./scripts/git_workflow.sh sync "Backtester: Iteration 1 - WR 85%, FALSE_SIGNAL root cause identified"
```

---

## 🔄 Standard Workflow Pattern

**ALL agents follow this pattern:**

```bash
# 1. START: Pull latest
./scripts/git_workflow.sh pull

# 2. READ: Context from brain/ and experience/
cat brain/**
cat experience/**

# 3. WORK: Do agent-specific work
nano [output files]

# 4. END: Sync changes
./scripts/git_workflow.sh sync "Agent: Work summary"
```

---

## 📋 Commit Message Format

**Template:**
```
Agent: Brief description (50 chars max)

Optional longer explanation if needed.
```

**Examples:**

```
Em: Iteration 2 optimization task created
Researcher: PA+SR confluence framework research
PM: Implementation plan v1 with DCA strategy
Technical Analyst: CODER_TASK with MQL5 specs
Reviewer: Phase 1 approved, 0 issues found
Coder: SimpleEA v1 compiled and backtested
Backtester: Iteration 1 journal - root cause analysis
```

---

## 🚨 Common Issues

### Permission Denied

```bash
chmod +x scripts/*.sh
```

### Git Conflicts

```bash
./scripts/git_workflow.sh pull
# Resolve conflicts in editor
git add .
./scripts/git_workflow.sh commit "Resolved merge conflicts"
./scripts/git_workflow.sh push
```

### Scripts Not Found

```bash
# Run from project root
cd /Volumes/Data/Git/EA-OAT-v2
./scripts/git_workflow.sh pull
```

---

## 📚 Documentation

- **Script Details:** `scripts/README.md`
- **Coder Workflow:** `skills/coder-worker/SKILL.md`
- **Technical Issues:** `experience/compile_issues.md`
- **Config Gotchas:** `experience/backtest_setup.md`
