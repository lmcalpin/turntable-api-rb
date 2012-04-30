require 'rubygems'
require 'websocker'
require 'json'
require 'digest/sha1'
require 'httparty'

module TurntableAPI
  class Bot
    attr_reader :connected, :roomid
    
    def initialize(opts = {})
      @userid = opts[:userid]
      @clientid = opts[:clientid] || "#{Time.now.to_i}-#{rand}"
      @auth = opts[:auth]
      @logger = opts[:logger] || Logger.new(STDOUT)
      @msgId = 0
      @command_handlers ||= {}
      @response_handler ||= {}
      @received_heartbeat = false
    end

    def start
      connect
    end
    
    def room_register(roomid)
      @ws.close unless @ws.nil?
      if roomid.instance_of?(Hash) then roomid = roomid[:roomid] end
      connect(roomid)
      call_api 'room.register', :roomid => roomid
      @roomid = roomid
    end
    
    def room_vote(opts)
      dir = opts[:val]
      songid = opts[:songid]
      raise ArgumentError, "dir and songid are required" if songid.nil? or dir.nil?
      opts[:vh] ||= hash("#{@roomid}#{dir}#{songid}")
      opts[:th] ||= hash(rand.to_s)
      opts[:ph] ||= hash(rand.to_s)
      send_command('room_vote', opts)
    end
    alias_method :vote, :room_vote
    
    # sends a command and sets up a callback that triggers
    # when the reply is received
    def on_response(cmd, opts={}, &blk)
      msg_id = send_command cmd, opts
      @response_handler[msg_id] = blk
    end
    
    def method_missing(meth, *args)
      @logger.debug "method_missing #{meth}: #{args}"
      hash = args[0] unless args.empty?
      hash ||= {}
      send_command(meth, hash)
    end
    
    # send a command to Turntable.FM
    def send_command(command, opts={})
      command = command.to_s.sub('_', '.')
      call_api(command, opts)
    end
    
    # triggered when we receive a command from Turntable.FM
    def on_command(command, &blk)
      @command_handlers[command.to_sym] = blk
    end
    
    def on_ready(&blk)
      @ready_handler = blk
    end
    
    def on_error(&blk)
      @error_handler = blk
    end

    def on_message(msg)
      @logger.debug "Received: #{msg}"
      if msg == "~m~10~m~no_session"
        authenticate
      elsif msg =~ /~m~[0-9]+~m~(~h~[0-9]+)/
        hb = $1
        @ready_handler.call unless @received_heartbeat or @ready_handler.nil?
        @received_heartbeat = true
        send_text(hb)
      else
        msg =~ /~m~\d*~m~(\{.*\})/
        json = JSON.parse($1)
        command = json["command"]
        err = json["err"]
        msgid = json["msgid"]
        @error_handler.call(err) unless @error_handler.nil? or err.nil?
        unless command.nil?
          blk = @command_handlers[command.to_sym]
          blk.call(json) unless blk.nil?
        end
        unless @response_handler[msgid].nil?()
          blk = @response_handler[msgid]
          blk.call(json) unless blk.nil?
          @response_handler.delete(msgid)
        end
      end
    end
    
    private
    
    def connect(roomid='unknown')
      @ws = Websocker::Client.new(:host => chatserver(roomid), :path => "/socket.io/websocket")
      @ws.connect
      @ws.on_message do |msg|
        on_message msg
      end
      @ws.on_closed do
        on_closed
      end
      @listener_thread = @ws.listen
      @connected = true
    end
    
    def on_closed
      @connected = false
      Thread.kill(@listener_thread) unless @listener_thread.nil?
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
      return messageId
    end
    
    def send_text(txt)
      msg = "~m~#{txt.length}~m~#{txt}"
      send_raw(msg)
    end
    
    def send_raw(msg)
      @logger.debug "Sent: #{msg}"
      @ws.send(msg)
    end
    
    def next_message_id
      @msgId += 1
    end
    
    def hash(msg)
      Digest::SHA1.hexdigest(msg)
    end
    
    def chatserver(roomid)
      resp = HTTParty.get("http://turntable.fm/api/room.which_chatserver?roomid=#{roomid}").body
      JSON.parse(resp)[1]["chatserver"][0]
    end  
  end

end
