# Multi-Agent Architecture Design - EA-OAT-v2

## Date: 2026-02-17
## Status: DRAFT

---

## 1. Overview

Expand EA-OAT-v2 from 2-agent (Em + Coder) to 6-agent team swarm architecture using Claude Code Agent Teams. Focus: Price Action + Support/Resistance strategies for Commodity Futures (Gold XAUUSD, Oil CL) on MT5.

### Targets (ALL must be met simultaneously)
| Metric | Target |
|--------|--------|
| Win Rate | >= 90% |
| Risk:Reward | >= 1:2 |
| Trades/day | >= 10 |
| Max Drawdown | < 10% |

---

## 2. Architecture

### Runtime: Claude Code Agent Teams
- 1 Team Lead (user's main session) + 6 Teammates
- Shared task list with dependencies
- Inter-agent messaging
- Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json

### 6 Agents

| Agent | Role | Phase | Reads | Writes |
|-------|------|-------|-------|--------|
| Researcher | Deep research PA+S/R methods for Gold/Oil | Phase 1 | brain/, experience/ | brain/strategy_research.md |
| PM | Break strategy into implementation plan | Phase 1 | brain/, Researcher output | brain/implementation_plan.md |
| Technical Analyst | Convert PM docs → MQL5 specs | Phase 1 | PM output, brain/ | tasks/CODER_TASK.md |
| Reviewer | Quality gate - review all Phase 1 outputs | Gate | All Phase 1 outputs | brain/review_log.md |
| Coder | Implement EA, compile, run backtest | Phase 2 | tasks/, brain/, experience/ | code/experts/, results/ |
| Backtester | Trade-by-trade analysis, journal | Phase 2 | results/, code/experts/ | results/journal, experience/backtest_journal.md |

### Task Dependencies

```
Task 1: [Researcher] Research PA+S/R methods for Gold/Oil
Task 2: [PM] Break down strategy into implementation plan
  └── blockedBy: [Task 1]
Task 3: [Technical] Convert PM plan → MQL5 technical specs
  └── blockedBy: [Task 2]
Task 4: [Reviewer] Review Researcher + PM + Technical outputs
  └── blockedBy: [Task 1, Task 2, Task 3]
Task 5: [Coder] Implement EA from approved specs
  └── blockedBy: [Task 4]
Task 6: [Backtester] Run backtest, trade-by-trade analysis
  └── blockedBy: [Task 5]
```

### Iteration Loop

```
1. Backtester reports → Lead receives results
2. Lead checks targets: WR >= 90%? RR >= 1:2? Trades >= 10? DD < 10%?
3. ALL met → DONE, report to Boss
4. MISS → Lead analyzes root cause from journal:
   - WR low → Researcher: "refine entry filters"
   - RR poor → Researcher: "improve exit strategy"
   - Few trades → Researcher: "relax entry conditions"
   - DD high → Researcher: "add risk management"
5. Lead creates new tasks for Iteration N+1
6. Pipeline reruns: Research → PM → Tech → Review → Code → Backtest

Max iterations: 10 (then escalate to Boss)
Pivot rule: 3 iterations no improvement → Researcher pivot strategy
```

### Communication Flow

- Researcher → PM: research findings
- PM → Technical: plan details
- Reviewer → any Phase 1 agent: reject + feedback
- Coder → Backtester: compile complete, ready for backtest
- Backtester → Lead: results + journal
- Lead → Researcher: next iteration direction

---

## 3. Trade Classification System

### 5 Categories

| Category | Description | Action |
|----------|-------------|--------|
| CORRECT_WIN | Entry matches strategy, TP hit | None - working as intended |
| CORRECT_LOSS | Entry matches strategy, SL hit | Check RR ratio |
| FALSE_SIGNAL | Entry does NOT match strategy rules | Coder bug fix |
| BAD_TIMING | Right direction, entered too early/late | Researcher refine entry trigger |
| MISSED_EXIT | Had profit but exited too early/late | Researcher refine exit logic |

### Classification Logic

```
For each trade in MT5 history:
1. Parse: ticket, type, open/close time, entry/sl/tp, profit
2. Get price data at entry time
3. Check entry rules against strategy spec:
   - S/R level valid?
   - Candlestick pattern confirmed?
   - All filters passed?
4. Classify:
   - Rules NOT match → FALSE_SIGNAL
   - Rules match + win → CORRECT_WIN
   - Rules match + loss:
     - Price went correct direction after SL? → BAD_TIMING
     - Price never went correct direction → CORRECT_LOSS
   - Win but profit < expected RR → MISSED_EXIT
5. Record journal entry with note + fix suggestion
```

---

## 4. Backtest Journal Format

### File: `results/iteration_N_journal.md`

```markdown
# Backtest Journal - Iteration N
## EA: [Name] v[N] | Symbol: XAUUSD | Period: H1
## Date Range: 2024.01.01 - 2024.12.31

### Summary
| Metric          | Value  | Target | Status |
|-----------------|--------|--------|--------|
| Win Rate        | X%     | >= 90% | PASS/MISS |
| Risk:Reward     | 1:X    | >= 1:2 | PASS/MISS |
| Trades/day      | X      | >= 10  | PASS/MISS |
| Max Drawdown    | X%     | < 10%  | PASS/MISS |
| Total Trades    | X      |        |        |

### Classification Breakdown
| Category       | Count | % of Total | Impact     |
|---------------|-------|------------|------------|
| CORRECT_WIN   | X     | X%         | +X% to WR  |
| CORRECT_LOSS  | X     | X%         | expected   |
| FALSE_SIGNAL  | X     | X%         | -X% to WR  |
| BAD_TIMING    | X     | X%         | -X% to WR  |
| MISSED_EXIT   | X     | X%         | hurts RR   |

### Session Analysis (Time-of-Day)
| Session        | Hours (UTC)  | Trades | WR    | Avg RR | Notes |
|---------------|-------------|--------|-------|--------|-------|
| Asian         | 00:00-08:00 | X      | X%    | 1:X    |       |
| London        | 08:00-12:00 | X      | X%    | 1:X    |       |
| London-NY     | 12:00-16:00 | X      | X%    | 1:X    | overlap |
| NY            | 16:00-21:00 | X      | X%    | 1:X    |       |
| Late NY       | 21:00-00:00 | X      | X%    | 1:X    |       |

### Session Insights
- Best performing session: [session] (WR: X%, RR: 1:X)
- Worst performing session: [session] (WR: X%, RR: 1:X)
- Recommendation: [e.g., "Disable trading during Asian session"]

### Correlation Analysis
| Pattern | Occurrences | Impact | Recommendation |
|---------|-------------|--------|----------------|
| FALSE_SIGNAL clusters in [session] | X | -X% WR | Add session filter |
| BAD_TIMING after news events | X | -X% WR | Add news filter |
| MISSED_EXIT in trending market | X | hurts RR | Trail stop in trend |
| Consecutive losses > 3 | X times | DD spike | Add cooldown period |

### Root Cause Summary (for Lead)
- **WR gap**: X% → 90%. Need to eliminate:
  - FALSE_SIGNAL: X trades (fix: [specific])
  - BAD_TIMING: X trades (fix: [specific])
- **RR gap**: 1:X → 1:2. Fix MISSED_EXIT: X trades
- **Priority**: [ordered list of fixes]

### Trade Details
[Each trade as detailed entry with classification]
```

---

## 5. Agent Skill Definitions

### 5.1 Researcher (`skills/researcher/SKILL.md`)

**Role**: Deep research Price Action + S/R methods for Gold/Oil commodity futures.

**Responsibilities**:
- Research PA methods: S/D zones, key levels, candlestick patterns, breakout/retest
- Study Gold-specific behavior: session patterns, news sensitivity, volatility cycles
- Analyze which methods suit targets (90% WR, 1:2 RR, 10 trades/day)
- Learn from backtest journals to refine strategy
- Output structured research to brain/strategy_research.md

**Iteration behavior**:
- Iteration 1: Full research, propose strategy
- Iteration N+1: Read backtest journal, analyze failures, refine specific aspects

### 5.2 PM (`skills/pm/SKILL.md`)

**Role**: Break research into detailed, actionable implementation plan.

**Responsibilities**:
- Read Researcher output and create structured implementation plan
- Define milestones, acceptance criteria, parameter ranges
- Create clear entry/exit rules specification
- Define risk management rules
- Ensure plan is specific enough for Technical Analyst to convert to code

### 5.3 Technical Analyst (`skills/technical-analyst/SKILL.md`)

**Role**: Convert PM's implementation plan into MQL5 technical specifications.

**Responsibilities**:
- Translate strategy rules to MQL5-compatible logic
- Define indicator parameters, buffer access patterns
- Write CODER_TASK.md with exact MQL5 implementation spec
- Define OnTester() metrics requirements
- Specify backtest configuration (symbol, period, date range)

### 5.4 Reviewer (`skills/reviewer/SKILL.md`)

**Role**: Quality gate between planning and execution phases.

**Responsibilities**:
- Review Researcher output: methods valid? evidence-based?
- Review PM output: plan complete? rules unambiguous? measurable criteria?
- Review Technical output: specs codeable? MQL5 compatible? edge cases handled?
- Identify gaps, inconsistencies, missing rules
- Can reject and send back to any agent with specific feedback
- Only approve when ALL outputs are consistent and complete

### 5.5 Coder (`skills/coder-worker/SKILL.md` - updated)

**Role**: Implement EA from approved specs, compile, prepare for backtest.

**Changes from current**:
- No longer analyzes backtest results (Backtester does that)
- Focus: implement → compile → run backtest → collect raw results
- Still maintains experience/ for technical lessons

### 5.6 Backtester (`skills/backtester/SKILL.md` - new)

**Role**: Trade-by-trade backtest analysis with session and correlation insights.

**Responsibilities**:
- Parse MT5 backtest results (CSV + trade history)
- Classify each trade into 5 categories
- Analyze by trading session (Asian/London/NY)
- Find correlation patterns in failures
- Write detailed journal with root cause summary
- Provide actionable fix suggestions for next iteration

---

## 6. Directory Structure (updated)

```
brain/
  strategy_research.md    ← Researcher writes
  implementation_plan.md  ← PM writes
  design_decisions.md     ← PM + Researcher write
  optimization_log.md     ← Lead writes (iteration tracking)
  review_log.md           ← Reviewer writes
  targets.md              ← Lead updates

experience/
  backtest_journal.md     ← Backtester writes (persistent lessons)
  compile_issues.md       ← Coder writes
  mql5_patterns.md        ← Coder writes
  backtest_setup.md       ← Coder writes
  wine_quirks.md          ← Coder writes

tasks/
  CODER_TASK.md           ← Technical Analyst writes
  OPTIMIZATION_TASK.md    ← Lead writes for iteration N+1
  archive/

results/
  iteration_N_XAUUSD_H1.csv        ← Coder collects from MT5
  iteration_N_journal.md            ← Backtester writes
  iteration_N_trades_detail.csv     ← Backtester exports
  logs/

code/experts/   ← Coder writes
code/include/   ← Coder writes
code/indicators/ ← Coder writes

skills/
  researcher/SKILL.md
  pm/SKILL.md
  technical-analyst/SKILL.md
  reviewer/SKILL.md
  coder-worker/SKILL.md       ← updated
  backtester/SKILL.md          ← new

config/
  templates/
  active/
```

---

## 7. Slash Commands

| Command | Agent | File |
|---------|-------|------|
| `/researcher` | Researcher | .claude/commands/researcher.md |
| `/pm` | PM | .claude/commands/pm.md |
| `/technical` | Technical Analyst | .claude/commands/technical.md |
| `/reviewer` | Reviewer | .claude/commands/reviewer.md |
| `/coder` | Coder (updated) | .claude/commands/coder.md |
| `/backtester` | Backtester | .claude/commands/backtester.md |
| `/em` | Team Lead (updated) | .claude/commands/em.md |

---

## 8. Team Launch Command

```
Create a team "ea-oat-gold" with 6 teammates:
- researcher: load skills/researcher/SKILL.md, deep research PA+S/R for Gold
- pm: load skills/pm/SKILL.md, break strategy into implementation plan
- technical: load skills/technical-analyst/SKILL.md, convert to MQL5 specs
- reviewer: load skills/reviewer/SKILL.md, quality gate all outputs
- coder: load skills/coder-worker/SKILL.md, implement and compile EA
- backtester: load skills/backtester/SKILL.md, trade-by-trade analysis

Task dependencies:
- pm blockedBy researcher
- technical blockedBy pm
- reviewer blockedBy researcher, pm, technical
- coder blockedBy reviewer
- backtester blockedBy coder

After backtester completes, analyze results against targets.
If targets not met, create new iteration tasks.
Max 10 iterations.
```
