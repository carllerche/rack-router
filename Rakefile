require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "spec/rake/spectask"

spec = Gem::Specification.new do |s|
  s.name         = "rack-router"
  s.version      = "0.0.1"
  s.platform     = Gem::Platform::RUBY
  s.author       = "Carl Lerche"
  s.email        = "carl@splendificent.com"
  s.homepage     = "http://github.com/carllerche/rack-router"
  s.summary      = "Rack middleware that handles routing a request to a rack application"
  s.description  = "Rack middleware that handles routing a request to a rack application"
  s.require_path = "lib"
  s.files        = %w( LICENSE README Rakefile ) + Dir["{lib}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README )

  s.required_rubygems_version = ">= 1.3.0"
  
  # Dependencies
  s.add_dependency "rack", ">= 0.9.1"
  s.required_ruby_version = ">= 1.8.6"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc "Run all benchmarks"
task :benchmark do
  Dir["benchmarks/*.rb"].each do |file|
    pid = fork do
      load file
      exit
    end
    Process.wait2(pid)
  end
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ["-c", "-fs"]
end

task :default do
  exec "rake spec && rake spec optimizations=true"
end