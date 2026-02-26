# frozen_string_literal: true

RSpec.describe PriceScanner::Detector do
  def extract_values(text)
    described_class.extract_prices_from_text(text).map { |p| p[:value] }.sort
  end

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
      values = extract_values("Stara cena: 1.019,00 zł, Nowa cena: 799,00 zł")
      expect(values).to eq([799.0, 1019.0])
    end

    it "ignores negative prices (discount badges like -100,00 zł)" do
      values = extract_values("449,00 zł -100,00 zł 349,00 zł")
      expect(values).to eq([349.0, 449.0])
    end

    it "ignores negative prices with en-dash (\u2212100,00 zł)" do
      values = extract_values("449,00 zł \u2212100,00 zł 349,00 zł")
      expect(values).to eq([349.0, 449.0])
    end

    it "extracts price at beginning of text (no preceding char)" do
      values = extract_values("349,00 zł")
      expect(values).to eq([349.0])
    end

    context "with savings detection" do
      it "filters savings amount that equals difference of other prices" do
        values = extract_values("449,00 zł 349,00 zł 100,00 zł")
        expect(values).to eq([349.0, 449.0])
      end

      it "filters savings with tolerance for rounding (99 instead of 100)" do
        values = extract_values("449,00 zł 349,00 zł 99,00 zł")
        expect(values).to eq([349.0, 449.0])
      end

      it "keeps all prices when none equals difference (no savings badge)" do
        values = extract_values("500,00 zł 300,00 zł 150,00 zł")
        expect(values).to eq([150.0, 300.0, 500.0])
      end

      it "keeps both prices when only 2 prices present" do
        values = extract_values("449,00 zł 349,00 zł")
        expect(values).to eq([349.0, 449.0])
      end
    end

    context "with real-world cases" do
      it "percentage badge before prices (25% zniżki)" do
        values = extract_values("25% zniżki 100,00 zł 75,00 zł")
        expect(values).to eq([75.0, 100.0])
      end

      it "savings badge with text (Zaoszczędź 25 zł)" do
        values = extract_values("Zaoszczędź 25,00 zł 100,00 zł 75,00 zł")
        expect(values).to eq([75.0, 100.0])
      end

      it "multiple unit prices (per 50cm and per meter)" do
        values = extract_values("15,00 zł / 50cm 20,00 zł 30,00 zł/mb")
        expect(values).to eq([15.0, 20.0, 30.0])
      end

      it "euro prices with savings" do
        values = extract_values("€99,00 €79,00 €20,00")
        expect(values).to eq([79.0, 99.0])
      end

      it "British pounds with savings" do
        values = extract_values("£150 £120 £30")
        expect(values).to eq([120.0, 150.0])
      end

      it "does not filter when smallest is legitimate third price" do
        values = extract_values("200,00 zł 100,00 zł 40,00 zł")
        expect(values).to eq([40.0, 100.0, 200.0])
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
