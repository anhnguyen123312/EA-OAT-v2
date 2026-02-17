# Scripts - Automation Tools for EA-OAT-v2

Bộ scripts tự động hóa workflow cho 6-agent team.

---

## 📋 Scripts Overview

| Script | Purpose | Used By | When to Use |
|--------|---------|---------|-------------|
| **git_workflow.sh** | Git pull/commit/push automation | ALL agents | Before & after work |
| **validate_config.sh** | Validate MT5 .ini config | Technical Analyst, Coder | Before backtest |
| **compile_ea.sh** | Compile EA from source | Coder | After implementing code |
| **run_backtest_native.sh** | Launch MT5 backtest (preserves login) | Coder | Run backtest |
| **collect_backtest_results.sh** | Collect CSV + logs after backtest | Coder | After backtest completes |
| **restore_mt5_login.sh** | Restore MT5 credentials | Coder | When login session lost |

---

## 🔄 Git Workflow Script

**File:** `git_workflow.sh`
**Agents:** ALL (Em, Researcher, PM, Technical Analyst, Reviewer, Coder, Backtester)

### Commands

```bash
# Pull latest changes (BEFORE work)
./scripts/git_workflow.sh pull

# Commit changes (AFTER work)
./scripts/git_workflow.sh commit "Agent: Description of work"

# Push to remote
./scripts/git_workflow.sh push

# Full sync: pull + commit + push
./scripts/git_workflow.sh sync "Agent: Description of work"

# Check status
./scripts/git_workflow.sh status
```

### Integration into Agent Workflows

**EVERY agent MUST:**
1. **START work:** `./scripts/git_workflow.sh pull`
2. **END work:** `./scripts/git_workflow.sh sync "Agent: Work summary"`

**Commit Message Format:**
```
Agent Role: Brief description

Examples:
- "Researcher: Initial PA+SR research complete"
- "PM: Implementation plan v1 ready for review"
- "Technical Analyst: CODER_TASK.md with confluence specs"
- "Reviewer: Phase 1 approved, no issues found"
- "Coder: AdvancedEA v1 compiled and backtested"
- "Backtester: Iteration 1 journal - WR 85%, needs filters"
- "Em: Iteration 2 optimization task created"
```

---

## ✅ Config Validator

**File:** `validate_config.sh`
**Agents:** Technical Analyst (before specs), Coder (before backtest)

### Purpose
Validate MT5 backtest .ini config for common errors.

### Usage

```bash
./scripts/validate_config.sh config/active/autobacktest.ini
```

### Checks

| Check | Error Type | Impact |
|-------|------------|--------|
| Expert= has path prefix | ❌ ERROR | Backtest fails "Expert not found" |
| Missing Symbol= | ❌ ERROR | Backtest fails |
| Invalid Period= | ⚠️ WARNING | May use wrong timeframe |
| Invalid Model= (not 0-4) | ❌ ERROR | Backtest fails |
| Invalid date format | ❌ ERROR | Backtest fails |
| Missing Deposit= | ⚠️ WARNING | Uses default |
| ShutdownTerminal≠1 | ⚠️ WARNING | Manual close needed |
| Model=4 but no Login/Server | ⚠️ WARNING | Real ticks won't download |

### Integration

**Technical Analyst:** Add to CODER_TASK.md
```markdown
## Backtest Configuration Validation

Before running backtest, validate config:
```bash
./scripts/validate_config.sh config/active/autobacktest.ini
```

Fix any errors before proceeding.
```

**Coder:** Run before backtest
```bash
# Step 1: Validate config
./scripts/validate_config.sh config/active/autobacktest.ini
# If errors: fix config, re-validate
# If success: proceed to backtest
```

---

## 🔨 EA Compiler

**File:** `compile_ea.sh`
**Agent:** Coder

### Purpose
Compile EA source (.mq5) to executable (.ex5) via Wine/MT5.

### Usage

```bash
./scripts/compile_ea.sh EAName

# Example
./scripts/compile_ea.sh SimpleEA
./scripts/compile_ea.sh AdvancedEA
```

### What It Does

1. ✅ Validates source exists at `code/experts/[EAName].mq5`
2. 📋 Copies source to MT5 Experts folder
3. 📦 Copies includes to MT5 Include folder (if any)
4. 🔨 Runs Wine metaeditor64.exe compiler
5. 📊 Parses log for errors/warnings
6. ✅ Reports success with .ex5 size OR errors

