require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "mega_mutex"
    gem.version = "1.1.0"
    gem.summary = %Q{Distributed mutex for Ruby}
    gem.description = %Q{Distributed mutex for Ruby}
    gem.email = "developers@songkick.com"
    gem.homepage = "http://github.com/songkick/mega_mutex"
    gem.authors = ["Matt Johnson", "Matt Wynne"]
    gem.add_dependency 'memcache-client', '>= 1.7.4'
    gem.add_dependency 'logging', '>= 1.1.4'
    gem.add_dependency 'reretryable', '>= 0.1.0'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

namespace :github do
  task :push do
    remotes = `git remote`.split("\n")
    unless remotes.include?('github')
      sh('git remote add github git@github.com:songkick/mega_mutex.git')
    end
    sh('git push github master')
  end
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => [:spec, 'github:push', 'gemcutter:release']

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mega_mutex #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
