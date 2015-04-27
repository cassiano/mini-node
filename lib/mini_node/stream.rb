module MiniNode
  class Stream
    include EventEmitter

    CHUNK_SIZE = 16 * 1024

    def initialize(io)
      @io = io
      @write_buffer = ''
    end

    def closed?
      @io.closed?
    end

    def handle_read
      puts ">>> handle_read called" if DEBUG_MODE

      data = @io.read_nonblock(CHUNK_SIZE)
      emit(:data, data)
    rescue EOFError, Errno::ECONNRESET
      close
    end

    def handle_write
      if @write_buffer.empty?
        emit(:empty_write_buffer)
      else
        buffer, @write_buffer = @write_buffer, ''
        write(buffer)
      end
    end

    def write(data)
      chomped_data = data.chomp

      if DEBUG_MODE
        if chomped_data.size > 40
          puts "Writing `#{chomped_data[0..19]} ... #{chomped_data[-20..-1]}`"
        else
          puts "Writing `#{chomped_data}`"
        end
      end

      bytes_written = @io.write_nonblock(data)
      remaining_bytes = data[bytes_written..-1] || ''

      if DEBUG_MODE
        puts "#{bytes_written} bytes written"
        puts "#{remaining_bytes.size} bytes remaining"
      end

      @write_buffer << remaining_bytes if remaining_bytes.size > 0
    rescue Errno::EAGAIN, Errno::EPIPE
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
  end
end
