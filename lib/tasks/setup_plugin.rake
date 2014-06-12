require 'fileutils'

desc "Install redmine time tracker plugin"
namespace :redmine do
  namespace :plugins do
    namespace :redmine_time_tracker do
      @plugin = 'redmine_time_tracker'

      task :install do
        Rake::Task["redmine:plugins:redmine_time_tracker:convert:coffeescript"].invoke
        Rake::Task["redmine:plugins:redmine_time_tracker:convert:sass"].invoke
      end

      desc "Copy Guard file to redmine root"
      task :setup do
        guardfile = File.read(Rails.root.join("plugins/#{@plugin}/Guardfile"))
        if File.exists? 'Guardfile'
          puts "An Guardfile alread exists in your Rails root. Please add the following blocks to your Guardfile in order to watch coffeescript and sass files:"
          puts 
          puts '-'*60
          puts guardfile
          puts '-'*60
          puts
        else
          File.open(Rails.root.join('Guardfile'), 'w') { |file| file.write(guardfile)}
          puts "An Guardfile has been written to #{Rails.root}."
        end

        puts "You can run $ guard to watch coffee and scss/sass files. They will automatically copied to the redmines public assets folder when something has changed."
        puts "\n$ guard\n"
      end

      namespace :convert do

        task :coffeescript do
          puts "Compiling coffeescript files:"
          puts '---'

          source_dir = Rails.root.join("plugins/#{@plugin}/app/assets/javascripts")
          dest_dir = Rails.root.join("public/plugin_assets/#{@plugin}/javascripts")

          directories = Dir.glob(source_dir.join('**/*')).select {|fn| File.directory? fn }
          directories << source_dir
          directories.each do |cs_dir|
            Dir.glob("#{cs_dir}/*.coffee").each do |cs_file|
              cs_filename = File.basename cs_file
              js_filename = cs_filename.sub('.coffee', '')

              rel_js_dir = cs_dir.sub(source_dir.to_path, '')        
              js_dir = [dest_dir, rel_js_dir].join('')

              js_content = CoffeeScript.compile File.read(cs_file)
              FileUtils.mkdir_p(js_dir)
              js_file = [js_dir, js_filename].join('/')
              File.open(js_file, 'w') { |file| file.write(js_content) }

              puts "FROM: #{cs_file}"
              puts "TO: #{js_file}"
              puts '---'
            end
            
          end
          
        end

        task :sass do
          puts "Compiling coffeescript files:"
          puts '---'
          
          source_dir = Rails.root.join("plugins/#{@plugin}/app/assets/stylesheets")
          dest_dir = Rails.root.join("public/plugin_assets/#{@plugin}/stylesheets")

          directories = Dir.glob(source_dir.join('**/*')).select {|fn| File.directory? fn }
          directories << source_dir
          directories.each do |sass_dir|
            Dir.glob("#{sass_dir}/*.scss").each do |sass_file|
              sass_filename = File.basename sass_file
              css_filename = sass_filename.sub('.scss', '')

              rel_css_dir = sass_dir.sub(source_dir.to_path, '')        
              css_dir = [dest_dir, rel_css_dir].join('')

              

              css_content = Sass.compile File.read(sass_file)
              FileUtils.mkdir_p(css_dir)
              css_file = [css_dir, css_filename].join('/')
              File.open(css_file, 'w') { |file| file.write(css_content) }

              puts "FROM: #{sass_file}"
              puts "TO: #{css_file}"
              puts '---'
            end
          end
        end
      end
    end
  end
end