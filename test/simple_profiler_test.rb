require 'test_helper'

class RuntimeProfilerTest < Minitest::Test
  def test_configure_should_set_configs
    profiled_paths = %w[app/model]
    profiled_sql_commands = %w[SELECT]
    output_path = '/usr/local/test'

    RuntimeProfiler.configure do |config|
      config.profiled_paths = %w[app/model]
      config.profiled_sql_commands = %w[SELECT]
      config.output_path = '/usr/local/test'
    end

    assert_equal(%w[app/model], profiled_paths)
    assert_equal(%w[SELECT], profiled_sql_commands)
    assert_equal('/usr/local/test', output_path)
  end
end
