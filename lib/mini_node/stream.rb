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
      if @write_buffer.empty?
        emit :empty_write_buffer
      else
        write ''
      end
    end

    def write(data)
      raise "Non-empty buffer cannot be written to closed stream" if !@write_buffer.empty? && closed?

      return if closed?

      @write_buffer << data if data.size > 0

      begin
        bytes_written = @io.write_nonblock(@write_buffer)
        @total_bytes_written += bytes_written
        @write_buffer.slice! 0, bytes_written
      rescue Errno::EAGAIN, Errno::EPIPE
      end
    end

    def close
      close_io = -> do
        emit :close
        @io.close
      end

      if @write_buffer.empty?
        close_io.call
      else
        on :empty_write_buffer, &close_io
      end
    end

    # Pipe method.
    def |(another_stream)
      on :data do |data|
        another_stream.write data
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
