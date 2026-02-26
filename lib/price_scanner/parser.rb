# frozen_string_literal: true

module PriceScanner
  module Parser
    CURRENCY_MAP = {
      "zł" => "PLN", "pln" => "PLN",
      "€" => "EUR", "eur" => "EUR",
      "$" => "USD", "usd" => "USD",
      "£" => "GBP", "gbp" => "GBP"
    }.freeze

    module_function

    def normalized_price(value)
      text = value.to_s.tr("\u00a0", " ").strip
      return nil if text.nil? || text.empty?

      clean = text.gsub(/[^\d.,\s]/, "")
      return nil if clean.nil? || clean.empty?

      if clean.include?(",") && clean.include?(".")
        dot_pos = clean.rindex(".")
        comma_pos = clean.rindex(",")

        if comma_pos > dot_pos
          clean = clean.delete(".").tr(",", ".")
        else
          clean = clean.delete(",")
        end
      elsif clean.count(",") == 1 && !clean.include?(".")
        clean = clean.tr(",", ".")
      elsif clean.count(",") > 1 && !clean.include?(".")
        parts = clean.split(",")
        clean = "#{parts[0...-1].join}.#{parts.last}"
      end

      clean = clean.gsub(/\s/, "")

      Float(clean)
    rescue ArgumentError, TypeError
      nil
    end

    def extract_currency(value)
      return nil if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      match = value.to_s.match(/(pln|usd|eur|gbp|zł|€|\$|£)/i)
      return nil unless match

      raw = match[1]
      CURRENCY_MAP[raw.downcase] || CURRENCY_MAP[raw] || raw.upcase
    end

    def strip_price_mentions(text, *prices)
      cleaned = text.to_s.tr("\u00a0", " ")
      prices.compact.each do |price|
        next if price.to_s.strip.nil? || price.to_s.strip.empty?

        normalized = price.to_s.tr("\u00a0", " ").strip
        cleaned = cleaned.gsub(normalized, "")
        cleaned = cleaned.gsub(normalized.gsub(" ", ""), "")

        price_value = normalized_price(price)
        next if price_value.nil?

        cleaned = cleaned.gsub(price_regex_from_value(price_value), "")
      end

      cleaned.gsub(/\s{2,}/, " ").strip
    end

    def price_regex_from_value(value)
      integer, decimals = format("%.2f", value).split(".")
      groups = integer.reverse.scan(/.{1,3}/).reverse
      int_pattern = groups.join("[\\s\\u00a0]?")
      /#{int_pattern}[\\.,]#{decimals}\\s?(?:zł|zl|pln)?/i
    end
  end
end
