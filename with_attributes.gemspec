require_relative "lib/with_attributes/version"

Gem::Specification.new do |spec|
  # information
  spec.name = "with_attributes"
  spec.version = WithAttributes::VERSION
  spec.summary = "temporarily enabling or disabling boolean attributes on classes and instances"
  spec.author = "Javier Aranda"
  spec.email = "javier@aranda.dev"
  spec.homepage = "https://github.com/javierav/with_attributes"
  spec.license = "MIT"

  # metadata
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  # gem files
  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]

  # ruby minimal version
  spec.required_ruby_version = "~> 3.0"
end
