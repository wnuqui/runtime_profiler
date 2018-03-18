module RuntimeProfiler
  class ProcessActionEvent
    attr_reader :started_at, :finished_at, :payload

    def initialize(args:)
      _name, @started_at, @finished_at, _unique_id, @payload = args
    end

    def total_runtime
      1000.0 * (@finished_at - @started_at)
    end

    def view_runtime
      @view_runtime ||= @payload[:view_runtime]
    end

    def db_runtime
      @db_runtime ||= @payload[:db_runtime]
    end

    def recordable?
      true  # NB: We may be putting login on this in the future
    end

    def path
      @path ||= @payload[:path].gsub(/(\S=)(?:(?!&).)+/, '\1xxx').gsub(/(\d+)/, 'xxx')
    end

    def key
      @key ||= Digest::MD5.hexdigest(path.downcase)
    end
  end
end