### Output

**Success:**
```
[5/5] ✅ SUCCESS: 0 errors, 2 warning(s)

Compiled binary: SimpleEA.ex5 (45123 bytes)

Done. Ready for backtest.
```

**Failure:**
```
[5/5] ❌ FAILED: 3 error(s), 1 warning(s)

=== Compile Log ===
error 256: undeclared identifier 'STAT_WIN_TRADES'
error 115: variable 'handle' not defined
...

Compile log saved to: [path]
Update experience/compile_issues.md with this error
```

### Integration into Coder Workflow

**Replace manual compile steps with:**
```bash
# OLD (manual, error-prone)
cp code/experts/SimpleEA.mq5 "$MT5_BASE/MQL5/Experts/"
cd "$MT5_BASE"
wine64 metaeditor64.exe /compile:"MQL5\\Experts\\SimpleEA.mq5" /log
cat "$MT5_BASE/MQL5/Experts/SimpleEA.log"

# NEW (automated, validated)
./scripts/compile_ea.sh SimpleEA
```

**On compile failure:**
1. Read error from script output
2. Update `experience/compile_issues.md`
3. Fix code
4. Re-run `./scripts/compile_ea.sh EAName`
5. Repeat until 0 errors

---

## 🚀 Backtest Launcher

**File:** `run_backtest_native.sh`
**Agent:** Coder

### Purpose
Launch MT5 native app to run backtest (preserves login session).

### Usage

```bash
./scripts/run_backtest_native.sh
```

### What It Does

1. 📋 Copies `config/active/autobacktest.ini` to MT5 folder
2. 🚀 Launches MT5 native app with config
3. ⏳ Waits for manual backtest start (if MT5 already running)
4. 📊 Shows how to retrieve results after completion

### Notes

- **Login Preservation:** Uses native app instead of Wine terminal to keep login session
- **Manual Start:** May require manual Strategy Tester activation (Ctrl+R)
- **Model=4 (Real Ticks):** Requires valid Login/Server in config

### Integration

**After compile success:**
```bash
# Step 1: Validate config
./scripts/validate_config.sh config/active/autobacktest.ini

# Step 2: Run backtest
./scripts/run_backtest_native.sh

# Wait for MT5 to complete (ShutdownTerminal=1) or close manually

# Step 3: Collect results
./scripts/collect_backtest_results.sh EAName Symbol Period
```

---

## 📊 Results Collector

**File:** `collect_backtest_results.sh`
**Agent:** Coder

### Purpose
Collect CSV results + logs after backtest completes.

### Usage

```bash
./scripts/collect_backtest_results.sh EAName Symbol Period

# Example
./scripts/collect_backtest_results.sh SimpleEA XAUUSD M5
./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5
```

### What It Does

1. ✅ Validates CSV exists at Wine Common/Files path
2. 📋 Copies CSV to `results/YYYY-MM-DD_EAName_Symbol_Period.csv`
3. 📝 Copies tester log to `results/logs/YYYY-MM-DD_EAName.log` (if exists)
4. 📊 Displays quick summary (Win Rate, Total Trades, Net Profit, Max DD)

### Output

**Success:**
```
[4/4] Results Summary:

  Win Rate:      85.50
  Total Trades:  197
  Net Profit:    4523.90
  Max DD %:      8.45

Done. Results saved to results/

Next steps:
1. Backtester reads: results/2026-02-17_SimpleEA_XAUUSD_M5.csv
2. Backtester writes: results/2026-02-17_SimpleEA_journal.md
3. git add + commit + push
```

**Failure:**
```
ERROR: CSV not found at: [path]

Possible causes:
1. Backtest didn't complete
2. OnTester() didn't export CSV
3. Wrong Wine username (check actual path)

Try: ls -la "[Common/Files path]"
```

### Integration

**After backtest completes:**
```bash
# Collect results
./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5

# Update experience if needed
nano experience/compile_issues.md  # Add any runtime issues

# Sync to git
./scripts/git_workflow.sh sync "Coder: AdvancedEA backtest complete, results in results/"
```

---

## 🔐 Login Restorer

**File:** `restore_mt5_login.sh`
**Agent:** Coder

### Purpose
Restore MT5 login credentials from backup when session is lost.

