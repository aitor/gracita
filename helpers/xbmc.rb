=begin Adhearsion metadata

  name: Xbox Media Center Controller
  author:
    name: Jay Phillips
    blog: http://jicksta.com
    email: Jicksta -at- Gmail.com
  instructions: >
      Hacked xbox owners can use this helper to remotely control
      their Xbox Media Center (XBMC) application. It works by
      sending HTTP requests to XBMC's web server (which must be
      enabled first), potentially emulating many different tasks.
      
      See the XBMC's HTTP API at 
      http://www.xboxmediacenter.com/wiki/index.php?title=WebServerHTTP-API
      for a full list of the available commands. Most often you'll
      want to use the SendKey command in a loop, though, to take
      in input. Here is how you may do that:
        
      <pre>
      loop { XBMC.sendkey XBMC.translate!(wait_for_digit) }
      </pre>
      
      That will take an infinite loop receiving keypad input,
      converting it to the appropriate numerical key codes, then
      sending a "SendKey" command with the translated argument.

=end
class XBMC
  KEY_MAPPING = { '1'=>37, '2'=>166, '4'=>169, '5'=>11, '6'=>168, '8'=>167 }
  KEY_MAPPING.default = 0
  def XBMC.translate(key) KEY_MAPPING[key] end
  def XBMC.method_missing name, hash={}
    args = []
    hash = { :parameter => hash} unless hash.kind_of? Hash
    hash.merge({:command => name}).each { |k,v| args << "#{k}=#{v}" }
    open("http://#{hash['ip'] || $HELPERS['xbmc']['ip']}/xbmcCmds/xbmcHttp?#{args * '&'}").read
  end
end