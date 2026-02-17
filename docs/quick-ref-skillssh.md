# Quick Reference: 3 Key Patterns from skills.sh

## 1. Confluence Score (0-10)

```
Setup Analysis Checklist:

Elliott Wave (0-3):
□ Wave 3 or early Wave 5? → +3
□ Wave 2/4 pullback? → +2
□ Late Wave 5? → +1
□ Corrective wave C? → 0

Wyckoff Phase (0-4):
□ Accumulation LPS + markup? → +4
□ Accumulation Spring? → +3
□ Ranging? → +2
□ Distribution LPSY/markdown? → 0

Fibonacci Levels (0-3):
□ 38.2-50% pullback + 161.8% target? → +3
□ 50-61.8% pullback + 138.2% target? → +2
□ 61.8-78.6% deep pullback? → +1
□ Poor levels? → 0

TOTAL SCORE:
9-10 = EXCELLENT ✅ (high conviction)
7-8  = GOOD ✅ (standard trade)
5-6  = MODERATE ⚠️ (reduce size)
0-4  = SKIP ❌ (no trade)
```

---

## 2. Risk Anti-Patterns (Quick Check)

Before coding ANY strategy, verify:

### Capital & Exposure
- [ ] Risk per trade = 1-2% (not more, not unspecified)
- [ ] Max daily DD defined (e.g., -5%)
- [ ] No position > 30% of equity
- [ ] Spread/slippage/fees included

### Position Sizing & Stops
- [ ] SL explicit per trade (not "mental stop")
- [ ] Lot = f(Risk%, SL_distance) [not arbitrary]
- [ ] No martingale (increasing size after loss)
- [ ] Stops at structural levels (not round numbers)

### Backtest Integrity
- [ ] No look-ahead bias (no future data)
- [ ] Walk-forward test (not just in-sample)
- [ ] Realistic costs (spread, slippage modeled)
- [ ] Sharpe < 3, WR < 95% (if higher = overfitting)

**If ANY box unchecked → HIGH RISK → Fix or reject**

---

## 3. Agent Architecture (Hybrid)

```
RESEARCH PHASE (Swarm-like):
Market Context ↔ News ↔ Sentiment
       ↓
   Researcher
       ↓
  Bull ↔ Bear (debate)

       ↓ (GATE: Supervisor checks consensus)

EXECUTION PHASE (Supervised):
       PM
       ↓
   Risk Analyst ← GATE: Anti-patterns check
       ↓
  Technical Analyst
       ↓
    Reviewer ← GATE: Quality check
       ↓
     Coder
       ↓
  Backtester
       ↓
  Lead (Em) ← DECISION: Iterate/Pivot/Done
```

**Key:** Lateral exploration in research, linear gates in execution

---

## Usage Templates

### For Technical Analyst
```markdown
## Confluence Analysis
- Elliott: [Wave position] → [score/3]
- Wyckoff: [Phase] → [score/4]
- Fibonacci: [Levels] → [score/3]
- **TOTAL: X/10** → [EXCELLENT/GOOD/MODERATE/SKIP]
```

### For Risk Analyst
```markdown
## Anti-Patterns Check
- Capital/Exposure: [X/6 passed]
- Position Sizing: [X/6 passed]
- Backtest Design: [X/7 passed]
**CRITICAL VIOLATIONS:** [list]
**VERDICT:** [APPROVE/APPROVE_WITH_MITIGATIONS/REJECT]
```

### For Lead (Em)
```markdown
## Iteration Decision
- Research swarm complete? [Y/N]
- Risk gate passed? [Y/N]
- Quality gate passed? [Y/N]
- Backtest results: WR=X%, RR=1:X, trades/day=X
- Confluence avg: X/10
**DECISION:** [ITERATE/PIVOT/TARGETS_MET]
```

---

**Quick Ref Version:** skills-sh-integration.md (full details)
