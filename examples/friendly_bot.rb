$:.push File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
require "turntable_api/version"
require "turntable_api/bot"
require 'yaml'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

yaml = YAML.load_file(File.join(File.dirname(__FILE__), 'bot.yml'))
creds = yaml['bot']
bot = TurntableAPI::Bot.new(:auth => creds['auth'], :userid => creds['userid'], :logger => logger)

bot.start

# if anyone speaks, say hello
bot.on_command(:registered) do |cmd|
  name = cmd['name']
  if name != '@@@'
    text = "Hello, #{name}"
    bot.room_speak :text => text
  end
end

# upvote every new song that plays
bot.on_command(:newsong) do |cmd|
  songid = cmd['room']['metadata']['current_song']['_id']
  bot.vote :val => 'up', :songid => songid
end

# join the /industrial room 
bot.room_register :roomid => '4df1058699968e6b8a00168d'

while bot.connected()
  puts '.'
  sleep(50)
end

puts "Done"