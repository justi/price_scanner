# frozen_string_literal: true

module PriceScanner
  # Normalizes price strings into floats and extracts currency codes.
  module Parser
    CURRENCY_MAP = {
      "zł" => "PLN", "pln" => "PLN",
      "€" => "EUR", "eur" => "EUR",
      "$" => "USD", "usd" => "USD",
      "£" => "GBP", "gbp" => "GBP"
    }.freeze

    CURRENCY_REGEX = /(pln|usd|eur|gbp|zł|€|\$|£)/i
    CURRENCY_SUFFIX = /(?:zł|zl|pln|€|eur|\$|usd|£|gbp)/i
    MULTIPLE_SPACES = /\s{2,}/
    NBSP = "\u00a0"
    DECIMAL_PLACES = 2
    THOUSANDS_GROUP = /.{1,3}/

    module_function

    def normalized_price(value)
      text = value.to_s.tr(NBSP, " ").strip
      return nil if text.empty?

      clean = text.gsub(/[^\d.,\s]/, "")
      return nil if clean.empty?

      clean = normalize_separators(clean).gsub(/\s/, "")
      Float(clean)
    rescue ArgumentError, TypeError
      nil
    end

    def extract_currency(value)
      text = value.to_s
      return nil if text.empty?

      match = text.match(CURRENCY_REGEX)
      return nil unless match

      CURRENCY_MAP.fetch(match[1].downcase, match[1].upcase)
    end

    def strip_price_mentions(text, *prices)
      cleaned = text.to_s.tr(NBSP, " ")
      prices.compact.each do |price|
        normalized = price.to_s.tr(NBSP, " ").strip
        next if normalized.empty?

        cleaned = cleaned.gsub(normalized, "").gsub(normalized.delete(" "), "")

        price_value = normalized_price(price)
        next unless price_value

        cleaned = cleaned.gsub(price_regex_from_value(price_value), "")
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

    def normalize_separators(clean)
      has_dot = clean.include?(".")
      comma_count = clean.count(",")

      if comma_count.positive? && has_dot
        resolve_mixed_separators(clean)
      elsif comma_count == 1 && !has_dot
        clean.tr(",", ".")
      elsif comma_count > 1 && !has_dot
        parts = clean.split(",")
        "#{parts[0...-1].join}.#{parts.last}"
      else
        clean
      end
    end

    def resolve_mixed_separators(clean)
      if clean.rindex(",") > clean.rindex(".")
        clean.delete(".").tr(",", ".")
      else
        clean.delete(",")
      end
    end

    private_class_method :normalize_separators, :resolve_mixed_separators
  end
end
