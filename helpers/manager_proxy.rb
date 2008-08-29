require 'rami'
class PBX
  include Rami
  
  @@sip_users = {}
  
  @@rami_server_thread = Thread.current
  
  @@rami_server = Rami::Server.new $HELPERS.manager_proxy
  @@rami_server.console = 1
  @@rami_server.run
  
  @@rami_client = Client.new @@rami_server
  @@rami_client.timeout = 10
  
  def self.rami_client() @@rami_client end
  
  $HUTDOWN.hook do
    @@rami_client.stop
  end
  
  def self.sip_users
    if !@@sip_users[:expiration] || @@sip_users[:expiration] <= Time.now
      sip_db = PBX.rami_client.command("database show SIP/Registry").first
      sip_db = sip_db[ sip_db.keys.select { |x| x.is_a? Fixnum }.first ]
      sip_db = sip_db.gsub( /--[A-Z ]+?--/ , '').strip
      users = sip_db.split "\n"
      users.collect! do |user|
        fields = user.split ':'
        { :username => fields[4],
          :ip => fields[1].strip,
          :port => fields[2],
          :address =>  fields[6] }
      end
      @@sip_users[:users] = users
      @@sip_users[:expiration] = 90.seconds.from_now
    end
    @@sip_users[:users]
  end
  
  class << self
    
    # An introduction connects two endpoints together. The first argument is
    # the first person the PBX will call. When she's picked up, Asterisk will
    # play ringing while the second person is being dialed.
    #
    # The first argument is the person called first. Pass this as a canonical
    # IAX2/server/user type argument. Destination takes the same format, but
    # comma-separated Dial() arguments can be optionally passed after the
    # technology.
    #
    # TODO: Provide an example when this works.
    def introduce src, dst, hash={}
      cid     = hash.delete(:callerid) || hash.delete(:cid)
      options = hash.delete(:options) || hash.delete(:opts)
      dst << "|" << options if options
      call_and_exec src, "Dial", dst, cid
    end
    
    def call_and_exec channel, app, args=nil, callerid=nil
      args = { :channel => channel
               :application => app }
      args[:data] = args if args
      args[:callerid] = callerid if callerid
      originate args
    end
    
    def overhear their_channel, your_channel
      
    end
    
    
    def call chan, code=nil, &block
      raise "Cannot provide both a String and a block!" if code && block_given?
      ip = 'localhost' # TODO: How to get this?!
      originate :application => "AGI",
                :data => "agi://#{ip}/?call_id=",
                :channel => chan
      
      # TODO: Initiate an origination that comes back
      # into Adhearsion and runs either a certain block
      # of code or eval()s a String of dialplan code.
    end
    
    def originate hash
      # This is an ugly hack to use until RAI's AMI work is ported in.
      h = {}
      h['Application'] = hash.delete :app
      hash.each { |k,v| h[k.to_s.titleize] = v }
      @@rami_client.originate h
    end
  
    def record hash={}, &block
      # TODO: Implement me!
      raise NotImplementedError
    
      # defaults = {:file => "#{String.random(5)}", :folder => nil,
      #             :channel => Thread.current[:VARS]['channel'], :format => 'wav', :mix => '1'}
      # defaults = defaults.merge hash
      # PBX.rami_client.... # TODO
    end
    
    # private
    # CALL_BLOCK_CACHE = {}
    # def handle_call_specifically expiration=3.minutes.from_now, &block
    #   # Find a random, unused id
    #   while CALL_BLOCK_CACHE[id = rand(1_073_741_823)]; end  # 1073741823 is the Fixnum max
    #   CALL_BLOCK_CACHE[id] = [expiration, block]
    # end
  end
  
end
