# frozen_string_literal: true

RSpec.describe PriceScanner::Detector do
  describe "PRICE_PATTERN" do
    it "matches price with dot as thousands separator (1.019,00 zł)" do
      expect("1.019,00 zł").to match(described_class::PRICE_PATTERN)
    end

    it "matches price with space as thousands separator (1 019,00 zł)" do
      expect("1 019,00 zł").to match(described_class::PRICE_PATTERN)
    end

    it "matches simple price without thousands (799,00 zł)" do
      expect("799,00 zł").to match(described_class::PRICE_PATTERN)
    end

    it "matches price with currency prefix (zł 248,86)" do
      expect("zł 248,86").to match(described_class::PRICE_PATTERN)
    end

    it "matches euro price (€1 234)" do
      expect("€1 234").to match(described_class::PRICE_PATTERN)
    end

    it "does not match price preceded by letters (DKA2zł)" do
      matches = "DKA2zł".scan(described_class::PRICE_PATTERN).flatten.compact
      expect(matches).to be_empty
    end
  end

  describe ".extract_prices_from_text" do
    it "extracts full price with dot thousands separator" do
      prices = described_class.extract_prices_from_text("Cena: 1.019,00 zł")
      expect(prices.size).to eq(1)
      expect(prices.first[:text]).to eq("1.019,00 zł")
      expect(prices.first[:value]).to be_within(0.01).of(1019.0)
    end

    it "extracts full price with space thousands separator" do
      prices = described_class.extract_prices_from_text("Cena: 1 019,00 zł")
      expect(prices.size).to eq(1)
      expect(prices.first[:text]).to eq("1 019,00 zł")
      expect(prices.first[:value]).to be_within(0.01).of(1019.0)
    end

    it "extracts multiple prices with different formats" do
      text = "Stara cena: 1.019,00 zł, Nowa cena: 799,00 zł"
      prices = described_class.extract_prices_from_text(text)

      expect(prices.size).to eq(2)
      values = prices.map { |p| p[:value] }.sort
      expect(values[0]).to be_within(0.01).of(799.0)
      expect(values[1]).to be_within(0.01).of(1019.0)
    end

    it "ignores negative prices (discount badges like -100,00 zł)" do
      text = "449,00 zł -100,00 zł 349,00 zł"
      prices = described_class.extract_prices_from_text(text)

      values = prices.map { |p| p[:value] }.sort
      expect(values.size).to eq(2)
      expect(values[0]).to be_within(0.01).of(349.0)
      expect(values[1]).to be_within(0.01).of(449.0)
    end

    it "ignores negative prices with en-dash (−100,00 zł)" do
      text = "449,00 zł \u2212100,00 zł 349,00 zł"
      prices = described_class.extract_prices_from_text(text)

      values = prices.map { |p| p[:value] }.sort
      expect(values.size).to eq(2)
      expect(values[0]).to be_within(0.01).of(349.0)
      expect(values[1]).to be_within(0.01).of(449.0)
    end

    it "extracts price at beginning of text (no preceding char)" do
      text = "349,00 zł"
      prices = described_class.extract_prices_from_text(text)

      expect(prices.size).to eq(1)
      expect(prices.first[:value]).to be_within(0.01).of(349.0)
    end

    context "with savings detection" do
      it "filters savings amount that equals difference of other prices" do
        text = "449,00 zł 349,00 zł 100,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(349.0)
        expect(values[1]).to be_within(0.01).of(449.0)
      end

      it "filters savings with tolerance for rounding (99 instead of 100)" do
        text = "449,00 zł 349,00 zł 99,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(349.0)
        expect(values[1]).to be_within(0.01).of(449.0)
      end

      it "keeps all prices when none equals difference (no savings badge)" do
        text = "500,00 zł 300,00 zł 150,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(3)
        expect(values[0]).to be_within(0.01).of(150.0)
        expect(values[1]).to be_within(0.01).of(300.0)
        expect(values[2]).to be_within(0.01).of(500.0)
      end

      it "keeps both prices when only 2 prices present" do
        text = "449,00 zł 349,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(349.0)
        expect(values[1]).to be_within(0.01).of(449.0)
      end
    end

    context "with real-world cases" do
      it "Ohbutik with discount badge -100 zł" do
        text = "449,00 zł -100,00 zł 349,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(349.0)
        expect(values[1]).to be_within(0.01).of(449.0)
      end

      it "percentage badge before prices (25% zniżki)" do
        text = "25% zniżki 100,00 zł 75,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(75.0)
        expect(values[1]).to be_within(0.01).of(100.0)
      end

      it "savings badge with text (Zaoszczędź 25 zł)" do
        text = "Zaoszczędź 25,00 zł 100,00 zł 75,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(75.0)
        expect(values[1]).to be_within(0.01).of(100.0)
      end

      it "multiple unit prices (per 50cm and per meter)" do
        text = "15,00 zł / 50cm 20,00 zł 30,00 zł/mb"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(3)
      end

      it "euro prices with savings" do
        text = "€99,00 €79,00 €20,00"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(79.0)
        expect(values[1]).to be_within(0.01).of(99.0)
      end

      it "British pounds with savings" do
        text = "£150 £120 £30"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(2)
        expect(values[0]).to be_within(0.01).of(120.0)
        expect(values[1]).to be_within(0.01).of(150.0)
      end

      it "does not filter when smallest is legitimate third price" do
        text = "200,00 zł 100,00 zł 40,00 zł"
        prices = described_class.extract_prices_from_text(text)

        values = prices.map { |p| p[:value] }.sort
        expect(values.size).to eq(3)
      end
    end
  end

  describe ".contains_price?" do
    it "returns true when text contains a price" do
      expect(described_class.contains_price?("Cena: 99,00 zł")).to be true
    end

    it "returns false when text has no price" do
      expect(described_class.contains_price?("No price here")).to be false
    end
  end
end
