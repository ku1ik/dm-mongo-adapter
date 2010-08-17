require 'rubygems'
require 'rake'
require 'rake/clean'

CLOBBER.include ['pkg', '*.gem', 'doc', 'coverage', 'measurements']

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = 'dm-mongo-adapter'
    gem.summary     = 'MongoDB DataMapper Adapter'
    gem.email       = "piotr.solnica@gmail.com"
    gem.homepage    = "http://github.com/solnic/dm-mongo-adapter"
    gem.authors     = ['Piotr Solnica']

    gem.has_rdoc    = false

    # Runtime deps
    gem.add_dependency 'activesupport', '~> 3.0.0.beta3'
    gem.add_dependency 'dm-core',       '~> 1.0.0'
    gem.add_dependency 'dm-aggregates', '~> 1.0.0'
    gem.add_dependency 'dm-migrations', '~> 1.0.0'
    gem.add_dependency 'mongo',         '~> 1.0.7'
    gem.add_dependency 'bson',          '~> 1.0.0'
    gem.add_dependency 'bson_ext',      '~> 1.0.0'
    # Development deps
    gem.add_development_dependency 'rspec',     '>= 1.3.0'
    gem.add_development_dependency 'yard',      '>= 0.5'
    gem.add_development_dependency 'yardstick', '>= 0.1'

    # Exclude files
    gem.files.exclude "bin/console"
  end
  Jeweler::GemcutterTasks.new
  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: sudo gem ' \
       'install jeweler'
end

task :install_fast do
  sh "rake build; gem install pkg/dm-mongo-adapter*.gem --local"
end
