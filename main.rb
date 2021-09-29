require 'socket'
require 'yaml'
require 'json'

def connect_twitch_chat
  # load conf file for twitch auth credentials
  puts "Loading config file for credentials..."
  $twitch_auth_conf = YAML.load_file('./auth/config.yaml')


  # Initiate and authenticate a connection to twitch irc
  puts "Connecting to twitch irc..."
  socket = TCPSocket.new("irc.chat.twitch.tv", 6667)
  socket.set_encoding "UTF-8"

  puts "Authenticating..."
  socket.print("PASS #{$twitch_auth_conf["oauth_token"]}\r\n")
  socket.print("NICK #{$twitch_auth_conf["nickname"]}\r\n")

  puts "Switching to channel..."
  socket.print("JOIN ##{$twitch_auth_conf["channel"]}\r\n")
  
  # Skip over the introduction of twitch chat
  puts "Skipping long intro message..."
  twitch_intro_msg = socket.gets(":End of /NAMES list\r\n")
  
  # Return socket starting with chat messages
  puts "Now reading chat!\n"
  return socket

end



def main
  # Load credentials file and connect to twitch irc
  socket_session = connect_twitch_chat()

  loop do
    # Get irc chat msg
    irc_response = socket_session.gets("\r\n")
    chat_msg = Hash.new()

    # If a ping message, pong back
    if irc_response.include? "PING :tmi.twitch.tv\r\n"
      socket_session.print("PONG :tmi.twitch.tv\r\n")
      puts "\033[0;34mGet Pong'd\e[0m"
  
    else
      # Do something with chat msg response
      chat_msg["username"] = irc_response[/^:([^!]*)/m, 1]
      chat_msg["text"] = irc_response[/##{$twitch_auth_conf["channel"]} :(.*?)\r\n/m, 1]

      puts "chat username: #{chat_msg["username"]}"
      puts "chat message text: #{chat_msg["text"]}"
      puts "chat_msg serialized to json: #{JSON.dump(chat_msg)}"
  
    end
  
  end
end

main()
