require 'active_support'

require 'runtime_profiler/profiler'
require 'method_meter'

module RuntimeProfiler
  include ActiveSupport::Configurable

  config_accessor :instrumented_constants do
    []
  end

  config_accessor :instrumented_paths do
    %w(app lib)
  end

  config_accessor :instrumented_sql_commands do
    %w(SELECT INSERT UPDATE DELETE)
  end

  config_accessor :output_path do
    if defined?(Rails) && Rails.respond_to?(:root)
      File.join(Rails.root.to_s, 'tmp')
    else
      'tmp'
    end
  end

  class << self
    def configure
      Rails.application.eager_load! rescue nil
      yield self if block_given?
    end

    def profile!(key, konstants)
      konstants = konstants.is_a?(Array) ? konstants : [konstants]
      profiler = Profiler.new(konstants)
      profiler.prepare_for_instrumentation

      MethodMeter.measure!(key) { yield }

      profiler.save_instrumentation_data
    end

    def runtime(label='for the block')
      result = nil

      elapsed_time = Benchmark.realtime { result = yield }

      puts
      puts '~~~~> ELAPSED TIME (%s): %s' % [label, elapsed_time * 1000]
      puts

      result
    end
  end
end