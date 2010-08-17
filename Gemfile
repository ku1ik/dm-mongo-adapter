source 'http://gemcutter.org'

group :runtime do
  # MongoDB driver
  gem 'mongo',     '~> 1.0'
  gem 'bson_ext',  '~> 1.0'

  # ActiveSupport is preffered over Extlib
  gem 'activesupport', '~> 3.0.0.beta2', :require => false

  # DataMapper libs
  gem 'dm-core',       :git => 'git://github.com/datamapper/dm-core.git'
  gem 'dm-aggregates', :git => 'git://github.com/datamapper/dm-aggregates.git'
  gem 'dm-migrations', :git => 'git://github.com/datamapper/dm-migrations.git'
end

group :development do
  gem 'rake'
  gem 'rcov'
  gem 'rspec'
  gem 'jeweler'
  gem 'yard',      '~> 0.5'
end

group :quality do
  gem 'yardstick', '~> 0.1'
end
