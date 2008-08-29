=begin Adhearsion metadata
name: Adhearsion Growler
  author:
    name: Phil Kates
    email: hawk684 -at- gmail.com
    modified-by: Jay Phillips
  gems:
    - ruby-growl
=end

require 'ruby-growl'

GROWL_SERVER = unless $HELPERS['growler']['ip'] then nil else
  Growl.new $HELPERS['growler']['ip'] || 'localhost',
            $HELPERS['growler']['app_name'] || "Adhearsion",
            $HELPERS['growler']['notifications'],
            nil, $HELPERS['growler']['password']
end

# Sends a message to an OSX desktop's Growl notification server. If you
# intend to only notify a single machine, you can specify the parameters
# in growler.yml.
#
# == Usage:
#
# - message: The notification or message you wish to send!
# - type (optional): The type of notification as specified in the growler.yml
#   config file. This defaults to the first "notifications" entry. If you want
#   growl() to automatically set this for you, simply send it nil.
# - ip (optional): The desktop's IP address you wish to notify. This
#   by default uses what's in growler.yml or, if unavailable, "localhost".
# - password (optional): a password if one is needed. Defaults to nothing.
#
# == Examples:
#  - growl "Isn't it about time you debugged me?"
#  - growl "Call from #{callerid}!", "Incoming Call"
#  - growl "The caller queue size is #{queue.size}", nil, "192.168.1.133"
#  - growl "Join conference 1234!", nil, "192.168.50.151", "Secretz!"
def growl message, type=nil, ip=nil, password=nil
  type = $HELPERS['growler']['notifications'].first unless type
  
  # Create a new Growl client if an IP was specified, otherwise use
  # our server created when Adhearsion booted.
  svr = unless ip then GROWL_SERVER else
    Growl.new ip, $HELPERS['growler']['app_name'] || "Adhearsion",
              $HELPERS['growler']['notifications'], nil,
              $HELPERS['growler']['password']
  end
  
  # TODO support priorities and stickies. May need to use hash-key argments?
  # TODO handle unreachable desktops
  svr.notify type, type, message
end
