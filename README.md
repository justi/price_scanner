# PriceScanner

Battle-tested multi-currency price extraction from text. Supports PLN, EUR, GBP, USD with Polish and English number formats.

Extracted from [snipe.sale](https://snipe.sale) — a price tracking service processing thousands of product pages daily.

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

## Features

- **Multi-currency**: PLN (zł), EUR (€), GBP (£), USD ($)
- **Number formats**: Polish (`1.299,00`) and English (`1,299.00`)
- **Smart filtering**: Removes negative discount badges (`-100,00 zł`), price ranges (`£3.29 – £92.71`), savings amounts, and per-unit prices (`32,74 zł/kg`)
- **Zero dependencies** (nokogiri optional, only for consent detection)

## License

MIT License. See [LICENSE](LICENSE).
