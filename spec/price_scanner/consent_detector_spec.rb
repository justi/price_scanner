# frozen_string_literal: true

require "nokogiri"

RSpec.describe PriceScanner::ConsentDetector do
  def parse_html(html)
    Nokogiri::HTML(html)
  end

  describe ".consent_node?" do
    context "when false positives (should NOT detect as consent)" do
      it "does not detect product with 'ciasteczkowa' (cookie-colored)" do
        html = <<~HTML
          <div class="product">
            <a href="/yarn">Przędza SOFT tęcza ciasteczkowa / szpula ~ 0,5 kg</a>
            <span class="price">49,00 zł</span>
          </div>
        HTML
        element = parse_html(html).css(".product").first
        expect(described_class.consent_node?(element)).to be false
      end

      it "does not detect brand name containing 'OK'" do
        html = <<~HTML
          <div class="product">
            <a href="/product">KOKONKI Premium Yarn</a>
            <button>Do koszyka</button>
          </div>
        HTML
        element = parse_html(html).css(".product").first
        expect(described_class.consent_node?(element)).to be false
      end

      it "does not detect product with 'zgoda' in name" do
        html = <<~HTML
          <div class="product">
            <a href="/book">Książka o zgodzie narodów</a>
            <span class="price">29,00 zł</span>
          </div>
        HTML
        element = parse_html(html).css(".product").first
        expect(described_class.consent_node?(element)).to be false
      end

      it "does not detect 'continue shopping' button" do
        html = <<~HTML
          <div class="cart">
            <p>Twój koszyk jest pusty</p>
            <a href="/shop" class="btn">Kontynuuj zakupy</a>
          </div>
        HTML
        element = parse_html(html).css(".cart").first
        expect(described_class.consent_node?(element)).to be false
      end
    end

    context "when true positives (SHOULD detect as consent)" do
      it "detects cookie banner with accept button" do
        html = <<~HTML
          <div class="cookie-banner">
            <p>Ta strona używa ciasteczek</p>
            <button>Akceptuj</button>
          </div>
        HTML
        element = parse_html(html).css(".cookie-banner").first
        expect(described_class.consent_node?(element)).to be true
      end

      it "detects GDPR consent dialog" do
        html = <<~HTML
          <div id="gdpr-consent">
            <p>Prosimy o zgodę na przetwarzanie danych</p>
            <button>Zgadzam się</button>
          </div>
        HTML
        element = parse_html(html).css("#gdpr-consent").first
        expect(described_class.consent_node?(element)).to be true
      end

      it "detects cookie consent by class attribute" do
        html = <<~HTML
          <div class="cookiebot-banner">
            <p>We use cookies</p>
            <button>OK</button>
          </div>
        HTML
        element = parse_html(html).css(".cookiebot-banner").first
        expect(described_class.consent_node?(element)).to be true
      end

      it "detects privacy policy consent" do
        html = <<~HTML
          <div class="privacy-notice">
            <p>Read our privacy policy</p>
            <button>Accept</button>
          </div>
        HTML
        element = parse_html(html).css(".privacy-notice").first
        expect(described_class.consent_node?(element)).to be true
      end

      it "detects RODO banner (Polish GDPR)" do
        html = <<~HTML
          <div class="rodo-info">
            <p>Informacja RODO</p>
            <button>Rozumiem</button>
          </div>
        HTML
        element = parse_html(html).css(".rodo-info").first
        expect(described_class.consent_node?(element)).to be true
      end
    end

    context "with edge cases" do
      it "returns false for nil node" do
        expect(described_class.consent_node?(nil)).to be false
      end

      it "checks ancestors for consent patterns" do
        html = <<~HTML
          <div class="cookie-consent">
            <div class="inner">
              <p>We use cookies</p>
              <button>Accept all</button>
            </div>
          </div>
        HTML
        inner = parse_html(html).css(".inner").first
        expect(described_class.consent_node?(inner)).to be true
      end

      it "requires both text match AND action button for text-based detection" do
        html = <<~HTML
          <div class="info">
            <p>Informacje o ciasteczkach</p>
          </div>
        HTML
        element = parse_html(html).css(".info").first
        expect(described_class.consent_node?(element)).to be false
      end

      it "detects consent by attribute alone (cookiebot, onetrust, etc.)" do
        html = <<~HTML
          <div id="onetrust-banner">
            <p>Some content</p>
          </div>
        HTML
        element = parse_html(html).css("#onetrust-banner").first
        expect(described_class.consent_node?(element)).to be true
      end
    end
  end
end
