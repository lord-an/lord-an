require_relative "lib/commerce/version"

Gem::Specification.new do |spec|
  spec.name        = "commerce"
  spec.version     = Commerce::VERSION
  spec.authors     = [ "Lord An" ]
  spec.email       = [ "maintainers@example.org" ]
  spec.homepage    = "https://example.org/lord-an"
  spec.summary     = "Mountable cart and order engine."
  spec.description = "Provides customer carts and unpaid order records."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.4.1"
  spec.add_dependency "store", ">= 0.1.0"
  spec.add_dependency "authenticate", ">= 0.1.0"
  spec.add_dependency "internationalization", ">= 0.1.0"
end
