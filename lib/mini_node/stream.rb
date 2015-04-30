module MiniNode
  class Stream
    attr_reader :total_bytes_written, :total_bytes_read

    include EventEmitter

    CHUNK_SIZE = 16 * 1024

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
      puts ">>> handle_read called" if DEBUG_MODE

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
        write @write_buffer, true
      end
    end

    def write(data, replace_buffer = false)
      if DEBUG_MODE
        chomped_data = data.chomp

        if chomped_data.size > 40
          puts "Writing `#{chomped_data[0..19].inspect} ... #{chomped_data[-20..-1].inspect}`"
        else
          puts "Writing `#{chomped_data.inspect}`"
        end
      end

      bytes_written = @io.write_nonblock(data)
      @total_bytes_written += bytes_written
      remaining_data = data[bytes_written..-1] || ''

      if DEBUG_MODE
        puts "#{bytes_written} bytes written"
        puts "#{remaining_data.size} bytes remaining"
      end

      if remaining_data.size > 0
        if replace_buffer
          @write_buffer = remaining_data
        else
          @write_buffer << remaining_data
        end
      end
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

    def to_s
      @io.class.to_s
    end
  end
end
