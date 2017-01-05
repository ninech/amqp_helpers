Gem::Specification.new do |s|
  s.name        = 'amqp_helpers'
  s.version     = File.read(File.expand_path('../VERSION', __FILE__)).strip
  s.authors     = ['Nils Caspar', 'Raffael Schmid', 'Samuel Sieg']
  s.email       = 'development@nine.ch'
  s.homepage    = 'https://github.com/ninech/amqp_helpers'
  s.license     = 'MIT'
  s.summary     = 'Simple helpers to achieve various AMQP tasks.'
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec', '~> 3.x'
  s.add_development_dependency 'rake', '~> 10.3'

  s.add_runtime_dependency 'amqp', '~> 1.3'
  s.add_runtime_dependency 'bunny', '~> 2.0.0'
  s.add_runtime_dependency 'syslogger', '~> 1.5'
end
