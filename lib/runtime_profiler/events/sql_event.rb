module RuntimeProfiler
  class SqlEvent
    attr_reader :started_at, :finished_at, :payload, :trace

    def initialize(args: , trace: )
      _name, @started_at, @finished_at, _unique_id, @payload = args
      @trace = sanitize_trace!(trace)
    end

    def recordable?
      return true unless RuntimeProfiler.instrumented_sql_commands.respond_to?(:join)
      instrumented_sql_matcher =~ sql
    end

    def total_runtime
      1000.0 * (@finished_at - @started_at)
    end

    def sanitized_sql
      sql.squish!

      sql.gsub!(/(\s(=|>|<|>=|<=|<>|!=)\s)('[^']+'|[\$\+\-\w\.]+)/, '\1xxx')
      sql.gsub!(/(\sIN\s)\([^\(\)]+\)/i, '\1(xxx)')
      sql.gsub!(/(\sBETWEEN\s)('[^']+'|[\+\-\w\.]+)(\sAND\s)('[^']+'|[\+\-\w\.]+)/i, '\1xxx\3xxx')
      sql.gsub!(/(\sVALUES\s)\(.+\)/i, '\1(xxx)')
      sql.gsub!(/(\s(LIKE|ILIKE|SIMILAR TO|NOT SIMILAR TO)\s)('[^']+')/i, '\1xxx')
      sql.gsub!(/(\s(LIMIT|OFFSET)\s)(\d+)/i, '\1xxx')

      sql
    end

    def key
      @key ||= Digest::MD5.hexdigest(sql.downcase)
    end

    private

    def sql
      @sql ||= @payload[:sql].dup
    end

    def instrumented_sql_matcher
      @instrumented_sql_matcher ||= /\A#{RuntimeProfiler.instrumented_sql_commands.join('|')}/i
    end

    def trace_path_matcher
      @trace_path_matcher ||= %r{^(#{RuntimeProfiler.instrumented_paths.join('|')})\/}
    end

    def sanitize_trace!(trace)
      return trace unless defined?(Rails)
      return trace unless Rails.respond_to?(:backtrace_cleaner)

      if Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
        Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
      end

      Rails.backtrace_cleaner.remove_silencers!

      if RuntimeProfiler.instrumented_paths.respond_to?(:join)
        Rails.backtrace_cleaner.add_silencer do |line|
          line !~ trace_path_matcher
        end
      end

      Rails.backtrace_cleaner.clean(trace)
    end
  end
end