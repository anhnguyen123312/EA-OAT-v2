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
- `ShutdownTerminal=1` for Wine CLI automated runs (MT5 auto-closes after backtest)
- `ShutdownTerminal=0` for native macOS app (=1 causes immediate exit before backtest starts)

### Native macOS app vs Wine CLI
- **Native app** (PREFERRED): `open -a "MetaTrader 5" --args '/config:C:\Program Files\MetaTrader 5\autobacktest.ini'`
  - Preserves broker login session (Exness)
  - Must set `ShutdownTerminal=0`
  - May need manual start via Strategy Tester (Ctrl+R)
- **Wine CLI**: `/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64 terminal64.exe`
  - Creates fresh MT5 instance without login
  - Use `ShutdownTerminal=1` for auto-close

### MetaEditor compilation from CLI
- Must run from MT5 base directory: `cd "$MT5_BASE"`
- Must use relative Windows path: `'/compile:MQL5\Experts\SimpleEA.mq5'`
- Absolute paths or wrong directory → silent failure (no .ex5 produced)
- Check `MQL5/Experts/SimpleEA.log` for results

### Login credentials backup
- MT5 login stored in `$MT5_BASE/config/`:
  - `common.ini` - Login + server
  - `accounts.dat` - Saved credentials (binary)
  - `servers.dat` - Server configs (binary)
- Backup: `config/mt5-backup/` (gitignored)
- Restore: `scripts/restore_mt5_login.sh`

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
