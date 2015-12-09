source 'https://rubygems.org'

# simulating assets pipeline
gem 'coffee-script'
gem 'sass'

group :test do
  gem 'zonebie'
  gem 'minitest'
  if (Gem::Version.new(ENV['REDMINE_VERSION']) < Gem::Version.new('2.6.4')) && !ENV['REDMINE_VERSION'].nil?
    gem 'turn'
  else
    gem 'minitest-reporters'
    gem 'shoulda-context'
  end
  gem 'timecop'
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
