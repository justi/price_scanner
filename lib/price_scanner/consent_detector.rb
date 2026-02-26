# frozen_string_literal: true

module PriceScanner
  # Detects GDPR/cookie consent banners in HTML nodes (requires nokogiri).
  module ConsentDetector
    CONSENT_TEXT_REGEX = /
      \bcookie\b|\bcookies\b|\bconsent\b|\bgdpr\b|\bprivacy\b|\btracking\b|\bpreferences\b|\bpersonaliz|marketing\s+cookies|
      do\s+not\s+sell|opt\s+out|opt\s+in|cookie\s+policy|privacy\s+policy|
      \bciasteczk(?:a|i|ami|ach|om)?\b|\bprywatn|\bzgod(?:a|y|ę|zie)?\b|\brodo\b
    /ix
    CONSENT_ACTION_REGEX = /
      \baccept\b|\bagree\b|\ballow\b|\bmanage\b|\bpreferences\b|\bdecline\b|\breject\b|\bok\b|\bokay\b|\bcontinue\b|save\s+preferences|
      accept\s+all|allow\s+all|got\s+it|\brozumiem\b|\bzgadzam\b|\bakceptuj|\bzaakceptuj|\bodrzuc|\bodmow
    /ix
    CONSENT_ATTR_REGEX = /
      cookie|consent|gdpr|privacy|cmp|onetrust|trustarc|cookielaw|cookiebot|osano|
      quantcast|usercentrics|didomi|cookieyes|termly|iubenda|shopify-pc__banner
    /ix

    module_function

    def consent_node?(node)
      return false unless node

      nodes = [node] + node.ancestors.take(3)
      hits = detect_hits(nodes)
      return false unless hits[:text] || hits[:attr]

      (hits[:text] && hits[:action]) || hits[:attr]
    end

    def detect_hits(nodes)
      {
        text: nodes.any? { |item| item.text.to_s.match?(CONSENT_TEXT_REGEX) },
        attr: nodes.any? { |item| attribute_text(item).match?(CONSENT_ATTR_REGEX) },
        action: nodes.any? { |item| action_button?(item) }
      }
    end

    def attribute_text(node)
      [
        node["id"],
        node["class"],
        node["role"],
        node["aria-label"],
        node["aria-modal"]
      ].compact.join(" ")
    end

    def action_button?(node)
      node.css("button, [role='button'], input[type='button'], input[type='submit'], a").any? do |button|
        text = [
          button.text,
          button["aria-label"],
          button["title"],
          button["value"]
        ].compact.join(" ")
        text.match?(CONSENT_ACTION_REGEX)
      end
    end

    private_class_method :detect_hits, :attribute_text, :action_button?
  end
end
