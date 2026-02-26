# PriceScanner

Battle-tested multi-currency price extraction from text. Supports PLN, EUR, GBP, USD with Polish and English number formats.

## Installation

```ruby
gem "price_scanner"
```

## Usage

### Parse a single price

```ruby
PriceScanner.parse("1.299,00 zł")
# => { amount: 1299.0, currency: "PLN", text: "1.299,00 zł" }

PriceScanner.parse("£49.99")
# => { amount: 49.99, currency: "GBP", text: "£49.99" }
```

### Extract all prices from text

```ruby
PriceScanner.scan("Was £49.99 Now £29.99")
# => [{ amount: 49.99, currency: "GBP", text: "£49.99" },
#     { amount: 29.99, currency: "GBP", text: "£29.99" }]
```

### Check if text contains a price

```ruby
PriceScanner.contains_price?("Only 99,00 zł")  # => true
PriceScanner.contains_price?("No price here")   # => false
```

### GDPR consent detection (optional, requires nokogiri)

```ruby
require "nokogiri"

doc = Nokogiri::HTML(html)
node = doc.css(".cookie-banner").first
PriceScanner::ConsentDetector.consent_node?(node)  # => true/false
```

### Advanced API

For finer control, use `Detector` and `Parser` modules directly.

#### Detect prices in text

```ruby
PriceScanner::Detector.contains_price?("see price: 49,00 zł")  # => true

PriceScanner::Detector.extract_prices_from_text("Was 49,00 zł, now 29,00 zł")
# => [{ text: "49,00 zł", value: 49.0, position: 4 },
#     { text: "29,00 zł", value: 29.0, position: 18 }]

PriceScanner::Detector::PRICE_PATTERN  # => Regexp matching prices
```

#### Parse and normalize prices

```ruby
PriceScanner::Parser.normalized_price("1.299,00 zł")  # => 1299.0
PriceScanner::Parser.normalized_price("$49.99")        # => 49.99

PriceScanner::Parser.extract_currency("49,00 zł")  # => "PLN"
PriceScanner::Parser.extract_currency("€120")      # => "EUR"
```

#### Strip price mentions from text

```ruby
PriceScanner::Parser.strip_price_mentions("Buy for 49,00 zł or 59,00 zł", "49,00 zł", "59,00 zł")
# => "Buy for or"
```

#### Build a regex for a specific price value

```ruby
PriceScanner::Parser.price_regex_from_value("1.299,00 zł")
# => Regexp matching variations like "1 299,00 zł", "1299,00zł", etc.
```

## Supported currencies

| Currency | Symbol | Code | Example input | Parsed |
|----------|--------|------|---------------|--------|
| PLN | `zł`, `zl` | `PLN` | `1.299,00 zł` | 1299.0 |
| EUR | `€` | `EUR` | `€99,00` | 99.0 |
| USD | `$` | `USD` | `$1,019.00` | 1019.0 |
| GBP | `£` | `GBP` | `£49.99` | 49.99 |

Currency symbols and codes are matched case-insensitively (`pln`, `PLN`, `Pln` all work).

## Supported number formats

| Format | Example | Parsed |
|--------|---------|--------|
| Dot thousands, comma decimal (Polish) | `1.299,00 zł` | 1299.0 |
| Space thousands, comma decimal | `1 299,00 zł` | 1299.0 |
| NBSP thousands, comma decimal | `1\u00a0299,00 zł` | 1299.0 |
| Comma thousands, dot decimal (English) | `$1,299.00` | 1299.0 |
| No thousands separator | `799,00 zł` | 799.0 |
| Integer (no decimals) | `£150` | 150.0 |
| Currency before amount | `zł 248,86` | 248.86 |

## Smart filtering

Prices that match the following patterns are automatically excluded from results:

### Negative prices

Prices preceded by `-` or `−` (U+2212) are treated as discount badges and filtered out.

```ruby
PriceScanner.scan("449,00 zł -100,00 zł 349,00 zł")
# => [{ amount: 449.0, ... }, { amount: 349.0, ... }]
# -100,00 zł is excluded
```

### Price ranges

Two prices connected by an en-dash (`–`, `—`) or spaced hyphen (` - `) are recognized as a range and both are removed.

```ruby
PriceScanner.scan("Size S–XL, £3.29 – £92.71, buy now for £49.99")
# => [{ amount: 49.99, currency: "GBP", text: "£49.99" }]
# range £3.29 – £92.71 is excluded
```

### Savings amounts

When 3+ prices are detected and one equals the difference between two others (within ±2% tolerance), the savings amount is removed.

```ruby
PriceScanner.scan("Was 449,00 zł, now 349,00 zł. You save 100,00 zł!")
# => [{ amount: 449.0, ... }, { amount: 349.0, ... }]
# 100,00 zł is excluded (449 - 349 = 100)
```

### Per-unit prices

Prices followed by a unit indicator are filtered out.

Supported units: `kg`, `g`, `mg`, `l`, `ml`, `szt`, `m`, `m²`, `m³`, `cm`, `mm`, `op`, `opak`, `pcs`, `pc`, `unit`, `each`, `ea`, `kaps`, `tabl`, `tab`

Recognized prefixes: `/` (slash) and `za` (Polish "per").

```ruby
PriceScanner.scan("32,74 zł/kg — buy 500g for 16,37 zł")
# => [{ amount: 16.37, currency: "PLN", text: "16,37 zł" }]
# 32,74 zł/kg is excluded
```

### Deduplication

If the same price value appears multiple times, only one occurrence is kept.

## Features

- **Zero dependencies** (nokogiri optional, only for consent detection)
- Case-insensitive currency matching
- Handles regular spaces, non-breaking spaces (NBSP), and mixed whitespace
- Tracks position of each price in the source text
- Ignores letter-preceded numbers to avoid false positives from product codes (e.g. `DKA2zł`)

## Used by

- [snipe.sale](https://snipe.sale) — price tracking service processing thousands of product pages daily

## License

MIT License. See [LICENSE](LICENSE).
