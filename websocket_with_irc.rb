#-*- coding: utf-8 -*-
require "rubygems"
require "em-websocket"
require "socket"

MAX_LOG = 100  # max log size

class IRCClient

  def initialize
    @server = "192.168.1.1"
    @servername = "IRCServerName"
    @port = 6667
    @eol = "\r\n"
    @username = "wsirc"
    @nickname = "wsirc"
    @realname = "wsirc"
    @channel = "#websocket_with_irc"
    @irc = nil
    @write_start = false
  end

  def connect
    @irc = TCPSocket.new(@server, @port)
  end

  def send_cmd(cmd)
    @irc.write(cmd.to_s + @eol)
  end

  def login
    send_cmd("USER #{@username} hostname servername :#{@realname}")
    send_cmd("NICK #{@nickname}")
  end

  def join
    send_cmd("JOIN #{@channel}")
  end

  def close(msg = "bye!")
    send_cmd("QUIT :#{msg}")
    @irc.close
    @irc = nil
  end

  def send_msg(message)
    send_cmd("PRIVMSG #{@channel} :#{message}")
  end

  def receiveloop(obj = nil)
    begin
      while msg = @irc.gets.to_s.split
        unless msg.empty?
          #p ["msg: ", msg.join(" ")]

          if @write_start
            unless obj.nil?
              if msg.include?("PRIVMSG")
                username = msg.shift.scan(/\~(.+)\@/).flatten[0]
                command = msg.shift
                channel = msg.shift
                talk = msg.join(" ").reverse.chop.reverse.force_encoding("UTF-8")
                obj.each do |k, v|
                  v.send("(#{username}) #{talk}") if v.signature != 2
                end
              end
            end
          end

          send_cmd("PONG #{msg[1]}") if msg[0] == "PING"
          if msg[1] == '376' || msg[1] == '422'
            join if !@write_start
            @write_start = true
          end
          break if msg[0] == "ERROR"
        end
      end
    rescue
      p ["error: ", $!]
      retry
    ensure
      close
    end
  end

  def run_receive_loop(obj = nil)
    th = Thread.new(obj) do |tobj|
      receiveloop(tobj)
    end
  end

  def writable?
    return @write_start
  end
end


class WebSocket
  def initialize
    @port = 8089
  end

  def run
    @irc = IRCClient.new

    EM::run do
      @channel = Hash.new
      @logs = Array.new
      
      puts "start websocket server. port=#{@port}"
      EventMachine::WebSocket.start({:host => "0.0.0.0",
                                      :port => @port}) do |ws|
        sid = ws.signature
        @channel[sid] = ws if !@channel.key?(sid) 
        @logs.shift if @logs.length > MAX_LOG
        
        ws.onopen{
          #puts "<#{sid}> connected"
          @logs.push("hello <#{sid}>")
          @irc.send_msg("<#{sid}> connected") if @irc.writable?
        }
        
        ws.onmessage{|msg|
          #puts "<#{sid}> #{msg}"
          @logs.push("<#{sid}> #{msg}")
          @channel.each do |k, v|
            v.send("#{msg}") if v.signature != sid
          end

          @irc.send_msg("<#{sid}> #{msg}") if @irc.writable?
        }
        
        ws.onclose{
          #puts "<#{sid}> connection closed"
          @logs.push("<#{sid}> disconnected")
          @channel.delete(sid)

          @irc.send_msg("<#{sid}> disconnected") if @irc.writable?
        }
      end

      # connect to irc
      @irc.connect
      @irc.login
      @irc.run_receive_loop(@channel)
      
      EM::defer do
      end
    end
  end
end

# ----
ws = WebSocket.new
ws.run
