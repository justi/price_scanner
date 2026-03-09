# Changelog

## 0.3.0

- Add `include_per_unit:` option to `extract_prices_from_text` — allows including per-unit prices (`£46.00/M`, `29,99 zł/kg`) that are filtered by default

## 0.2.3

- Fix comma-as-thousands-separator not recognized in PRICE_PATTERN (`7,999.00 €` → was parsed as `999.00 €`)
- Affects prices in English/international format: `$1,299.99`, `8,289.00 €`, etc.
- Safe change: requires exactly 3 digits after separator, so decimal commas (`19,99 zł`) still work correctly

## 0.2.2

- Fix negative price detection with spaced dash ("- 1.040 zł") — savings badges with space between minus and price were not filtered
- Refactor `negative_price?` with `rindex_non_space` helper (DRY)
- Distinguish range separators ("Pack of 3 - 29,99 zł") from negative prices

## 0.2.1

- Fix false price extraction from model numbers (IP65, HC940, H265, 2K 30MP)
- Prevent digits before currency symbol from being matched as prices

## 0.2.0

- Remove ConsentDetector from gem (moved to smart_offers app)

## 0.1.1

- Remove rubycritic dependency
- Auto-require all price_scanner modules

## 0.1.0

- Initial release
- `PriceScanner::Parser` — normalize prices, extract currency, strip price mentions
- `PriceScanner::Detector` — extract prices from text, filter negatives/per-unit/ranges/savings
- Multi-currency support: PLN, EUR, USD, GBP
- Smart filtering: negative prices, per-unit prices, price ranges, savings amounts
