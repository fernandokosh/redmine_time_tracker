source 'https://rubygems.org'
group :test do
  gem 'zonebie'
  gem 'win32console', '1.3.0', :platform => :mingw_19
  gem "minitest"
  gem 'timecop'
  gem 'turn'
  gem 'poltergeist'
end

gem 'debugger', {group: [:test, :development]}.merge(ENV['RM_INFO'] ? {require: false} : {})