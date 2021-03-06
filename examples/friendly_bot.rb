#$:.push File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
require 'turntable_api'
require 'yaml'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

yaml = YAML.load_file(File.join(File.dirname(__FILE__), 'bot.yml'))
creds = yaml['bot']
myname = creds['name']
bot = TurntableAPI::Bot.new(:auth => creds['auth'], :userid => creds['userid'], :logger => logger)

bot.start

# if anyone comes into the room, say hello
bot.on_command(:registered) do |cmd|
  name = cmd['user'][0]['name']
  unless name == myname
    text = "Hello, #{name}"
    bot.room_speak :text => text
  end
end

# turntable does not allow autobop; this is just an example on how to use the API
# http://faq.turntable.fm/customer/portal/articles/258935
# upvote every new song that plays
#bot.on_command(:newsong) do |cmd|
#  songid = cmd['room']['metadata']['current_song']['_id']
#  bot.vote :val => 'up', :songid => songid
#end

# join a room 
bot.room_register :roomid => '4f4f938fa3f7517d61003ae7'

while bot.connected()
  puts '.'
  sleep(50)
end

puts "Done"