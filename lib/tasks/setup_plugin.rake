require 'rake'
require 'fileutils'

desc "Install redmine time tracker plugin"
namespace :redmine do
  namespace :plugins do
    namespace :redmine_time_tracker do
      @plugin = 'redmine_time_tracker'
      @source_dir = Rails.root.join("plugins/#{@plugin}/app/assets")
      @dest_dir = Rails.root.join("public/plugin_assets/#{@plugin}")

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
        puts "\n$ bundle exec guard\n"
      end

      namespace :convert do

        task :coffeescript, [:paths] do |t, args|
          puts "Compiling coffeescript files:"
          puts '---'
          source_dir = @source_dir.join('javascripts')
          dest_dir = @dest_dir.join('javascripts')
          if args.paths.nil?
            directories = Dir.glob(source_dir.join('**/*')).select {|fn| File.directory? fn }
            directories << source_dir
            directories.each do |cs_dir|
              Dir.glob("#{cs_dir}/*.coffee").each do |cs_file|
                convert_file(cs_file, source_dir, dest_dir, 'coffee')
              end
            end
          else
            args.paths.each do |changed_file|
              convert_file(Rails.root.join(changed_file), source_dir, dest_dir, 'coffee')
            end
          end
          
        end

        task :sass, [:paths] do |t, args|
          puts "Compiling sass files:"
          puts '---'
          source_dir = @source_dir.join('stylesheets')
          dest_dir = @dest_dir.join('stylesheets')
          if args.paths.nil?
            
            directories = Dir.glob(@source_dir.join('**/*')).select {|fn| File.directory? fn }
            directories << @source_dir
            directories.each do |sass_dir|
              Dir.glob("#{sass_dir}/*.scss").each do |sass_file|
                convert_file(sass_file, source_dir, dest_dir, 'scss')
              end
            end
          else
            args.paths.each do |changed_file|
              convert_file(Rails.root.join(changed_file), source_dir, dest_dir, 'scss')
            end
          end
        end
      end
    end
  end

  def convert_file(source_file, source_dir, dest_dir, ext)
    source_filename = File.basename source_file
    dest_filename = source_filename.sub(".#{ext}", '')

    rel_dest_dir = File.dirname(source_file).sub("#{source_dir}", '')     
    assets_dest_dir = [dest_dir, rel_dest_dir].join('')

    if ext.eql? 'coffee'
      file_content = CoffeeScript.compile File.read(source_file)
    else
      file_content = Sass.compile File.read(source_file)
    end

    FileUtils.mkdir_p(assets_dest_dir)
    dest_file = [assets_dest_dir, dest_filename].join('/')
    File.open(dest_file, 'w') { |file| file.write(file_content) }

    puts "[#{ext.upcase}]> FROM: #{source_file}"
    puts "[#{ext.upcase}]> TO: #{dest_file}"
  end
end