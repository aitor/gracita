# This is an example dialplan. Feel free to remove this file and
# start your dialplan from scratch.


# This "internal" context would map over if Adhearsion were invoked
# in Asterisk's own "internal" context. For example, if you set up
# your extensions.conf file for Adhearsion as so:
#
# [internal]
#     exten => _.,1,AGI(agi://192.168.1.3)
#
# then, when Adhearsion receives that call, it sees it came from
# the "internal" context and invokes this.
internal {
  # In this example context you'll see use of a User object. This
  # is intended to be an ActiveRecord object created from your
  # config/database.rb file.
  case extension
    when 101...200
      employee = Employee.find_by_extension extension
      unless employee.busy? then dial employee
      else
        voicemail extension
      end

    when 888 then play weather_report("Dallas, Texas")
    when 999 then check_voicemail extension
    
    # This is simply an example of including another context in
    # the block of another context. Simply place a plus sign before
    # its name. No need to even declare it above the context you
    # enter it into.
    when 999 then +joker_voicemail
  end
}
joker_voicemail {
  play %w(a-connect-charge-of 22 cents-per-minute will-apply)
  sleep 2.seconds
  play 'just-kidding-not-upset'
  check_voicemail extension
}