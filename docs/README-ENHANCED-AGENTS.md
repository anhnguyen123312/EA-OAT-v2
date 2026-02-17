# EA-OAT-v2 Enhanced Multi-Agent Architecture

## Overview

EA-OAT-v2 đã được nâng cấp từ **7 agents** lên **14 agents** dựa trên ý tưởng từ [TradingAgents](https://github.com/TauricResearch/TradingAgents) framework. Hệ thống mới tích hợp:

- **Multi-perspective analysis** (Market Context, News, Sentiment)
- **Adversarial debate** (Bull vs Bear researchers)
- **Risk assessment gate** (Risk Analyst pre-screening)
- **Semantic memory** (Memory Manager with embedding search)

---

## Agent Roster (14 Total)

### Phase 1: Research & Analysis (NEW - 4 agents)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **Market Context Analyst** | HTF trends, DXY correlation, volatility regime | OHLCV data (M15, H1, H4, D1), DXY data | Market regime report |
| **News Analyst** | Economic calendar, event impact | Calendar, news feeds | Event filter recommendations |
| **Sentiment Analyst** | COT reports, institutional positioning | COT data, broker sentiment | Positioning report |
| **Researcher** | PA+S/R strategy research (ENHANCED) | All context reports + past journals | Strategy proposal |

### Phase 2: Strategy Debate (NEW - 2 agents)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **Bull Researcher** | Build strongest case WHY strategy works | Strategy proposal + context | Bull arguments |
| **Bear Researcher** | Find flaws, challenge assumptions | Strategy proposal + context | Bear challenges |

**Outcome:** Debate transcript → PM synthesizes refined strategy

### Phase 3: Planning & Risk (1 existing + 1 NEW)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **PM** | Implementation plan (EXISTING) | Refined strategy from debate | CODER_TASK.md |
| **Risk Analyst** | Pre-implementation risk assessment (NEW) | Implementation plan + all context | Risk report, DD projection |

### Phase 4: Quality Gate (EXISTING - 2 agents)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **Technical Analyst** | MQL5 specs | Implementation plan | Technical specs |
| **Reviewer** | Quality gate | All Phase 1-3 outputs | Approve/Reject |

### Phase 5: Implementation (EXISTING - 2 agents)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **Coder** | Code + compile + backtest | CODER_TASK.md | Backtest results |
| **Backtester** | Trade-by-trade analysis | Backtest CSV | Journal, root cause |

### Coordinator & Utility (1 existing + 1 NEW)

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **Em (Lead)** | Coordination, iteration decisions (EXISTING) | All outputs | Next iteration tasks |
| **Memory Manager** | Semantic search, lesson retrieval (NEW) | Query from any agent | Relevant past learnings |

---

## Workflow Comparison

### Old Pipeline (7 agents)
```
Researcher → PM → Technical → Reviewer → Coder → Backtester → Lead
```

### New Pipeline (14 agents)
```
┌─────────────────────────────────────────┐
│ Phase 1: Multi-Source Analysis         │
├─────────────────────────────────────────┤
│ Market Context │ News │ Sentiment │     │
│        └────────┴──────┴──────┐         │
│                         Researcher      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│ Phase 2: Adversarial Debate             │
├─────────────────────────────────────────┤
│   Bull Researcher ↔ Bear Researcher     │
│            │                             │
│            ▼                             │
│      Debate Synthesis                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│ Phase 3: Planning & Risk                │
├─────────────────────────────────────────┤
│   PM → Risk Analyst                     │
│         │                                │
│         ▼                                │
│   Risk Acceptable? ──No──> Adjust       │
│         │                   │            │
│        Yes                  └──> PM     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│ Phase 4: Quality Gate (unchanged)       │
├─────────────────────────────────────────┤
│ Technical Analyst → Reviewer            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│ Phase 5: Implementation (unchanged)     │
├─────────────────────────────────────────┤
│ Coder → Backtester → Lead               │
└─────────────────────────────────────────┘

    Memory Manager (serves all agents)
```

---

## Key Improvements from TradingAgents

### 1. Multi-Perspective Analysis
**Inspired by:** TradingAgents' Analyst Team (Fundamentals, Market, News, Sentiment)

**Our Implementation:**
- **Market Context Analyst:** Multi-timeframe (M15/H1/H4/D1), DXY correlation, volatility regime
- **News Analyst:** Economic calendar, FOMC/NFP/CPI event filters
- **Sentiment Analyst:** COT reports, institutional vs retail positioning

**Benefit:** Strategies are designed WITH context, not in vacuum. Reduces blind spots.

---

### 2. Adversarial Debate
**Inspired by:** TradingAgents' Bull vs Bear Researcher debate

**Our Implementation:**
- **Bull Researcher:** Builds strongest case for WHY strategy will work
- **Bear Researcher:** Attacks assumptions, finds edge cases, cites past failures
- **Rounds:** Configurable (default: 2 rounds)
- **Output:** Debate transcript → PM synthesizes

**Benefit:** Exposes flaws BEFORE coding. Saves wasted iterations on broken strategies.

**Example Debate Topics:**
- Bull: "MA crossover + S/R achieves 90% WR via confluence"
- Bear: "MA lags price, we enter late, RR degrades to 1:1.5"
- Bull refutes: "We use S/R pullback entry, not mid-move chase"
- Outcome: Add break-and-retest logic to avoid lag problem

---

### 3. Risk Assessment Gate
**Inspired by:** TradingAgents' Risk Management Team

**Our Implementation:**
- **Risk Analyst:** Runs BEFORE coding
- **Assessments:**
  - Monte Carlo DD projection
  - Risk dimension scoring (strategy/market/event/sentiment/execution)
  - Failure scenario analysis
  - Mitigation requirements
- **Decision:** Approve (low risk) / Approve with mitigations (medium) / Reject (high)

**Benefit:** Prevents high-DD strategies from being coded. Saves backtest time.

---

### 4. Memory System
**Inspired by:** TradingAgents' Memory for past decisions

**Our Implementation:**
- **Memory Manager:** Semantic search over `brain/` and `experience/`
- **Technology:** ChromaDB + OpenAI embeddings
- **Queries:** "What S/R methods failed before?" → Retrieves relevant chunks
- **Integration:** All agents can query for past learnings

**Benefit:** Agents learn from past iterations. Don't repeat mistakes.

---

## Configuration

All settings in `config/agents_config.yaml`:

```yaml
# Quick Start - Enable/Disable Enhanced Mode
workflow:
  mode: "enhanced"  # or "simple" for old 7-agent pipeline

# Agent Models
agents:
  market_context_analyst:
    enabled: true
    model: "claude-sonnet-4-5"
  # ... etc

# Debate Settings
debate:
  enabled: true
  max_rounds: 2

# Risk Settings
risk:
  max_acceptable_dd: 10.0
  circuit_breaker:
    daily_dd_limit: 5.0

# Memory Settings
memory:
  enabled: true
  embedding_model: "text-embedding-3-small"
```

---

## Usage

### Slash Commands (unchanged)

```bash
/em [instruction]         # Run as Lead
/researcher [instruction] # Run as Researcher
/pm [instruction]         # Run as PM
/coder [instruction]      # Run as Coder
/backtester [instruction] # Run as Backtester
/reviewer [instruction]   # Run as Reviewer
/technical [instruction]  # Run as Technical Analyst
```

### New Slash Commands

```bash
/market-context-analyst [instruction]
/news-analyst [instruction]
/sentiment-analyst [instruction]
/bull-researcher [instruction]
/bear-researcher [instruction]
/risk-analyst [instruction]
/memory-manager [query]
```

### Typical Iteration Flow (Enhanced Mode)

```bash
# 1. Lead starts iteration
/em "Start Iteration 3 - analyze current market and refine strategy"

# 2. Market Context (parallel)
/market-context-analyst "Analyze Gold regime for next 7 days"
/news-analyst "Check economic calendar and create event filters"
/sentiment-analyst "Check COT positioning and sentiment"

# 3. Researcher proposes strategy
/researcher "Design PA+S/R strategy based on context reports"

# 4. Debate (sequential)
/bull-researcher "Build case for proposed strategy"
/bear-researcher "Challenge strategy assumptions and find risks"
# ... rounds continue ...

# 5. PM synthesizes
/pm "Create implementation plan from debate synthesis"

# 6. Risk assessment
/risk-analyst "Assess risk before coding - project DD and failure scenarios"

# 7. Quality gate (if risk acceptable)
/technical "Convert plan to MQL5 specs"
/reviewer "Review all outputs, approve/reject"

# 8. Implementation (if approved)
/coder "Implement EA from CODER_TASK, compile, backtest"
/backtester "Analyze trades, classify, identify root cause"

# 9. Memory update
/memory-manager "Index new learnings from Iteration 3"

# 10. Lead decision
/em "Review results, decide next iteration or pivot"
```

---

## Directory Structure (Enhanced)

```
EA-OAT-v2/
├── brain/
│   ├── strategy_research.md
│   ├── market_context_reports/      (NEW)
│   │   └── iteration_N_context.md
│   ├── sentiment_reports/           (NEW)
│   │   └── iteration_N_sentiment.md
│   ├── news_impact_log.md           (NEW)
│   ├── debate_transcripts/          (NEW)
│   │   └── iteration_N_debate.md
│   ├── risk_assessments/            (NEW)
│   │   └── iteration_N_risk.md
│   └── ... (existing files)
│
├── data/                            (NEW)
│   ├── market_context/
│   │   ├── XAUUSD_M15.csv
│   │   ├── XAUUSD_H1.csv
│   │   ├── DXY_D1.csv
│   │   └── correlations.csv
│   ├── news_events/
│   │   ├── economic_calendar.json
│   │   └── news_feeds.json
│   ├── sentiment/
│   │   ├── cot_gold.csv
│   │   └── retail_positioning.json
│   └── embeddings/
│       └── memory_index.db
│
├── skills/
│   ├── market-context-analyst/      (NEW)
│   ├── news-analyst/                (NEW)
│   ├── sentiment-analyst/           (NEW)
│   ├── bull-researcher/             (NEW)
│   ├── bear-researcher/             (NEW)
│   ├── risk-analyst/                (NEW)
│   ├── memory-manager/              (NEW)
│   └── ... (7 existing agents)
│
├── config/
│   └── agents_config.yaml           (NEW)
│
└── docs/
    ├── plans/
    │   └── integration-tradingagents.md
    └── README-ENHANCED-AGENTS.md    (this file)
```

---

## Cost Optimization

Enhanced mode uses more agents but optimized for cost:

| Agent | Model | Reasoning |
|-------|-------|-----------|
| Em (Lead) | Opus 4.6 | Strategic decisions (sparse usage) |
| Risk Analyst | Opus 4.6 | Critical risk assessment |
| Debate Synthesis | Opus 4.6 | Complex reasoning |
| All Analysts | Sonnet 4.5 | Standard intelligence |
| Memory Manager | Haiku 4.5 | Fast retrieval (cheap) |

**Estimated cost increase:** ~30% vs simple mode, but **reduces wasted iterations** by catching bad strategies early.

---

## Performance Expectations

### Old Pipeline (7 agents)
- **Iterations to viable strategy:** 3-5
- **False starts:** 2-3 (strategies that backtest poorly)
- **Time per iteration:** 2-3 hours

### Enhanced Pipeline (14 agents)
- **Iterations to viable strategy:** 2-3 (debate catches issues early)
- **False starts:** 0-1 (risk analyst pre-screens)
- **Time per iteration:** 3-4 hours (more analysis upfront)

**Net result:** FASTER to viable strategy despite longer per-iteration time.

---

## Migration Guide

### Option 1: Start with Enhanced Mode (Recommended for new iterations)
```yaml
# config/agents_config.yaml
workflow:
  mode: "enhanced"
```

### Option 2: Gradually Add Agents
```yaml
# Start with debate only
debate:
  enabled: true

# Keep other new agents disabled
agents:
  market_context_analyst:
    enabled: false  # Add later
```

### Option 3: Keep Simple Mode
```yaml
# Use original 7-agent pipeline
workflow:
  mode: "simple"
```

---

## Troubleshooting

### Issue: Too many agents slow down iteration
**Solution:** Disable optional agents in config
```yaml
agents:
  sentiment_analyst:
    enabled: false  # Disable if COT data unavailable
```

### Issue: Debate doesn't reach conclusion
**Solution:** Reduce max_rounds or disable consensus requirement
```yaml
debate:
  max_rounds: 1  # Faster, less thorough
  require_consensus: false
```

### Issue: Memory search returns irrelevant results
**Solution:** Increase similarity threshold
```yaml
memory:
  similarity_threshold: 0.8  # Higher = more relevant, fewer results
```

---

## Next Steps

1. **Review:** Read integration plan in `docs/plans/integration-tradingagents.md`
2. **Configure:** Edit `config/agents_config.yaml` for your preferences
3. **Test:** Run Iteration 1 with enhanced mode
4. **Iterate:** Refine agent prompts based on results
5. **Scale:** Add more data sources (DXY, COT) as infrastructure matures

---

## References

- **TradingAgents Framework:** https://github.com/TauricResearch/TradingAgents
- **Original EA-OAT-v2:** `.claude/CLAUDE.md`
- **Integration Plan:** `docs/plans/integration-tradingagents.md`
- **Agent Skills:** `skills/*/SKILL.md` (14 files)

---

**Happy Trading! 🚀**
