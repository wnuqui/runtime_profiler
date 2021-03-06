lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'runtime_profiler/version'

Gem::Specification.new do |spec|
  spec.name          = 'runtime_profiler'
  spec.version       = RuntimeProfiler::VERSION
  spec.authors       = ['Wilfrido T. Nuqui Jr.']
  spec.email         = ['nuqui.dev@gmail.com']

  spec.summary       = 'Runtime Profiler for Rails Applications'
  spec.description   = 'Runtime Profiler for Rails Applications'
  spec.homepage      = 'http://www.github.com/wnuqui/runtime_profiler'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['runtime_profiler']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activesupport', '>= 3.0.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-line'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rubocop'
  spec.add_runtime_dependency 'commander'
  spec.add_runtime_dependency 'defined_methods'
  spec.add_runtime_dependency 'hirb'
  spec.add_runtime_dependency 'method_meter', '>= 0.4.3'
  spec.add_runtime_dependency 'terminal-table'
end
