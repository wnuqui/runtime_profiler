require 'active_support'

require 'runtime_profiler/profiler'
require 'method_meter'

module RuntimeProfiler
  include ActiveSupport::Configurable

  config_accessor :profiled_constants do
    []
  end

  config_accessor :profiled_paths do
    %w[app lib]
  end

  config_accessor :profiled_sql_commands do
    %w[SELECT INSERT UPDATE DELETE]
  end

  config_accessor :output_path do
    if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
      File.join(Rails.root.to_s, 'tmp')
    else
      'tmp'
    end
  end

  config_accessor :excepted_methods do
    []
  end

  class << self
    def configure
      begin
        Rails.application.eager_load!
      rescue StandardError
        nil
      end
      yield self if block_given?
    end

    def profile!(key, konstants)
      konstants = konstants.is_a?(Array) ? konstants : [konstants]
      profiler = Profiler.new(konstants)
      profiler.prepare_for_profiling

      MethodMeter.measure!(key) { yield }

      profiler.save_profiling_data
    end
  end
end
