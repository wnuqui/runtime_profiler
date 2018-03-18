require 'hirb'
require 'terminal-table'
require 'active_support/core_ext/string'

module RuntimeProfiler
  class TextReport
    COUNT_WIDTH         = 5
    DURATION_WIDTH      = 22
    TOTAL_RUNTIME_WIDTH = 20

    SUMMARY_TEMPLATE = <<-EOT.strip_heredoc

        \e[1mPROFILING REPORT\e[22m
        ----------------

        \e[1mRUNTIME\e[22m
          Total Runtime     : %s ms
          Database Runtime  : %s ms
          View Runtime      : %s ms

        \e[1mMETHODS\e[22m
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

    attr_accessor :data, :options

    def initialize(json_file, options)
      self.data = JSON.parse( File.read(json_file) )
      self.options  = options
    end

    def print
      print_summary

      if self.options.details == 'full'
        print_instrumented_methods
        print_instrumented_sql_calls
      end
    end

    private

    def print_summary
      summary = SUMMARY_TEMPLATE % summary_template_data
      puts summary
    end

    def print_instrumented_methods
      instrumented_methods = []

      self.data['instrumentation']['instrumented_methods'].each do |profiled_object_name, methods|
        instrumented_methods.concat methods.map { |method| method['method'] = [profiled_object_name, method['method']].join; method}
      end

      instrumented_methods = sort(instrumented_methods)

      table = Terminal::Table.new do |t|
        t.headings = ['Method', 'Total Runtime (ms)', 'Total Calls', 'Min', 'Max']

        instrumented_methods.each_with_index do |row, index|
          t.add_row [
            row['method'],
            row['total_runtime'],
            row['total_calls'],
            row['min'],
            row['max']
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
      instrumented_sql_calls = sort(self.data['instrumentation']['instrumented_sql_calls'])

      table = Terminal::Table.new do |t|
        t.headings = ['Count', 'Total Runtime (ms)', 'Average Runtime (ms)', 'SQL Query', 'Source']

        instrumented_sql_calls.each_with_index do |row, index|
          chopped_sql       = wrap_text(row['sql'], sql_width)
          source_list       = wrap_list(row['runtimes'].map { |runtime| runtime[1] }.uniq, sql_width - 15)
          average_runtime   = row['average'].round(2)
          total_lines       = if chopped_sql.length >= source_list.length
                                chopped_sql.length
                              else
                                source_list.length
                              end

          (0...total_lines).each do |line|
            count         = line == 0                 ? row['total_calls']    : ''
            average       = line == 0                 ? average_runtime       : ''
            total_runtime = line == 0                 ? row['total_runtime']  : ''
            source        = source_list.length > line ? source_list[line]     : ''
            query         = row['sql'].length > line  ? chopped_sql[line]     : ''

            t.add_row []
            t.add_row [count, total_runtime, average, query, source]
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

    def sort(data)
      data.sort_by do |d|
        if self.options.sort_by == 'total_runtime'
          -d['total_runtime']
        else
          -d['total_calls']
        end
      end
    end

    def summary_template_data
      summary = self.data['instrumentation']['summary']

      [
        summary['total_runtime'].round(2),
        summary['db_runtime'].round(2),
        summary['view_runtime'].round(2),

        summary['slowest_method']['method'],
        summary['slowest_method']['total_runtime'].round(2),

        summary['mostly_called_method']['method'],
        summary['mostly_called_method']['total_calls'],
        summary['mostly_called_method']['total_runtime'].round(2),

        summary['total_sql_calls'],
        summary['total_unique_sql_calls'],

        summary['slowest_sql']['total_runtime'].round(2),
        summary['slowest_sql']['sql'],
        summary['slowest_sql']['source'],

        summary['mostly_called_sql']['total_calls'],
        summary['mostly_called_sql']['total_runtime'].round(2),
        summary['mostly_called_sql']['sql'],
        summary['mostly_called_sql']['runtimes'].map { |runtime| runtime[1] }.uniq
      ]
    end
  end
end
