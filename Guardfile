# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rake', :task => 'redmine:plugins:redmine_time_tracker:convert:coffeescript' do
  watch(%r{.js.coffee$})
end

guard 'rake', :task => 'redmine:plugins:redmine_time_tracker:convert:sass' do
  watch(%r{.css.scss$})
end