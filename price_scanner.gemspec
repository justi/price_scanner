# frozen_string_literal: true

require_relative "lib/price_scanner/version"

Gem::Specification.new do |spec|
  spec.name = "price_scanner"
  spec.version = PriceScanner::VERSION
  spec.authors = ["Justyna"]
  spec.email = ["justine84@gmail.com"]

  spec.summary = "Multi-currency price extraction from text"
  spec.description = "Battle-tested price parser supporting PLN, EUR, GBP, USD. " \
                     "Extracts prices from text, handles Polish and English number formats, " \
                     "filters savings badges and price ranges."
  spec.homepage = "https://github.com/justi/price_scanner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.require_paths = ["lib"]
end
