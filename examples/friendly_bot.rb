$:.push File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
require "turntable_api/version"
require "turntable_api/bot"
require 'yaml'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

yaml = YAML.load_file(File.join(File.dirname(__FILE__), 'bot.yml'))
puts yaml
creds = yaml['bot']
puts creds
bot = TurntableAPI::Bot.new(:auth => creds['auth'], :userid => creds['userid'], :logger => logger)
thrd = bot.start

# if anyone speaks, say hello
bot.on_command(:speak) do |cmd|
  name = cmd['name']
  if name != '@mybotname'
    bot.room_speak :text => "Hello, #{name}"
  end
end

# join the /industrial room
bot.room_register :roomid => '4df1058699968e6b8a00168d'
thrd.join
