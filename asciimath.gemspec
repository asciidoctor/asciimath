# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'asciimath/version'

Gem::Specification.new do |spec|
  spec.name          = "asciimath"
  spec.version       = AsciiMath::VERSION
  spec.authors       = ["Pepijn Van Eeckhoudt", "Gark Garcia"]
  spec.email         = ["pepijn@vaneeckhoudt.net", "pablo-ecobar@riseup.net"]
  spec.summary       = %q{AsciiMath parser and converter}
  spec.description   = %q{A pure Ruby AsciiMath parsing and conversion library.}
  spec.homepage      = "https://asciidoctor.org/"
  spec.license       = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/asciidoctor/asciimath/issues",
    "changelog_uri" => "https://github.com/asciidoctor/asciimath/blob/HEAD/CHANGELOG.adoc",
    "mailing_list_uri" => "https://chat.asciidoctor.org",
    "source_code_uri" => "https://github.com/asciidoctor/asciimath"
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
