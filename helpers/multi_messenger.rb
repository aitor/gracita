=begin Adhearsion metadata

=end

require 'xmpp4r-simple'

class MultiMessenger
  
  Format = /\A[\w\._%-]+@[\w\.-]+\.[a-zA-Z]{2,4}\z/
  def initialize username, password, accept_subs=false
    @username, @password = username, password
    @connection = Jabber::Simple.new username, password
    @connection.accept_subscriptions = accept_subs
  end
  
  def connected?() @connection.connected? end
  def your_username?(un) @username.downcase == un.downcase end
  def your_service?(s) %w'xmpp jabber gtalk'.include? s.to_s.downcase end
  def may_be_yours?(sn) true end
  def im username, message
    #debug "Connection #{@connection.inspect}, UN: #{username}, MSG: #{message}"
    @connection.deliver(username, message)
  end
  attr_reader :connection
end

config = $HELPERS['multi_messenger']

username = config['username']||''
password = config['password']||''
accept_subs = config['accept_subscriptions']

log "MultiMessenger: Connecting to #{username}"
jabber = MultiMessenger.new username, password, accept_subs

jabber.connection.received_messages do |msg|
  # Need to do something with each message? Do it here.
end

jabber.connection.presence_updates do |friend, old_presence, new_presence|
  # Handle presence updates here, optionally
end

jabber.connection.subscription_requests do |friend, presence|
  # When a subscription request comes in, handle it here.
end

jabber.connection.new_subscriptions do |friend, presence|
  # Handle each subscription notification
end

InstantMessenger.use_service jabber
$HUTDOWN.hook { jabber.connection.disconnect }