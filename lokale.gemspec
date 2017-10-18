# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lokale/version"
require "lokale/colorize"

Gem::Specification.new do |spec|
  spec.name          = "lokale"
  spec.version       = Lokale::VERSION
  spec.authors       = ["Anton Onizhuk"]
  spec.email         = ["anton.onizhuk@gmail.com"]

  spec.summary       = %q{Lokale is a small tool that inspects localization of Xcode projects.}
  spec.description   = %q{Write a longer description or delete this line.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["lokale"]
  spec.require_paths = ["lib"]

end
