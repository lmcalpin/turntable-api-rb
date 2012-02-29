require 'spec_helper'

describe TurntableAPI::Bot do
  before(:all) do
    @bot = TurntableAPI::Bot.new :userid => 'user', :auth => 'auth', :clientid => 'clientid'
  end

  it "should convert any message to an API call dynamically" do
    @bot.stub!(:send_raw)
    @bot.should_receive(:send_raw).with('~m~98~m~{"text":"hi","api":"room.speak","msgid":1,"userid":"user","clientid":"clientid","userauth":"auth"}')
    @bot.room_speak :text => 'hi'
  end

  it "should invoke a block if we registered a callback for a command" do
    # register a callback for the 'speak' command
    @bot.on_command(:speak) do |cmd|
      @text = cmd['text']
    end
    # simulate receiving a message from Turntable where user ABCDEFGHIJKLMNOPQ says 'hi'
    @bot.on_message('~m~139~m~{"command": "speak", "userid": "123456789012345678901234", "name": "ABCDEFGHIJKLMNOPQ", "roomid": "4df1058699968e6b8a00168d", "text": "hi"}')
    @text.should eq('hi')
  end
  
  context "when not logged in," do
    before(:each) do
      @bot.stub!(:start) do
        @bot.on_message('~m~10~m~no_session')
      end
    end
    it "should attempt to establish a session" do
      @bot.stub!(:send_raw)
      @bot.should_receive(:send_raw).with('~m~93~m~{"api":"user.authenticate","msgid":2,"userid":"user","clientid":"clientid","userauth":"auth"}')
      @bot.start
    end
  end
end