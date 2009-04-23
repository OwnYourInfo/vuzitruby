require 'rubygems'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'vuzitruby'
  s.version = "1.1.0"
  s.homepage = 'http://vuzit.com/'
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brent Matzelle"]
  s.date = %q{2009-3-30}
  s.default_executable = %q{vuzitcl}
  s.executables = ["vuzitcl"]
  s.description = %q{This is a library for the Vuzit Web Services API.  For 
                     more information on the platform, visit 
                     http://vuzit.com/developer}
  s.email = %q{support@vuzit.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["README", "Rakefile", "lib/vuzitruby.rb", 
             "lib/vuzitruby/document.rb", "lib/vuzitruby/exception.rb", 
             "lib/vuzitruby/service.rb"]
  s.has_rdoc = true
  #s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{vuzitruby}
  s.rubygems_version = %q{1.1.0}
  s.summary = %q{Ruby client library for the Vuzit Web Services API}
  s.extra_rdoc_files = ["README"]
end

namespace :github do
  desc "Prepare for GitHub gem packaging"
  task :prepare do
    `rake debug_gem > vuzitruby.gemspec`
  end
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

