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

  context "when not logged in," do
    before(:each) do
      @bot.stub!(:start) do
        @bot.send(:on_message, '~m~10~m~no_session')
      end
    end
    it "should attempt to establish a session" do
      @bot.stub!(:send_raw)
      @bot.should_receive(:send_raw).with('~m~93~m~{"api":"user.authenticate","msgid":2,"userid":"user","clientid":"clientid","userauth":"auth"}')
      @bot.start
    end
  end
end