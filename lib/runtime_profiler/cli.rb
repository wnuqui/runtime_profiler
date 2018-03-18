require 'commander'
require 'json'

require_relative 'text_report'

module RuntimeProfiler
  class CLI
    include Commander::Methods

    def run
      program :name, 'runtime_profiler'
      program :version, '0.1.0'
      program :description, 'Display report in console given the JSON report file.'

      command :view do |c|
        c.syntax = 'runtime_profiler view <profile.report.json> [options]'
        c.description = 'Display report in console given the JSON report file'

        c.option '--sort-by COLUMN',        String, 'Sort by COLUMN. COLUMN can either be "total_calls" or "total_runtime". Default is "total_calls".'
        c.option '--details TYPE',          String, 'TYPE can be "full" or "summary".'
        c.option '--runtime-above RUNTIME', String, 'RUNTIME is numeric value in ms.'
        c.option '--only-sqls',             String, 'Show only SQL(s).'
        c.option '--only-methods',          String, 'Show only method(s).'
        c.option '--calls-above CALLS',     String, 'CALLS is numeric value.'

        c.action do |args, options|
          default_options = {
            sort_by: 'total_calls',
            details: 'summary',
            runtime_above: 0,
            only_sqls: false,
            only_methods: false,
            calls_above: 1
          }

          options.default default_options

          report = RuntimeProfiler::TextReport.new(args.first, options)

          report.print
        end
      end

      run!
    end
  end
end