# 11 — Shop & currency

**Problem:** buying and selling must never create or destroy money/items by accident.

**Solution:** `Wallet` (integer balance, `earn`, `spend`) with atomic `buy` (money only taken if every item fits)
and `sell` (pays `floor(value × sell_ratio)`). Prices live in `ItemDef.value` (recipe 09) or a price table.

**Tuning:** item values, `sell_ratio` (0.3–0.6 keeps buy/sell loops unprofitable), starting money.

**Pitfalls:** floats for money; taking money before checking room; sell price ≥ buy price (infinite money loop —
write a test that buy-then-sell never gains money); UI showing prices from a different table than the logic uses.

**Test:** `tests/unit/test_r11_shop.gd`. Builds on recipe 09.
