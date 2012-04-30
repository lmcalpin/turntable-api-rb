$:.push File.expand_path('../lib', File.dirname(__FILE__))

require 'rubygems'
require "turntable_api/version"
require "turntable_api/bot"
require 'yaml'
require 'lastfm'
require 'rexml/document'

logger = Logger.new(STDOUT)

yaml = YAML.load_file(File.join(File.dirname(__FILE__), 'bot.yml'))
creds = yaml['bot']
bot = TurntableAPI::Bot.new(:auth => creds['auth'], :userid => creds['userid'], :logger => logger)
last_fm_api_key = yaml['lastfm']['key'] 

bot.start

# if anyone speaks, say hello
bot.on_command(:speak) do |cmd|
  text = cmd['text']
  case text
  when '/similar'
    roomInfo = bot.on_response(:room_info) do |info|
        song = info["room"]["metadata"]["current_song"]
        unless song.nil?
            begin
                artist = song["metadata"]["artist"]
                # look up similar artists on last.fm
                body = HTTParty.get("http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&artist=assemblage%2023&api_key=#{last_fm_api_key}&limit=15").body
                doc = REXML::Document.new(body)
                artists = doc.elements.collect('lfm/similarartists/artist/name') do |a|
                    a.text
                end
                artistsCsv = artists.join(', ')
                
                text = "Artists similar to #{artist}: #{artistsCsv}"
                bot.room_speak :text => text
             rescue Exception => e
                puts e
             end
        end
    end
  end
end

# join a room
bot.room_register :roomid => '4df1058699968e6b8a00168d'

while bot.connected()
  puts '.'
  sleep(50)
end

puts "Done"