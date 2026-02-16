# Backtest Setup

MT5 config tricks, .ini gotchas, timing issues.

## Known Gotchas

### Expert= path in .ini
- ONLY use EA name: `Expert=MyEA`
- NEVER use path prefix: `Expert=Experts\MyEA` (causes "not found" error)

### OnTester() requirements
- MUST return `double`, not `void`
- MUST use `FILE_COMMON` flag in `FileOpen()` for CSV export
- Without `FILE_COMMON`, file goes to local terminal folder (hard to find)

### ShutdownTerminal
- Always set `ShutdownTerminal=1` for automated runs
- MT5 auto-closes after backtest completes

<!-- Coder updates this file with new discoveries -->
