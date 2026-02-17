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

### Wine Common/Files path (macOS CrossOver)
- Wine user is `crossover`, NOT your macOS username
- Common/Files path: `$WINEPREFIX/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/`
- NOT: `$WINEPREFIX/drive_c/users/$(whoami)/...` (this path does NOT exist)
- Use `find "$WINEPREFIX" -name "backtest_results.csv"` if path is wrong

### CSV encoding
- MT5 writes CSV in UTF-16LE encoding (BOM: FF FE)
- Must convert to UTF-8 before parsing: `iconv -f UTF-16LE -t UTF-8 input.csv > output.csv`
- Tester logs are also UTF-16LE encoded

### Tester logs location
- Logs at: `$MT5_BASE/Tester/logs/YYYYMMDD.log`
- Agent logs at: `$MT5_BASE/Tester/Agent-127.0.0.1-3000/logs/YYYYMMDD.log`
- Both are UTF-16LE encoded

<!-- Coder updates this file with new discoveries -->
