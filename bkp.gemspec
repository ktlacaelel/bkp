Gem::Specification.new do |spec|
  spec.name = %q{bkp}
  spec.version = "1.0.1"
  spec.date = %q{2023-07-29}
  spec.summary = %q{bkp - Shell Backup Management Tool (for AWS S3 Buckets)}
  spec.author = 'Kazuyoshi Tlacaelel'
  spec.homepage = 'https://github.com/ktlacaelel/bkp'
  spec.email = 'kazu.dev@gmail.com'
  spec.license = 'MIT'
  spec.add_runtime_dependency 'abstract_command', '0.0.6'
  spec.add_runtime_dependency 'ona', '1.0.3'
  spec.require_paths = ["lib"]
  spec.bindir = 'bin'
  spec.files = [
    "Gemfile",
    "Onafile",
    "lib/bkp.rb",
    "lib/validations.rb",
    "lib/helpers.rb"
  ]
  spec.executables << 'bkp'
end
