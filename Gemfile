source 'https://rubygems.org'
group :test do
  gem 'zonebie'
  gem "minitest"
  gem 'timecop'
  gem 'turn'
  gem 'poltergeist'
end

gem 'debugger', {group: [:test, :development]}.merge(ENV['RM_INFO'] ? {require: false} : {})

group :development, :test do 
  gem 'coffee-script'
  gem 'sass'
  gem 'listen', '~> 2.7.5' if RUBY_PLATFORM =~ /(win32|w32)/
  gem 'guard-rake'
end