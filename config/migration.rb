#!/usr/bin/env ruby
require 'yaml'
require 'rubygems'
require 'active_record'

# A migration script uses a database configuration and creates tables
# very conveniently in a database-agnostic way. Below, add any customizations
# to the sample schema or leave it as-is. When done, type "rake migrate" to
# have this schema generated.

ActiveRecord::Base.establish_connection YAML.load_file('config/database.yml')

class CreateUsers < ActiveRecord::Migration
  # Available column types are :primary_key, :string, :text, :integer,
  # :float, :datetime, :timestamp, :time, :date, :binary, and :boolean
  def self.up
    create_table :users do |t|
      t.column :name, :string
      t.column :group_id, :integer # Foreign key
      t.column :extension, :string
      # t.column :billed_time, :integer, :null => false
      
      # Feel free to remove or change this to "email". Gmail offers email,
      # instant messaging, calendars, and so forth -- all of which you
      # can integrate with using one simple username.
      t.column :gmail, :string
    end
  end

  def self.down
    drop_table :users
  end
end

class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.column :name, :string
      t.column :administrator_email, :string
      t.column :callerid_name, :string
      t.column :callerid_num, :string
      #t.column :usage_limit, :integer
    end
  end

  def self.down
    drop_table :groups
  end
end


CreateUsers.up
CreateGroups.up

### If you'd like to create any initial users, do it here by
### requiring your database.rb file and performing your logic.
#
# require 'config/database.rb'
# User.create :name => "Jay Phillips", :extension => 123