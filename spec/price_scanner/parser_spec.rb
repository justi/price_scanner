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

  describe ".split_price_parts" do
    it "splits simple price into integer and decimals" do
      expect(described_class.split_price_parts(99.0)).to eq(%w[99 00])
    end

    it "splits price with cents" do
      expect(described_class.split_price_parts(49.99)).to eq(%w[49 99])
    end

    it "splits large price" do
      expect(described_class.split_price_parts(12_345.67)).to eq(%w[12345 67])
    end
  end

  describe ".thousands_groups" do
    it "returns single group for small numbers" do
      expect(described_class.thousands_groups("99")).to eq(%w[99])
    end

    it "splits 4-digit number into two groups" do
      expect(described_class.thousands_groups("1299")).to eq(%w[1 299])
    end

    it "splits 5-digit number correctly" do
      expect(described_class.thousands_groups("12345")).to eq(%w[12 345])
    end

    it "splits 7-digit number into three groups" do
      expect(described_class.thousands_groups("1234567")).to eq(%w[1 234 567])
    end
  end

  describe ".thousands_pattern" do
    it "returns digits for small numbers" do
      expect(described_class.thousands_pattern("99")).to eq("99")
    end

    it "joins groups with optional separator" do
      pattern = described_class.thousands_pattern("1299")
      expect(pattern).to eq("1[\\s\\u00a0]?299")
    end
  end

  describe ".price_regex_from_value" do
    it "matches PLN price format" do
      regex = described_class.price_regex_from_value(99.0)
      expect("99,00 zł").to match(regex)
      expect("99.00 pln").to match(regex)
    end

    it "matches EUR price format" do
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
