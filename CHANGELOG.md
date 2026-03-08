# Changelog

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
