# frozen_string_literal: true

module PriceScanner
  module Detector
    CURRENCIES = {
      pln: { symbols: %w[zł PLN], code: "PLN" },
      eur: { symbols: %w[€ EUR eur], code: "EUR" },
      usd: { symbols: %w[$ USD usd], code: "USD" },
      gbp: { symbols: %w[£ GBP gbp], code: "GBP" }
    }.freeze

    PRICE_PATTERN = /
      (?:zł|pln|€|\$|£)[\s\u00a0]*(?:\d{1,3}(?:[.\s\u00a0]\d{3})+|\d{1,4})(?:[.,]\d{1,2})?  |
      (?<![a-zA-Z])(?:\d{1,3}(?:[.\s\u00a0]\d{3})+|\d{1,4})[.,]\d{2}[\s\u00a0]*(?:zł|pln|€|\$|£|eur|usd|gbp)(?!\d)  |
      (?<![a-zA-Z])(?:\d{1,3}(?:[.\s\u00a0]\d{3})+|\d{1,4})[\s\u00a0]*(?:zł|pln|€|\$|£)(?!\d)
    /ix

    PER_UNIT_PATTERN = %r{(?:/\s*|za\s+)(?:kg|g|mg|l|ml|szt|m[²³23]?|cm|mm|op|opak|pcs|pc|unit|each|ea|kaps|tabl|tab)\b}i

    RANGE_SEPARATOR_PATTERN = /\s*[–—]\s*|\s+-\s+/

    module_function

    def extract_prices_from_text(text)
      text_str = text.to_s
      results = []
      last_end = 0

      text_str.scan(PRICE_PATTERN) do |match|
        match_str = match.is_a?(Array) ? match.first : match
        next if match_str.nil? || match_str.empty?

        match_index = text_str.index(match_str, last_end)
        next unless match_index

        last_end = match_index + match_str.length

        value = Parser.normalized_price(match_str)
        next if value.nil?

        if match_index.positive?
          char_before = text_str[match_index - 1]
          next if char_before == "-" || char_before == "\u2212"
        end

        text_after = text_str[last_end, 200].to_s.gsub(/\s+/, " ").lstrip
        next if text_after.match?(/\A#{PER_UNIT_PATTERN.source}/i)

        clean_text = match_str.gsub(/\s+/, " ").strip
        results << { text: clean_text, value: value, position: match_index }
      end

      results = filter_range_prices(results, text_str)
      results = results.uniq { |price| price[:value] }
      filter_savings_by_difference(results)
    end

    def contains_price?(text)
      text.to_s.match?(PRICE_PATTERN)
    end

    def filter_range_prices(prices, text)
      return prices if prices.size < 2

      range_positions = Set.new

      prices.each_with_index do |price, i|
        next_price = prices[i + 1]
        next unless next_price

        start_pos = price[:position] + price[:text].length
        end_pos = next_price[:position]

        next if end_pos <= start_pos

        between_text = text[start_pos...end_pos]

        if between_text.match?(RANGE_SEPARATOR_PATTERN)
          range_positions << i
          range_positions << (i + 1)
        end
      end

      prices.each_with_index.reject { |_, i| range_positions.include?(i) }.map(&:first)
    end

    def filter_savings_by_difference(prices)
      return prices if prices.size < 3

      values = prices.map { |p| p[:value] }
      min_value = values.min

      is_savings = values.combination(2).any? do |a, b|
        next false if a == min_value || b == min_value

        diff = (a - b).abs
        next false if diff < [min_value * 0.1, 0.01].max

        tolerance = [min_value * 0.02, 1.0].max
        (min_value - diff).abs <= tolerance
      end

      is_savings ? prices.reject { |p| p[:value] == min_value } : prices
    end

    private_class_method :filter_range_prices, :filter_savings_by_difference
  end
end
