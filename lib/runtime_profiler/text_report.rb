require 'hirb'
require 'terminal-table'
require 'active_support/core_ext/string'
require 'pry'

module RuntimeProfiler
  class TextReport
    COUNT_WIDTH         = 5
    DURATION_WIDTH      = 22
    TOTAL_RUNTIME_WIDTH = 20

    FULL_DETAILS_TEMPLATE = <<-EOT.strip_heredoc

        \e[1mPROFILING REPORT\e[22m
        ----------------

        \e[1mAPI RUNTIME\e[22m
          Total Runtime     : %s ms
          Database Runtime  : %s ms
          View Runtime      : %s ms

        \e[1mMETHOD CALLS\e[22m
          SLOWEST           : %s (%s ms)
          MOSTLY CALLED     : %s (%s number of calls in %s ms)

        \e[1mSQL CALLS\e[22m
          Total             : %s
          Total Unique      : %s

          \e[1mSLOWEST\e[22m
            Total Runtime   : %s ms
            SQL             : %s
            Source          : %s

          \e[1mMOSTLY CALLED\e[22m
            Total Calls     : %s
            Total Runtime   : %s ms
            SQL             : %s
            Sources         : %s

      EOT

    METHODS_DETAILS_TEMPLATE = <<-EOT.strip_heredoc

        \e[1mPROFILING REPORT\e[22m
        ----------------

        \e[1mAPI RUNTIME\e[22m
          Total Runtime     : %s ms
          Database Runtime  : %s ms
          View Runtime      : %s ms

        \e[1mMETHOD CALLS\e[22m
          SLOWEST           : %s (%s ms)
          MOSTLY CALLED     : %s (%s number of calls in %s ms)

      EOT

    SQLS_DETAILS_TEMPLATE = <<-EOT.strip_heredoc

        \e[1mPROFILING REPORT\e[22m
        ----------------

        \e[1mAPI RUNTIME\e[22m
          Total Runtime     : %s ms
          Database Runtime  : %s ms
          View Runtime      : %s ms

        \e[1mSQL CALLS\e[22m
          Total             : %s
          Total Unique      : %s

          \e[1mSLOWEST\e[22m
            Total Runtime   : %s ms
            SQL             : %s
            Source          : %s

          \e[1mMOSTLY CALLED\e[22m
            Total Calls     : %s
            Total Runtime   : %s ms
            SQL             : %s
            Sources         : %s

      EOT

    attr_accessor :data, :options

    def initialize(json_file, options)
      self.data = JSON.parse(File.read(json_file))
      self.options = options
    end

    def print
      print_summary

      if options.details == 'full'
        if only_methods?
          print_instrumented_methods
        elsif only_sqls?
          print_instrumented_sql_calls
        else
          print_instrumented_methods
          print_instrumented_sql_calls
        end
      end
    end

    private

    def only_methods?
      options.only_methods.present? && options.only_sqls.blank?
    end

    def only_sqls?
      options.only_sqls.present? && options.only_methods.blank?
    end

    def rounding
      options.rounding
    end

    def print_summary
      summary = if only_methods?
                  METHODS_DETAILS_TEMPLATE % details_template_data
                elsif only_sqls?
                  SQLS_DETAILS_TEMPLATE % details_template_data
                else
                  FULL_DETAILS_TEMPLATE % details_template_data
                end
      puts summary
    end

    def print_instrumented_methods
      instrumented_methods = []

      data['instrumentation']['instrumented_methods'].each do |profiled_object_name, methods|
        _instrumented_methods = methods.map do |method|
          method['method'] = [profiled_object_name, method['method']].join
          method
        end
        instrumented_methods.concat(_instrumented_methods)
      end

      instrumented_methods = runtime_above(instrumented_methods) if options.runtime_above.presence > 0
      instrumented_methods = calls_above(instrumented_methods) if options.calls_above.presence > 0
      instrumented_methods = sort(instrumented_methods)

      table = Terminal::Table.new do |t|
        t.headings = ['Method', 'Total Runtime (ms)', 'Total Calls', 'Min (ms)', 'Max (ms)']

        instrumented_methods.each_with_index do |row, index|
          t.add_row [
            row['method'],
            row['total_runtime'].round(rounding),
            row['total_calls'],
            row['min'].round(rounding),
            row['max'].round(rounding)
          ]
          t.add_separator if index < instrumented_methods.size - 1
        end
      end

      puts
      puts
      puts "\e[1mINSTRUMENTED METHOD(s)\e[22m"
      puts
      puts table
    end

    def print_instrumented_sql_calls
      instrumented_sql_calls = data['instrumentation']['instrumented_sql_calls']

      instrumented_sql_calls = runtime_above(instrumented_sql_calls) if options.runtime_above.presence > 0
      instrumented_sql_calls = calls_above(instrumented_sql_calls) if options.calls_above.presence > 0
      instrumented_sql_calls = sort(instrumented_sql_calls, false)

      table = Terminal::Table.new do |t|
        t.headings = ['SQL Query', 'Count', 'Total Runtime (ms)', 'Average Runtime (ms)', 'Source']

        instrumented_sql_calls.each_with_index do |row, index|
          chopped_sql       = wrap_text(row['sql'], sql_width)
          source_list       = wrap_list(row['runtimes'].map { |runtime| runtime[1] }.uniq, sql_width - 15)
          average_runtime   = row['average'].round(rounding)
          total_runtime     = row['total_runtime'].round(rounding)
          total_lines       = if chopped_sql.length >= source_list.length
                                chopped_sql.length
                              else
                                source_list.length
                              end

          (0...total_lines).each do |line|
            count         = line == 0                 ? row['total_calls']    : ''
            average       = line == 0                 ? average_runtime       : ''
            total_runtime = line == 0                 ? total_runtime : ''
            source        = source_list.length > line ? source_list[line]     : ''
            query         = row['sql'].length > line  ? chopped_sql[line]     : ''

            t.add_row []
            t.add_row [query, count, total_runtime, average, source]
          end

          t.add_row []
          t.add_separator if index < instrumented_sql_calls.size - 1
        end
      end

      puts
      puts
      puts "\e[1mINSTRUMENTED SQL(s)\e[22m"
      puts
      puts table
    end

    def wrap_text(text, width)
      return [text] if text.length <= width

      text.scan(/.{1,#{width}}/)
    end

    def wrap_list(list, width)
      list.map do |text|
        wrap_text(text, width)
      end.flatten
    end

    def sql_width
      @sql_width ||= begin
        terminal_width = Hirb::Util.detect_terminal_size.first
        (terminal_width - COUNT_WIDTH - DURATION_WIDTH - TOTAL_RUNTIME_WIDTH) / 2
      end
    end

    def sort(data, methods = true)
      if methods
        data.sort_by do |d|
          if options.sort_by == 'max_runtime'
            -d['max']
          elsif options.sort_by == 'total_runtime'
            -d['total_runtime']
          elsif options.sort_by == 'total_calls'
            -d['total_calls']
          end
        end
      else
        options.sort_by = 'total_runtime' if options.sort_by == 'max_runtime'
        data.sort_by { |d| options.sort_by == 'total_runtime' ? -d['total_runtime'] : -d['total_calls'] }
      end
    end

    def runtime_above(data)
      data.select { |d| d['total_runtime'] > options.runtime_above }
    end

    def calls_above(data)
      data.select { |d| d['total_calls'] > options.calls_above }
    end

    def details_template_data
      summary = data['instrumentation']['summary']

      template_data = [
        summary['total_runtime'] ? summary['total_runtime'].round(rounding) : 'n/a',
        summary['db_runtime'] ? summary['db_runtime'].round(rounding) : 'n/a',
        summary['view_runtime'] ? summary['view_runtime'].round(rounding) : 'n/a'
      ]

      methods_data = [
        summary['slowest_method']['method'],
        summary['slowest_method']['total_runtime'].round(rounding),

        summary['mostly_called_method']['method'],
        summary['mostly_called_method']['total_calls'],
        summary['mostly_called_method']['total_runtime'].round(rounding)
      ]

      sqls_data = [
        summary['total_sql_calls'],
        summary['total_unique_sql_calls'],

        summary['slowest_sql']['total_runtime'].round(rounding),
        summary['slowest_sql']['sql'],
        summary['slowest_sql']['source'],

        summary['mostly_called_sql']['total_calls'],
        summary['mostly_called_sql']['total_runtime'].round(rounding),
        summary['mostly_called_sql']['sql'],
        summary['mostly_called_sql']['runtimes'].map { |runtime| runtime[1] }.uniq
      ]

      if only_methods?
        template_data.concat(methods_data)
      elsif only_sqls?
        template_data.concat(sqls_data)
      else
        template_data
          .concat(methods_data)
          .concat(sqls_data)
      end
    end
  end
end
