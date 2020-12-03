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

        c.option '--sort-by COLUMN',        String,   'Sort by COLUMN. COLUMN can either be "total_calls" or "total_runtime". Default is "total_calls".'
        c.option '--details TYPE',          String,   'TYPE can be "full" or "summary". Default is "summary"'
        c.option '--runtime-above RUNTIME', Float,    'RUNTIME is integer or float value in ms.'
        c.option '--only-sqls',             String,   'Show only SQL(s).'
        c.option '--only-methods',          String,   'Show only method(s).'
        c.option '--calls-above CALLS',     Integer,  'CALLS is integer value.'

        c.action do |args, options|
          default_options = {
            sort_by: 'total_runtime',
            details: 'summary',
            runtime_above: 0,
            only_sqls: false,
            only_methods: false,
            calls_above: 0
          }

          options.default default_options

          if args.first.nil?
            say 'You need to supply <profile.report.json> as first argument of view.'
          else
            report = RuntimeProfiler::TextReport.new(args.first, options)
            report.print
          end
        end
      end

      run!
    end
  end
end