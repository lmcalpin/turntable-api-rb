require 'rubygems'
require 'websocker'
require 'json'

module TurntableAPI
  class Bot
    def initialize(opts = {})
      @userid = opts[:userid]
      @clientid = opts[:clientid] || "#{Time.now.to_i}-#{rand}"
      @auth = opts[:auth]
      @logger = opts[:logger] || Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @roomid = opts[:roomid]
      @msgId = 0
      @command_handlers ||= {}
    end

    def start
      @ws = Websocker::Client.new(:host => "chat2.turntable.fm", :path => "/socket.io/websocket", :logger => @logger)
      # for testing...
      #@ws = Websocker::Client.new(:host => "localhost", :port => 8887, :logger => @logger)
      @ws.connect
      @ws.on_message do |msg|
        on_message msg
      end
      @ws.on_closed do
        on_closed
      end
      listener_thread = @ws.listen
    end
    
    def method_missing(meth, *args, &block)
      @logger.debug "method_missing #{meth}: #{args}"
      command = meth.to_s.sub('_', '.')
      hash = args[0] unless args.empty?
      hash ||= {}
      call_api command, hash
    end
    
    def on_command(command, &block)
      @command_handlers[command.to_sym] = block
    end

    def on_message(msg)
      if msg == "~m~10~m~no_session"
        authenticate
      elsif msg =~ /~m~[0-9]+~m~(~h~[0-9]+)/
        # heartbeat
        hb = $1
        send_text(hb)
      else
        msg =~ /~m~\d*~m~(\{.*\})/
        json = JSON.parse($1)
        command = json["command"]
        @logger.debug "Looking up command handler for #{command} in #{json}"
        block = @command_handlers[command.to_sym]
        @logger.debug "Found #{@command_handlers}"
        block.call(json) unless block.nil?
      end
    end
    
    private
    
    def on_closed
      puts "Closed!"
    end

    def authenticate
      call_api "user.authenticate"
    end

    def call_api(api, addl_params={})
      messageId = next_message_id
      params = { 'api' => api, 'userid' => @userid, 'clientid' => @clientid, 'userauth' => @auth, 'msgid' => messageId }
      params['roomid'] = @roomid if @roomid
      params.merge!(addl_params)
      send_text(params.to_json)
    end
    
    def send_text(txt)
      msg = "~m~#{txt.length}~m~#{txt}"
      send_raw(msg)
    end
    
    def send_raw(msg)
      @ws.send(msg)
    end
    
    def next_message_id
      @msgId += 1
    end
  end

end
