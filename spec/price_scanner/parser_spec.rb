# frozen_string_literal: true

RSpec.describe PriceScanner::Parser do
  describe ".normalized_price" do
    it "normalizes simple Polish price (99,00)" do
      expect(described_class.normalized_price("99,00 zł")).to be_within(0.01).of(99.0)
    end

    it "normalizes Polish price with dot thousands separator (1.019,00)" do
      expect(described_class.normalized_price("1.019,00 zł")).to be_within(0.01).of(1019.0)
    end

    it "normalizes Polish price with space thousands separator (1 019,00)" do
      expect(described_class.normalized_price("1 019,00 zł")).to be_within(0.01).of(1019.0)
    end

    it "normalizes English price with comma thousands separator (1,019.00)" do
      expect(described_class.normalized_price("$1,019.00")).to be_within(0.01).of(1019.0)
    end

    it "normalizes large Polish price (12.345,67)" do
      expect(described_class.normalized_price("12.345,67 zł")).to be_within(0.01).of(12_345.67)
    end

    it "normalizes large English price (12,345.67)" do
      expect(described_class.normalized_price("$12,345.67")).to be_within(0.01).of(12_345.67)
    end

    it "returns nil for blank value" do
      expect(described_class.normalized_price("")).to be_nil
      expect(described_class.normalized_price(nil)).to be_nil
    end

    it "returns nil for text without numbers" do
      expect(described_class.normalized_price("zł")).to be_nil
    end
  end

  describe ".extract_currency" do
    it "extracts PLN from zł symbol" do
      expect(described_class.extract_currency("99,00 zł")).to eq("PLN")
    end

    it "extracts GBP from £ symbol" do
      expect(described_class.extract_currency("£49.99")).to eq("GBP")
    end

    it "extracts EUR from € symbol" do
      expect(described_class.extract_currency("€19.99")).to eq("EUR")
    end

    it "extracts USD from $ symbol" do
      expect(described_class.extract_currency("$29.99")).to eq("USD")
    end

    it "returns nil for no currency" do
      expect(described_class.extract_currency("just text")).to be_nil
    end

    it "returns nil for nil input" do
      expect(described_class.extract_currency(nil)).to be_nil
    end
  end
end
