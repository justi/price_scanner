# frozen_string_literal: true

module PriceScanner
  # Normalizes price strings into floats and extracts currency codes.
  module Parser
    CURRENCY_MAP = {
      "zł" => "PLN", "pln" => "PLN", "zl" => "PLN",
      "€" => "EUR", "eur" => "EUR",
      "$" => "USD", "usd" => "USD",
      "£" => "GBP", "gbp" => "GBP"
    }.freeze

    CURRENCY_SYMBOLS = CURRENCY_MAP.keys.map { |key| Regexp.escape(key) }.freeze
    CURRENCY_REGEX = /(#{CURRENCY_SYMBOLS.join("|")})/i
    CURRENCY_SUFFIX = /(?:#{CURRENCY_SYMBOLS.join("|")})/i

    MULTIPLE_SPACES = /\s{2,}/
    COLLAPSE_WHITESPACE = /\s+/
    NBSP = "\u00a0"
    DECIMAL_PLACES = 2
    THOUSANDS_GROUP = /.{1,3}/

    module_function

    def normalized_price(value)
      text = value.to_s.tr(NBSP, " ").strip
      return nil if text.empty?

      clean = clean_price_text(text)
      return nil unless clean

      Float(clean)
    rescue ArgumentError, TypeError
      nil
    end

    def extract_currency(value)
      text = value.to_s
      return nil if text.empty?

      match = text.match(CURRENCY_REGEX)
      resolve_currency(match)
    end

    def strip_price_mentions(text, *prices)
      cleaned = text.to_s.tr(NBSP, " ")
      prices.compact.each do |price|
        cleaned = strip_single_price(cleaned, price)
      end
      cleaned.gsub(MULTIPLE_SPACES, " ").strip
    end

    def price_regex_from_value(value)
      integer, decimals = split_price_parts(value)
      int_pattern = thousands_pattern(integer)
      /#{int_pattern}[.,]#{decimals}\s?#{CURRENCY_SUFFIX.source}?/i
    end

    def split_price_parts(value)
      format("%.#{DECIMAL_PLACES}f", value).split(".")
    end

    def thousands_groups(integer)
      integer.reverse.scan(THOUSANDS_GROUP).map(&:reverse).reverse
    end

    def thousands_pattern(integer)
      thousands_groups(integer).join("[\\s\\u00a0]?")
    end

    def clean_price_text(text)
      digits = text.gsub(/[^\d.,\s]/, "")
      return nil if digits.empty?

      normalize_separators(digits).gsub(/\s/, "")
    end

    def resolve_currency(match)
      return nil unless match

      symbol = match[1]
      CURRENCY_MAP.fetch(symbol.downcase, symbol.upcase)
    end

    def strip_single_price(cleaned, price)
      normalized = price.to_s.tr(NBSP, " ").strip
      return cleaned if normalized.empty?

      result = cleaned.gsub(normalized, "").gsub(normalized.delete(" "), "")
      price_value = normalized_price(price)
      return result unless price_value

      result.gsub(price_regex_from_value(price_value), "")
    end

    def normalize_separators(clean)
      return clean unless clean.include?(",")

      if clean.include?(".")
        resolve_mixed_separators(clean)
      else
        resolve_comma_only(clean)
      end
    end

    def resolve_mixed_separators(clean)
      if clean.rindex(",") > clean.rindex(".")
        clean.delete(".").tr(",", ".")
      else
        clean.delete(",")
      end
    end

    def resolve_comma_only(clean)
      parts = clean.split(",")
      if parts.size == 2
        clean.tr(",", ".")
      else
        "#{parts[0...-1].join}.#{parts.last}"
      end
    end

    private_class_method :clean_price_text, :resolve_currency, :strip_single_price,
                         :normalize_separators, :resolve_mixed_separators,
                         :resolve_comma_only
  end
end
