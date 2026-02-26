# frozen_string_literal: true

RSpec.describe PriceScanner do
  describe ".parse" do
    it "parses a Polish price" do
      result = described_class.parse("1.299,00 zł")
      expect(result).to eq({ amount: 1299.0, currency: "PLN", text: "1.299,00 zł" })
    end

    it "parses a British price" do
      result = described_class.parse("£49.99")
      expect(result).to eq({ amount: 49.99, currency: "GBP", text: "£49.99" })
    end

    it "returns nil for text without prices" do
      expect(described_class.parse("No price here")).to be_nil
    end

    it "returns only the first price" do
      result = described_class.parse("Was £49.99 now £29.99")
      expect(result[:amount]).to be_within(0.01).of(49.99)
    end
  end

  describe ".scan" do
    it "extracts multiple prices" do
      results = described_class.scan("Was £49.99 Now £29.99")
      expect(results.size).to eq(2)
      expect(results.map { |r| r[:amount] }.sort).to eq([29.99, 49.99])
      expect(results.map { |r| r[:currency] }.uniq).to eq(["GBP"])
    end

    it "returns empty array for text without prices" do
      expect(described_class.scan("No price here")).to eq([])
    end

    it "handles mixed currencies" do
      results = described_class.scan("€99,00 or £85.00")
      expect(results.size).to eq(2)
      currencies = results.map { |r| r[:currency] }.sort
      expect(currencies).to eq(%w[EUR GBP])
    end
  end

  describe ".contains_price?" do
    it "returns true when text contains a price" do
      expect(described_class.contains_price?("Only 99,00 zł")).to be true
    end

    it "returns false when text has no price" do
      expect(described_class.contains_price?("No price here")).to be false
    end
  end

  it "has a version number" do
    expect(PriceScanner::VERSION).not_to be_nil
  end
end
