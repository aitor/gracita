# Place any database customizations here. There are several ways you may desire enabling
# database connectivity:
#
#   * Daemons (MySQL/PostgreSQL/etc)
#     |
#     |  If you're running sophisticated applications for your VoIP server 
#     |  and desire performance or integration, you'll want a daemon database
#     |  management system. MySQL is recommended.
#     '____________________________________________________________
#   * File-based (Sqlite/Sqlite3)
#     | 
#     | If you have little desire to integrate your VoIP application's
#     | user and group data with other apps, sqlite/3 is a very
#     | easy solution to get running.
#     '____________________________________________________________
#   * No database
#     | 
#     | If you simply have no use for keeping any information about
#     | users, groups, or anything else, change the "enable_database"
#     | field to "false" in database.yml.
#     '____________________________________________________________
#
### SETTING UP YOUR DATABASE WITH A SAMPLE SCHEMA
#
# To make your Adhearsion app database-driven, you'll need to take a moment
# to configure your database.
#
# ActiveRecord resources:
#  * http://slash7.com/cheats/activerecord_cheatsheet.pdf
#

require 'active_record'
ActiveRecord::Base.logger = Logger.new 'logs/database.log', 10, 1.megabyte
ActiveRecord::Base.establish_connection YAML.load_file('config/database.yml')

# When Adhearsion first encounters this Group class, it will automatically associate it
# to the "groups" database. 
class Group < ActiveRecord::Base
  has_many :users
end

class User < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_presence_of :name
  belongs_to :group
  def busy?
    # Include your own logic here!
    false
  end
end
