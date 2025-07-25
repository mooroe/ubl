# frozen_string_literal: true

require_relative "lib/ubl/version"

Gem::Specification.new do |spec|
  spec.name = "ubl"
  spec.version = Ubl::VERSION
  spec.authors = ["mooroe"]
  spec.email = ["roeland@webding.org"]

  spec.summary = "Generate and validate UBL documents for Peppol"
  spec.description = "Generate and validate UBL (Universal Business Language) documents, such as invoices and credit notes, compliant with the Peppol network."
  spec.homepage = "https://github.com/mooroe/ubl"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mooroe/ubl"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.18"
  spec.add_dependency "base64", "~> 0.3.0"
  spec.add_dependency "colorize", "~> 1.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
