# AETHERION

**Adaptive Multi-Asset Intelligence** for MetaTrader 5.

Drop it on any chart. It reads the symbol, the timeframe and the asset class by itself — forex, crypto, every USDT pair, metals, energy, indices and stocks.

**v1.2.0** adds weekend flatten, quiet/volatile stand-aside, EMA pullback entries, breakeven after partials, gold/oil gap filter and a 24-hour hold cap. The command deck never shows tester numbers until you import your own HTM/CSV.

```
aetherion/
├── MQL5/Experts/Aetherion/     ← compile this folder in MetaEditor
├── Presets/                    ← load *.set from Inputs
├── Settings/Aetherion_Settings.xlsx
├── Tester/                     ← real-layout Strategy Tester dumps
├── simulator/                  ← live glowing deck
└── docs/                       ← Arabic install + warnings
```

Open the interactive deck:

```bash
python3 aetherion/simulator/server.py
```

Read `docs/README.md` and `docs/WARNINGS.md` before any live account.
