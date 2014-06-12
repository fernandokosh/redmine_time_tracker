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
  gem 'guard-rake'
end