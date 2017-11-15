Gem::Specification.new do |s|
  s.name          = 'logstash-input-ping'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Provides ping data as input for Logstash'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program'
  s.homepage      = 'https://github.com/davidecavestro/logstash-input-ping'
  s.authors       = ['Davide Cavestro']
  s.email         = 'davide.cavestro@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency 'logstash-codec-json'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'tzinfo'
  s.add_runtime_dependency 'tzinfo-data'
  s.add_runtime_dependency 'rufus-scheduler'
  s.add_runtime_dependency 'net-ping'

  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
  s.add_development_dependency 'timecop'
end
