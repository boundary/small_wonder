require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

spec = Gem::Specification.new do |s|
  s.name = "small_wonder"
  s.version = "0.1.1"
  s.author = "Joe Williams"
  s.email = "j@boundary.com"
  s.homepage = "https://github.com/boundary/small_wonder"
  s.platform = Gem::Platform::RUBY
  s.summary = "A Deployment Tool"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md"]
  %w{mixlib-config mixlib-cli mixlib-log excon yajl-ruby chef highline net-ssh net-scp salticid colorize}.each { |gem| s.add_dependency gem }
  s.bindir = "bin"
  s.executables = %w( small_wonder )
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
end
