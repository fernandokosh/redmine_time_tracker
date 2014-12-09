source 'https://rubygems.org'

# simulating assets pipeline
gem 'coffee-script'
gem 'sass'

group :test do
  gem 'zonebie'
  gem "minitest"
  gem 'timecop'
  gem 'turn'
  gem 'poltergeist'
end

group :development, :test do
  if RUBY_PLATFORM =~ /(win32|w32)/
    gem 'listen', '~> 2.7.5'
    gem 'wdm'
  end
  gem 'guard-rake'
  gem 'rb-readline'
end
