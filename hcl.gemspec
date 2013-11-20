$:.unshift(File.dirname(__FILE__) + '/lib')
require 'hcl'

Gem::Specification.new do |s|
  s.name = "hcl"
  s.version = HCl::VERSION

  s.authors = ["Zack Hobson"]
  s.date = "2013-11-19"
  s.description = "HCl is a command-line client for manipulating Harvest time sheets."
  s.email = "zack@zackhobson.com"
  s.executables = ["hcl"]
  s.files = %w[CHANGELOG LICENSE Rakefile] + Dir['*.markdown'] +
    Dir['bin/*'] + Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.homepage = "http://github.com/zenhob/hcl"
  s.licenses = ["MIT"]
  s.summary = "Harvest timesheets from the command-line"

  s.add_runtime_dependency 'trollop'
  s.add_runtime_dependency 'chronic'
  s.add_runtime_dependency 'highline'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'mocha'
end

