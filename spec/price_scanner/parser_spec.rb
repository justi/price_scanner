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

    it "extracts currency from text code (PLN, EUR)" do
      expect(described_class.extract_currency("99.00 PLN")).to eq("PLN")
      expect(described_class.extract_currency("99.00 eur")).to eq("EUR")
    end
  end

  describe ".strip_price_mentions" do
    it "removes price text from string" do
      result = described_class.strip_price_mentions("Cena: 99,00 zł rabat", "99,00 zł")
      expect(result).to eq("Cena: rabat")
    end

    it "removes multiple prices" do
      result = described_class.strip_price_mentions("Old 199,00 zł New 99,00 zł", "199,00 zł", "99,00 zł")
      expect(result).to eq("Old New")
    end

    it "removes NBSP variants of price" do
      result = described_class.strip_price_mentions("Cena: 99,00\u00a0zł ok", "99,00 zł")
      expect(result).to eq("Cena: ok")
    end

    it "handles nil prices in list" do
      result = described_class.strip_price_mentions("Cena: 99,00 zł", nil, "99,00 zł")
      expect(result).to eq("Cena:")
    end

    it "returns original text when no prices match" do
      result = described_class.strip_price_mentions("No price here", "99,00 zł")
      expect(result).to eq("No price here")
    end
  end

  describe ".price_regex_from_value" do
    it "builds regex matching PLN price format" do
      regex = described_class.price_regex_from_value(99.0)
      expect("99,00 zł").to match(regex)
      expect("99.00 pln").to match(regex)
    end

    it "builds regex matching EUR price format" do
      regex = described_class.price_regex_from_value(49.99)
      expect("49,99 eur").to match(regex)
      expect("49.99 gbp").to match(regex)
    end

    it "handles thousands with optional separator" do
      regex = described_class.price_regex_from_value(1299.0)
      expect("1299,00 zł").to match(regex)
      expect("1 299,00").to match(regex)
    end
  end
end
