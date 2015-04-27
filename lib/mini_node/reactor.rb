require "socket"

require "mini_node/event_emitter"
require "mini_node/server"

module MiniNode
  class Reactor
    include EventEmitter

    def initialize
      @streams = []
    end

    def add_io(io)
      MiniNode::Stream.new(io).tap do |stream|
        add_stream stream
      end
    end

    def add_stream(stream)
      @streams << stream

      stream.on(:close) do
        remove_stream stream
      end
    end

    def listen(host, port)
      server = Server.new(TCPServer.new(host, port))

      add_stream(server)

      server.on(:accept) do |client|
        add_stream(client)
      end

      server
    end

    def start
      loop { tick }
    end

    def tick
      emit(:next_tick)

      readable, writeable, _ = IO.select(@streams, @streams, [], 1)

      readable.each(&:handle_read)   if readable
      writeable.each(&:handle_write) if writeable
    end

    protected

    def remove_stream(stream)
      @streams.delete stream
    end
  end
end