### Usage

```bash
./scripts/restore_mt5_login.sh
```

### When to Use

- After Wine reinstall
- After MT5 update
- Login credentials lost
- Before Model=4 (real ticks) backtest

### What It Does

Restores from `config/mt5-backup/`:
- `common.ini` - Login settings (account: 128364028, server: Exness-MT5Real7)
- `accounts.dat` - Saved credentials
- `servers.dat` - Server configurations

### Integration

**When backtest fails with "no connection":**
```bash
# Restore login
./scripts/restore_mt5_login.sh

# Verify by opening MT5
open -a "MetaTrader 5"

# Re-run backtest
./scripts/run_backtest_native.sh
```

---

## 🎯 Complete Workflow Examples

### **Coder Agent - Full Iteration**

```bash
# START: Pull latest
./scripts/git_workflow.sh pull

# Read task
cat tasks/CODER_TASK.md

# Implement EA
nano code/experts/AdvancedEA.mq5

# Compile
./scripts/compile_ea.sh AdvancedEA
# If errors: fix → re-compile → repeat

# Validate config
./scripts/validate_config.sh config/active/autobacktest.ini
# If errors: fix config → re-validate

# Run backtest
./scripts/run_backtest_native.sh
# Wait for completion

# Collect results
./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5

# Update experience
nano experience/compile_issues.md  # Add lessons

# Mark task done
nano tasks/CODER_TASK.md  # Status: DONE
mv tasks/CODER_TASK.md tasks/archive/2026-02-17_AdvancedEA_v1.md

# END: Sync to git
./scripts/git_workflow.sh sync "Coder: AdvancedEA v1 backtest complete - results/2026-02-17_AdvancedEA_XAUUSD_M5.csv"
```

### **Technical Analyst - Create Specs**

```bash
# START: Pull latest
./scripts/git_workflow.sh pull

# Read inputs
cat brain/implementation_plan.md
cat experience/mql5_patterns.md

# Create CODER_TASK
nano tasks/CODER_TASK.md

# Validate config template
./scripts/validate_config.sh config/templates/standard.ini
# Fix any errors

# END: Sync to git
./scripts/git_workflow.sh sync "Technical Analyst: CODER_TASK v1 with confluence specs ready for review"
```

### **Researcher - Strategy Research**

```bash
# START: Pull latest
./scripts/git_workflow.sh pull

# Read context
cat brain/optimization_log.md
cat experience/backtest_journal.md

# Research & write
nano brain/strategy_research.md

# END: Sync to git
./scripts/git_workflow.sh sync "Researcher: Iteration 2 - refined PA filters for Asian session"
```

### **Backtester - Trade Analysis**

```bash
# START: Pull latest
./scripts/git_workflow.sh pull

# Read inputs
cat results/2026-02-17_AdvancedEA_XAUUSD_M5.csv
cat brain/implementation_plan.md

# Analyze & write journal
nano results/2026-02-17_AdvancedEA_journal.md

# Update persistent lessons
nano experience/backtest_journal.md

# END: Sync to git
./scripts/git_workflow.sh sync "Backtester: Iteration 1 analysis - WR 85%, FALSE_SIGNAL in Asian session"
```

---

## 🚨 Troubleshooting

### Script Permission Denied

```bash
chmod +x scripts/*.sh
```

### Git Conflicts on Pull

```bash
./scripts/git_workflow.sh pull
# If conflict:
# 1. Resolve conflicts manually
# 2. git add .
# 3. ./scripts/git_workflow.sh commit "Resolved conflicts"
# 4. ./scripts/git_workflow.sh push
```

### Wine Path Not Found

```bash
# Check Wine installation
ls -la "/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"

# If missing: reinstall MT5 from https://www.metatrader5.com/en/download
```

### CSV Not Created After Backtest

**Possible causes:**
1. OnTester() missing from EA → add it
2. FileOpen() missing FILE_COMMON flag → add flag
3. Wrong Wine username in path → check with: `ls -la "$WINEPREFIX/drive_c/users/"`

---

## 📚 References

- **MQL5 Documentation:** https://www.mql5.com/en/docs
- **Wine/MT5 Setup:** `experience/wine_quirks.md`
- **Compile Issues:** `experience/compile_issues.md`
- **Config Gotchas:** `experience/backtest_setup.md`
