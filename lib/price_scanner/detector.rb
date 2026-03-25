# frozen_string_literal: true

module PriceScanner
  # Extracts prices from text using regex patterns with smart filtering.
  module Detector
    # Space chars used as thousand separators: regular space, NBSP (\u00a0), narrow NBSP (\u202f)
    SP = "[\\s\\u00a0\\u202f]"

    PRICE_PATTERN = /
      (?:zł|pln|€|\$|£)#{SP}*(?:\d{1,3}(?:[.,#{SP}]\d{3})+|\d{1,4})(?:[.,]\d{1,2})?  |
      (?<![a-zA-Z\d])(?:\d{1,3}(?:[.,#{SP}]\d{3})+|\d{1,4})[.,]\d{2}#{SP}*(?:zł|pln|€|\$|£|eur|usd|gbp)(?!\d)  |
      (?<![a-zA-Z\d])(?:\d{1,3}(?:[.,#{SP}]\d{3})+|\d{1,4})#{SP}*(?:zł|pln|€|\$|£)(?!\d)
    /ix

    PER_UNIT_PATTERN = %r{(?:/\s*|za\s+)(?:kg|g|mg|l|ml|szt|m[²³23]?|cm|mm|op|opak|pcs|pc|unit|each|ea|kaps|tabl|tab)\b}i
    PER_UNIT_ANCHOR = /\A#{PER_UNIT_PATTERN.source}/i

    NEGATIVE_PREFIXES = ["-", "\u2212"].freeze

    # Prefixes that indicate the following price is a savings amount, not a product price.
    # "Oszczędzasz 6.40 PLN" = "You save 6.40 PLN" — not the product price.
    SAVINGS_PREFIX_PATTERN = /(?:oszcz[eę]dzasz|zaoszcz[eę]d[zź]|you\s+save|sie\s+sparen)\s*:?\s*\z/i

    RANGE_SEPARATOR_PATTERN = /\s*[–—]\s*|\s+-\s+/

    TEXT_AFTER_LOOKAHEAD = 200
    MIN_PRICES_FOR_RANGE = 2
    MIN_PRICES_FOR_SAVINGS = 3
    SAVINGS_MIN_RATIO = 0.1
    SAVINGS_MIN_DIFF = 0.01
    SAVINGS_TOLERANCE_RATIO = 0.02
    SAVINGS_TOLERANCE_MIN = 1.0

    module_function

    def extract_prices_from_text(text, include_per_unit: false)
      text_str = text.to_s
      raw_prices = scan_raw_prices(text_str, include_per_unit: include_per_unit)
      filtered = filter_range_prices(raw_prices, text_str)
      unique = filtered.uniq { |price| price[:value] }
      filter_savings_by_difference(unique)
    end

    def contains_price?(text)
      text.to_s.match?(PRICE_PATTERN)
    end

    def scan_raw_prices(text_str, include_per_unit: false)
      results = []
      last_end = 0

      text_str.scan(PRICE_PATTERN) do |match_str|
        result, last_end = find_price_at(text_str, match_str, last_end, include_per_unit: include_per_unit)
        results << result if result
      end

      results
    end

    def find_price_at(text_str, match_str, search_from, include_per_unit: false)
      return [nil, search_from] if match_str.empty?

      match_index = text_str.index(match_str, search_from)
      return [nil, search_from] unless match_index

      match_end = match_index + match_str.length
      [build_price_result(text_str, match_str, match_index, include_per_unit: include_per_unit), match_end]
    end

    def build_price_result(text_str, match_str, match_index, include_per_unit: false)
      value = Parser.normalized_price(match_str)
      return unless value

      return if negative_price?(text_str, match_index)
      return if savings_prefix?(text_str, match_index)
      return if !include_per_unit && per_unit_price?(text_str, match_index + match_str.length)

      clean_text = match_str.gsub(Parser::COLLAPSE_WHITESPACE, " ").strip
      { text: clean_text, value: value, position: match_index }
    end

    def negative_price?(text_str, match_index)
      return false unless match_index.positive?

      # Find the non-whitespace char before price: "-1.040" or "- 1.040"
      dash_pos = rindex_non_space(text_str, match_index - 1)
      return false unless dash_pos && NEGATIVE_PREFIXES.include?(text_str[dash_pos])

      # Dash at start of text = negative; after digit = range separator ("3 - 29,99")
      before_dash = rindex_non_space(text_str, dash_pos - 1)
      before_dash.nil? || text_str[before_dash] !~ /\d/
    end

    def rindex_non_space(text_str, from)
      i = from
      i -= 1 while i >= 0 && text_str[i] =~ /\s/
      i >= 0 ? i : nil
    end

    # Check if text before the price contains a savings prefix like "Oszczędzasz" or "You save"
    def savings_prefix?(text_str, match_index)
      return false unless match_index > 3

      # Look at up to 30 chars before the price match
      lookback_start = [match_index - 30, 0].max
      text_before = text_str[lookback_start...match_index]
      text_before.match?(SAVINGS_PREFIX_PATTERN)
    end

    def per_unit_price?(text_str, match_end)
      text_after = text_str[match_end, TEXT_AFTER_LOOKAHEAD].to_s.gsub(Parser::COLLAPSE_WHITESPACE, " ").lstrip
      text_after.match?(PER_UNIT_ANCHOR)
    end

    def filter_range_prices(prices, text)
      return prices if prices.size < MIN_PRICES_FOR_RANGE

      range_indices = find_range_indices(prices, text)
      prices.reject.with_index { |_, idx| range_indices.include?(idx) }
    end

    def find_range_indices(prices, text)
      indices = Set.new
      prices.each_cons(2).with_index do |(current, next_price), idx|
        if range_between?(current, next_price, text)
          indices << idx
          indices << (idx + 1)
        end
      end
      indices
    end

    def range_between?(current, next_price, text)
      start_pos = current[:position] + current[:text].length
      end_pos = next_price[:position]
      return false if end_pos <= start_pos

      text[start_pos...end_pos].match?(RANGE_SEPARATOR_PATTERN)
    end

    def filter_savings_by_difference(prices)
      return prices if prices.size < MIN_PRICES_FOR_SAVINGS

      values = prices.map { |entry| entry[:value] }
      min_value = values.min

      return prices unless savings_amount?(values, min_value)

      prices.zip(values).filter_map { |price, val| price unless val == min_value }
    end

    def savings_amount?(values, min_value)
      values.combination(2).any? do |first, second|
        next false if first == min_value || second == min_value

        matches_savings_pattern?((first - second).abs, min_value)
      end
    end

    def matches_savings_pattern?(diff, min_value)
      return false if diff < [min_value * SAVINGS_MIN_RATIO, SAVINGS_MIN_DIFF].max

      tolerance = [min_value * SAVINGS_TOLERANCE_RATIO, SAVINGS_TOLERANCE_MIN].max
      (min_value - diff).abs <= tolerance
    end

    private_class_method :scan_raw_prices, :find_price_at, :build_price_result,
                         :negative_price?, :rindex_non_space, :savings_prefix?, :per_unit_price?,
                         :filter_range_prices, :find_range_indices, :range_between?,
                         :filter_savings_by_difference, :savings_amount?, :matches_savings_pattern?
  end
end
