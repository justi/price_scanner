# frozen_string_literal: true

Dir.glob(File.join(__dir__, "price_scanner", "*.rb")).each { |f| require_relative f }

# Multi-currency price extraction from text.
module PriceScanner
  module_function

  def parse(text)
    prices = Detector.extract_prices_from_text(text)
    return nil if prices.empty?

    build_result(prices.first)
  end

  def scan(text)
    Detector.extract_prices_from_text(text).map { |price| build_result(price) }
  end

  def contains_price?(text)
    Detector.contains_price?(text)
  end

  def build_result(price)
    price_text = price[:text]
    { amount: price[:value], currency: Parser.extract_currency(price_text), text: price_text }
  end

  private_class_method :build_result
end
