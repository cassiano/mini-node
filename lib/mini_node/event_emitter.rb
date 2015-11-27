module MiniNode
  module EventEmitter
    def callbacks
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def on(event, &callback)
      puts "[#{Time.now}] Registering event `#{event}` of #{self.class.name}" if DEBUG_MODE

      callbacks[event] << callback

      callback.object_id
    end

    def unregister(event, callback_id)
      puts "[#{Time.now}] Unregistering callback ID `#{callback_id}` for event `#{event}` of #{self.class.name}" if DEBUG_MODE

      callbacks[event].delete_if { |callback| callback.object_id == callback_id }
    end

    def emit(event, *args)
      return if callbacks[event].size == 0

      puts "[#{Time.now}] Emitting `#{event}` of `#{self}` for #{callbacks[event].size} registered callback(s) with #{args.size} argument(s)" if DEBUG_MODE

      callbacks[event].each do |callback|
        begin
          callback.call(*args)
        rescue => e
          puts ">>> Exception detected: `#{e.message}`"
        end
      end
    end
  end
end
