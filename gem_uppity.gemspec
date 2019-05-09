# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gem_uppity/version'

Gem::Specification.new do |spec|
  spec.name          = 'gem_uppity'
  spec.version       = GemUppity::VERSION
  spec.authors       = ['Tim Gourley']
  spec.email         = ['tgourley@gmail.com']

  spec.summary       = 'Upgrade all gems in your Gemfile to the latest version on Rubyforge'
  spec.description   = 'Provides a starting point to modernizing an older Bundler-based ruby application'
  spec.homepage      = 'https://github.com/bratta/gem_uppity'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Required Dependencies
  spec.add_dependency 'bundler', '~> 2.0'

  # Development Dependencies
  spec.add_development_dependency 'byebug', '~> 11.0.1'
  spec.add_development_dependency 'irb', '~> 1.0.0'
  spec.add_development_dependency 'rake', '~> 12.3.2'
  spec.add_development_dependency 'rspec', '~> 3.8.0'
  spec.add_development_dependency 'rubocop', '~> 0.68.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.32.0'
end
