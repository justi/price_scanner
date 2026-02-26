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

    ANCESTOR_DEPTH = 3

    module_function

    def consent_node?(node)
      return false unless node

      nodes = [node] + node.ancestors.take(ANCESTOR_DEPTH)
      hits = detect_hits(nodes)
      text_hit = hits[:text]
      attr_hit = hits[:attr]
      return false unless text_hit || attr_hit

      (text_hit && hits[:action]) || attr_hit
    end

    def detect_hits(nodes)
      result = { text: false, attr: false, action: false }
      nodes.each do |item|
        result[:text] ||= item.text.to_s.match?(CONSENT_TEXT_REGEX)
        result[:attr] ||= attribute_text(item).match?(CONSENT_ATTR_REGEX)
        result[:action] ||= action_button?(item)
      end
      result
    end

    ATTR_KEYS = %w[id class role aria-label aria-modal].freeze
    ACTION_SELECTOR = "button, [role='button'], input[type='button'], input[type='submit'], a"

    def attribute_text(node)
      ATTR_KEYS.filter_map { |key| node[key] }.join(" ")
    end

    def action_button?(node)
      node.css(ACTION_SELECTOR).any? do |button|
        collect_text(button).match?(CONSENT_ACTION_REGEX)
      end
    end

    def collect_text(node)
      [node.text, node["aria-label"], node["title"], node["value"]].compact.join(" ")
    end

    private_class_method :detect_hits, :attribute_text, :action_button?, :collect_text
  end
end
