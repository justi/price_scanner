# frozen_string_literal: true

require_relative "price_scanner/version"
require_relative "price_scanner/parser"
require_relative "price_scanner/detector"

module PriceScanner
  module_function

  def parse(text)
    prices = Detector.extract_prices_from_text(text)
    return nil if prices.empty?

    price = prices.first
    currency = Parser.extract_currency(price[:text])
    { amount: price[:value], currency: currency, text: price[:text] }
  end

  def scan(text)
    prices = Detector.extract_prices_from_text(text)
    prices.map do |price|
      currency = Parser.extract_currency(price[:text])
      { amount: price[:value], currency: currency, text: price[:text] }
    end
  end

  def contains_price?(text)
    Detector.contains_price?(text)
  end
end
