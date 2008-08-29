require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'

Summary = 'Adhearsion is a professional integration system for integrating anything and everything.'

desc "Generate RDoc documentation for Adhearsion"
Rake::RDocTask.new do |rdoc|
  rdoc.title = "Generated Adhearsion Application-specific Documentation"
  rdoc.rdoc_dir = File.join('doc', 'rdoc')
end

desc "Pulls down the entire wiki in HTML format"
task :wiki => [:rm_wiki] do
  require 'open-uri'
  File.open "wiki.zip",'a' do |f|
    f.write open('http://adhearsion.stikipad.com/codex/export_html').read
  end
  Dir.mkdir 'docs' unless File.exists? 'docs'
  `unzip -d docs/wiki wiki.zip`
  File.delete 'wiki.zip'
  puts `find docs/wiki`
end

desc "Removes the local copy of the wiki"
task :rm_wiki do
  `rm -rf wiki.zip docs/wiki/`
end

desc "Removes all cached compiled RubyInline shared objects"
task :purge_objects do
  `rm -rf ~/.ruby_inline/*`
end

desc "Prepares Adhearsion for a new release"
task :prepare_release do
  # Remove log files
  Dir['log/*.log'].each do |f|
    puts "Removing file #{f}"
    File.delete f
  end

  # Check for unversioned files
  unversioned_files = `svn st | grep '^\?' | awk '{ print $2 }'`
  puts "WARNING: These files are not under version control:\n#{unversioned_files}" unless unversioned_files.empty? 
end

desc 'Initialize the environment for an ActiveRecord::Migration'
task :init_migrations do
  require 'active_record'
  # This won't work until the Adhearsion codebase is refactored.
  require 'lib/sexy_migrations'
  
  ActiveRecord::ConnectionAdapters::TableDefinition.send :include, SexyMigrations::Table
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, SexyMigrations::Schema
  
  require 'config/migration'
end

desc 'Create sample databases per the config/migration.rb and database.yml files.'
task :migrate => [:init_migrations] do
  ObjectSpace.each_object(Class) do |c|
    c.up if c.superclass == ActiveRecord::Migration
  end
end
