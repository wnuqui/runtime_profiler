require 'active_support'

require 'runtime_profiler/profiler'

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

    def profile!(key, constants)
      constants = constants.is_a?(Array) ? constants : [constants]
      profiler = Profiler.new(constants)
      profiler.profile!(key) { yield }
    end
  end
end
