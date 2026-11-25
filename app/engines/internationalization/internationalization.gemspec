require_relative "lib/internationalization/version"

Gem::Specification.new do |spec|
  spec.name        = "internationalization"
  spec.version     = Internationalization::VERSION
  spec.authors     = [ "Lord An" ]
  spec.email       = [ "maintainers@example.org" ]
  spec.homepage    = "https://example.org/lord-an"
  spec.summary     = "Shared locale configuration and language preference engine."
  spec.description = "Provides shared Rails I18n settings and locale preferences."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.4.1"
end
