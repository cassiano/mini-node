module MiniNode
  class Stream
    attr_reader :total_bytes_written, :total_bytes_read

    include EventEmitter

    CHUNK_SIZE = 512 * 1024

    def initialize(io)
      @io           = io
      @write_buffer = ''

      @total_bytes_written = 0
      @total_bytes_read    = 0
    end

    def closed?
      @io.closed?
    end

    def handle_read
      data = @io.read_nonblock(CHUNK_SIZE)
      @total_bytes_read += data.bytesize
      emit :data, data
    rescue EOFError, Errno::ECONNRESET
      close
    end

    def handle_write
      flush

      emit(:empty_write_buffer) if @write_buffer.empty?
    end

    def write(data)
      @write_buffer << data
    end

    def flush
      return if @write_buffer.empty? || closed?

      begin
        bytes_written = @io.write_nonblock(@write_buffer)
        @total_bytes_written += bytes_written
        @write_buffer.slice! 0, bytes_written
      rescue Errno::EAGAIN, Errno::EPIPE
      end
    end

    def close
      if @write_buffer.empty?
        emit(:close)
        @io.close
      else
        on(:empty_write_buffer) do
          emit(:close)
          @io.close
        end
      end
    end

    def pipe_to(another_stream)
      on(:data) do |data|
        another_stream.write(data)
      end
    end

    def to_io
      @io
    end

    def to_s
      @io.class.to_s
    end
  end
end
