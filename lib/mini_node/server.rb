require "mini_node/stream"

module MiniNode
  class Server
    include EventEmitter

    def initialize(socket)
      @socket = socket
    end

    def handle_read
      connection = Stream.new(@socket.accept_nonblock)
      emit(:accept, connection)
    end

    def to_io
      @socket
    end
  end
end
