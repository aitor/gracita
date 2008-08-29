# Micromenus Adhearsion helper
# Copyright 2006 Jay Phillips
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'rubygems'
require 'builder'
require 'webrick'
require 'stringio'

class WEBrick::HTTPRequest
  def ip() @peeraddr[3][/(\d{1,3}\.){3}\d{1,3}/] end
end

# Micromenu catchers are special hooks that allow integration
# between micromenus and incoming calls (specifically, incoming
# calls generated by the micromenus)
$MICROMENU_CALL_HOOKS = []
class << $MICROMENU_CALL_HOOKS
  def purge_expired!
    self.synchronize { |hooks| hooks.delete_if { |h| h.expiration < Time.now } }
  end
end

class MicromenusServlet < WEBrick::HTTPServlet::AbstractServlet
  
  class MicromenuGenerator

    def initialize request, model, io=$stdout
      @request, @io, @config = request, io, []
      @xml = Builder::XmlMarkup.new(:target => @io, :indent => 3)
      self.extend model
    end

    attr_accessor :name, :io, :config, :request

    def process request
      route = request.dup
      
      if route.empty?
        start "Error" do
          build_text "Whoops!"
          build_text "You forgot to include the target Micromenu in the URL path!"
        end
        return
      end
      
      title = " Adhearsion Micromenus"
      
      filename = route.shift
      load_menu filename
      until route.empty?
        segment = route.shift
        broken = segment.match(/^([\w_.]+)(;(\d*))?$/)
        
        segment, id = broken[1], broken[3]
        id = nil if id && id.empty?
        
        matches = @config.select do |x|
          x[:type] == :menu && x[:text].nameify == segment
        end
        dest = matches[(id.simplify || 1) - 1]
        
        
        if dest then
          @config.clear
          title = dest[:text]
          dest[:block].call
        else
          start "Error" do
            item '404 Not found!'
            item "Req: #{request.inspect}"
            return
          end
        end
      end
      
      # Let any headers override the default title
      @config.each do |item|
        if item[:type] == :heading
          title = @config.delete(item)[:text]
          break
        end
      end
      
      start title do
        @config.each do |item|
          case item[:type]
          when :menu
            build_menu item[:text], item[:uri], request
          when :item
            build_text item[:text]
          when :heading
            build_header item[:text]
          when :image
            build_image item[:text]
		      when :call
		        build_call item[:number], item[:text]
          end
        end
      end
    end
    def load_menu filename
      @config.clear
      file = File.join('config','helpers', 'micromenus', filename + '.rb')
      unless File.readable? file
        item "Target Micromenu doesn't exist!"
        item "Did you input the URL correctly?"
      else
        eval File.read(File.join('config','helpers', 'micromenus', filename + '.rb'))
      end
      @config
    end
    def join_url url, *pages
      url *= '/' if url.is_a? Array
      '/' + if url.empty?
        pages * '/'
      else
        ((url[-1] == ?/) ? url : url + "/") + pages * '/'
      end
    end
    def get_refresh() @refresh end


  module AjaxResponse
    
    def content_type() "application/xml" end
    
    def start name='', &block
      @xml.ul do
        yield
      end
    end
    
    def build_menu str, uri, request
      #build_menu item[:text], item[:uri], request
      #request.flatten! if request.is_a? Array
      @xml.li do
        @xml.a str, :href => join_url('ajax', request, uri), :rel => 'ajax'
      end
    end
    
    def build_text str
      @xml.li { @xml.span str }
    end
    
    def build_prompt
      
    end
    
    def build_image filename, hash=nil
      @xml.img :src => "/images/#{filename}"
    end
    
    def build_header str
      @xml.li { @xml.h1 str }
    end
    
    def build_call number, name=number
      @xml.a name, :href => "javascript:dial(#{number})"
      @xml.br
    end
  end

	
    module PolycomPhone
      
      def content_type() "text/html" end
      
      def start name='', &block
        @xml.html do
          @xml.head do
            @xml.title name
          end
          @xml.body do
            yield
          end
        end
      end
      
      def build_menu str, uri, request
        #build_menu item[:text], item[:uri], request
        #request.flatten! if request.is_a? Array
        @xml.p { @xml.a str, :href => join_url(request, uri) }
      end
      
      def build_text str
        @xml.p str
      end
      
      def build_prompt
        
      end
      
      def build_image filename, hash=nil
        @xml.img :src => "/images/#{filename}"
      end
      
      def build_header str
        @xml.h1 str
      end
      
      def build_call number, name=number
        @xml.a name, :href => "tel://#{number}"
        @xml.br
      end
    end

    module XulUi
      
	    include PolycomPhone
      def content_type() "application/vnd.mozilla.xul+xml" end

      def start name='', &block
        @xml.instruct!
        @xml.instruct! 'xml-stylesheet', :href => "chrome://global/skin/", :type => "text/css"
        @xml.instruct! 'xml-stylesheet', :href => "/stylesheets/firefox.xul.css", :type => "text/css"
        @xml.window :title => name,
          'xmlns:html' => "http://www.w3.org/1999/xhtml",
          :xmlns => "http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul" do
          @xml.vbox :id => 'haupt' do
            #@xml.label name, :class => 'header'
            yield
          end
        end
      end

      def build_call number, name=number
        # The tel:// UI doesn't do Firefox much good. Mexuar, maybe?
        @xml.html:a, name, :href => "tel://#{number}"
        @xml.html:br
      end
      
      def build_menu str, uri, request
        @xml.html:a, str, :href => join_url(request, uri)
      end
      
      def build_text str
        @xml.description str
        @xml.html:br
      end

      def build_image filename, hash=nil
        @xml.html:img, :src => "/images/#{filename}"
      end
      
      def build_header str
        @xml.label str, :class => 'header'
      end
      
    end
    module ModernUi
      
      CSSs = %w"carousel columnav microbrowsers"
      JAVASCRIPTS = %w"yahoo event dom animation connection container dragdrop carousel columnav"
      INIT = %{
        try { document.execCommand('BackgroundImageCache', false, true); } catch(e) {}
        function init() {
            var cn_cfg = { prevElement: 'columnav-prev', source: document.getElementById('main') };
            var cn = new YAHOO.extension.ColumNav('columnav', cn_cfg);
            
            YAHOO.namespace("example.container");
            
            YAHOO.example.container.panel1 = new YAHOO.widget.Panel("unique", { width:"350px", visible:true, draggable:true, close:true } );
            YAHOO.example.container.panel1.render();
            
            /*
  					YAHOO.example.container.panel2 = new YAHOO.widget.Panel("panel2", { width:"300px", visible:true, draggable:true, close:true } );
  					YAHOO.example.container.panel2.setHeader("Panel #2 from Script");
  					YAHOO.example.container.panel2.setBody("This is a dynamically generated Panel.");
  					YAHOO.example.container.panel2.setFooter("End of Panel #2");
  					YAHOO.example.container.panel2.render(document.body);
          	*/
          	
          	YAHOO.util.Event.addListener("show1", "click", YAHOO.example.container.panel1.show, YAHOO.example.container.panel1, true);
          	YAHOO.util.Event.addListener("hide1", "click", YAHOO.example.container.panel1.hide, YAHOO.example.container.panel1, true);
          	
          	/*
          	YAHOO.util.Event.addListener("show2", "click", YAHOO.example.container.panel2.show, YAHOO.example.container.panel2, true);
          	YAHOO.util.Event.addListener("hide2", "click", YAHOO.example.container.panel2.hide, YAHOO.example.container.panel2, true);
          	*/
        }
        YAHOO.util.Event.addListener(window, 'load', init);
        
      }
      
      def content_type() "text/html" end
      
      def start name='', &block
        @xml.html do
          @xml.head do
            @xml.title name
            CSSs.each { |css| @xml.link :rel => 'stylesheet', :type => 'text/css', :href => "/stylesheets/#{css}.css"}
            
            JAVASCRIPTS.each { |script| @xml.script :type => 'text/javascript', :src => "/javascripts/#{script}.js" do end }
            @xml.script INIT, :type => 'text/javascript'
          end
          @xml.body do
            
            @xml.div :id => "unique", :class => 'microbrowser' do
              
              @xml.div :class => "hd" do
                @xml.div :class => "tl" do
                  @xml.div :class => 'prevButton' do
                    @xml.a "Back", :href => "javascript:void(0)", :id => "columnav-prev"
                  end  
                end
                @xml.h1 name
                @xml.div :class => 'tr' do
                  @xml.span "Close", :class => "container-close"
                end
              end 
              
              @xml.div :class => 'bd' do
                @xml.div :id => 'columnav', :class => "carousel-component" do
                  @xml.div :class => "carousel-clip-region" do
                    @xml.ul :class => "carousel-list" do end
                  end
                end
            
                @xml.ul :id => 'main', :style => 'display:none' do
                  yield
                  # @xml << %{
                  #   <li><a href="/viewaddressbook">View Address book again</a>
                  #     <ul><li>
                  #       <a href="http://google.com">Jicksta.com</a>
                  #     </li></ul></li>
                  #   <li><a href='#'>Linking to Somewhere</a></li>
                  #   <li><strong>Not</strong> linking to somewhere</li>
                  #   }
                end
              end
              
              @xml.div :class => "ft" do
                @xml.hr           
              end
              
            end
          end
        end
      end
      
      def build_menu str, uri, request
        #build_menu item[:text], item[:uri], request
        #request.flatten! if request.is_a? Array
        @xml.li { @xml.a str, :rel => 'ajax', :href => join_url('ajax', request, uri) }
      end
      
      def build_text str
        @xml.li { @xml.span str }
      end
      
      def build_prompt
        
      end
      
      def build_image filename, hash=nil
        @xml.li { @xml.img :src => "/images/#{filename}" }
      end
      
      def build_header str
        @xml.li { @xml.h1 str }
      end
      
      def build_call number, name=number
        @xml.li { @xml.a name, :href => "javascript:call(#{number})" }
      end
    end
    

    private


    def image name
      name += '.bmp' unless name.index ?.
      @config << {:type => :image, :text => name}
    end
	  def refresh_every time
        @refresh = time
  	end
    def heading str
      @config << {:type => :heading, :text => str}
    end
    alias header heading

    def item title, &block
      hash = {:text => title, :type => :item }
      if block_given?
        hash[:block], hash[:type], hash[:uri] = block, :menu, title.nameify
        collisions = @config.select { |c| c[:type] == :menu && c[:text].nameify == hash[:uri]}.length
        hash[:uri] += ";#{collisions + 1}" if collisions.nonzero?
      end
      @config << hash
    end
    def items array
      array.each { |x| item x }
    end

    def guess_sip_user
      return @guessed_user if @guessed_user
      selection = PBX.sip_users.select { |x| x[:ip] == request.ip }.first
      @guessed_user = selection ? selection.username : nil
    end

    def call number, name=number, &block
      instance = {:type => :call, :text => name, :number => number}
      if block_given?
        $MICROMENU_CALL_HOOKS.purge_expired!
        num = "555551337#{rand(8_999_999_999) + 1_000_000_000}"
        instance[:number] = num
        $MICROMENU_CALL_HOOKS.synchronize do |hooks|
          hooks << { :expiration => 90.seconds.from_now, :extension => num, :hook => block }
        end
      end
  		@config << instance
	  end
	  
    def action title, &block
      # Just like menu() but without a submenu.
      # Useful for performing an action and refreshing.
    end
  end
  
  USER_AGENT_MAP = {
    "Polycom" => MicromenuGenerator::PolycomPhone
  }
  
  def do_GET(request, response)
    response.status = 200
    log "Request from: " + request['User-Agent']
    
    route = request.path[1..-1].split '/'
    handler = nil
    
    if route.first == 'ajax'
      handler = MicromenuGenerator::AjaxResponse
      route.shift
    end
    
    if route.first == 'images'
      file = File.join(%w(config helpers micromenus images), route[1..-1])
      # TODO: Handle missing files
      response.content_type = WEBrick::HTTPUtils::mime_type file, WEBrick::HTTPUtils::DefaultMimeTypes
      response.body = File.read file
      
    elsif route.first == 'stylesheets'
      file = File.join %w(config helpers micromenus stylesheets), route[1..-1]
      response.content_type = 'text/css'
      response.body = File.read file
    elsif route.first == 'javascripts'
        file = File.join %w(config helpers micromenus javascripts), route[1..-1]
        response.content_type = 'text/javascript'
        response.body = File.read file
    else
      mg = MicromenuGenerator.new request, handler || resolve_brand(request['User-Agent']), StringIO.new
      response.content_type = mg.content_type
      response['Expires'] = 2

      mg.process route

      refresh = mg.get_refresh
  	  response['Refresh'] = refresh if refresh

  	  response.body = mg.io.string
    end
  end
  
  def resolve_brand useragent
    USER_AGENT_MAP.each do |k,v|
      return v if useragent.index k
    end
    MicromenuGenerator::ModernUi # Default to Class A browser
  end
end

$MICROMENUS_SERVER = Thread.new do
  micromenu_server = WEBrick::HTTPServer.new :Port => ($HELPERS['micromenus']['port'] || 1337)

  micromenu_server.mount '/', MicromenusServlet
  $HUTDOWN.hook {
    micromenu_server.stop
  }
  micromenu_server.start
end

# This before_call hook is the magic behind the call() method in the micromenus.
before_call :low do
  # PSEUDOCODE
  # Check extension for format. next unless it matches
  # Delete all expired hooks
  # Find first match in the collection of hooks
  # Pull the first match out of the collection
  # Execute that match's block finish
  extension = Thread.current[:VARS]['extension'].to_s
  
  next unless extension.length == 19 && extension.starts_with?("555551337")
  $MICROMENU_CALL_HOOKS.purge_expired!
  match = $MICROMENU_CALL_HOOKS.detect { |x| x.extension == extension }
  next unless match
  Thread.current[:VARS]['context'] = :interrupted
  +match.hook
end
