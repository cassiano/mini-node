require "mini_node/stream"

module MiniNode
  class Server
    include EventEmitter

    def initialize(socket)
      @socket = socket
    end

    def handle_read
      begin
        connection = Stream.new(@socket.accept_nonblock)

        emit :accept, connection
      rescue Errno::EMFILE    # Too many open files
      end
    end

    def to_io
      @socket
    end
  end
end
