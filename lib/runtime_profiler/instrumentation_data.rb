module RuntimeProfiler
  class InstrumentationData
    attr_reader :controller_data, :sql_data

    def initialize(controller_data: nil, sql_data: nil)
      @controller_data = controller_data || {}
      @sql_data = sql_data
    end

    def persist!
      File.open(output_file, 'w') do |f|
        f.write JSON.dump(instrumentation_data)
      end

      puts "\n"
      puts 'Profiling data written at ' + output_file.to_s
      puts 'You can view profiling data via: bundle exec runtime_profiler view ' + output_file.to_s
      puts "\n"
    end

    private

    def output_file
      FileUtils.mkdir_p(RuntimeProfiler.output_path)
      filename = ['rp', Process.pid, Time.now.to_i].join('-') + '.json'
      File.join(RuntimeProfiler.output_path, filename)
    end

    def instrumented_api
      return unless controller_data[:payload]
      @instrumented_api ||= [
        controller_data[:payload][:controller],
        controller_data[:payload][:action]
      ].join('#')
    end

    def instrumentation_data
      @instrumentation_data ||= {
        instrumentation: {
          instrumented_api: instrumented_api,
          summary: {
                        db_runtime: controller_data[:db_runtime],
                      view_runtime: controller_data[:view_runtime],
                     total_runtime: controller_data[:total_runtime],
                       slowest_sql: sql_calls_data[:slowest_sql],
                 mostly_called_sql: sql_calls_data[:mostly_called_sql],
                   total_sql_calls: sql_calls_data[:total_sql_calls],
            total_unique_sql_calls: sql_calls_data[:total_unique_sql_calls],
                    slowest_method: method_calls_data[:slowest_method],
              mostly_called_method: method_calls_data[:mostly_called_method]
          },
          instrumented_sql_calls: sql_calls_data[:instrumented_sql_calls],
          instrumented_methods: method_calls_data[:instrumented_methods],
          instrumented_at: Time.now
        }
      }
    end

    def method_calls_data
      @method_calls_data ||= begin
        instrumented_methods = {}

        # TODO: Group methods under a key and under an object
        MethodMeter.measurement.each do |measurement|
          measurement.each_pair do |key, data|
            data.each do |d|
              object = d[:method].split(separator = '.')
              object = d[:method].split(separator = '#') if object.length == 1

              d[:method] = separator + object.second

              if instrumented_methods[object.first]
                instrumented_methods[object.first] << d
              else
                instrumented_methods[object.first] = [d]
              end
            end
          end
        end

        instrumented_methods = instrumented_methods.inject({}) do |hash, (key, value)|
          val = value.sort { |a, b| b[:total_runtime] <=> a[:total_runtime] }
          hash[key] = val
          hash
        end

        slowest_method = {total_runtime: 0}
        mostly_called_method = {total_calls: 0}

        instrumented_methods.each do |profiled_object_name, methods|
          # sort using `total_runtime` in DESC order
          _methods = methods.sort { |a, b| b[:total_runtime] <=> a[:total_runtime] }
          slowest = _methods[0]

          if slowest[:total_runtime] > slowest_method[:total_runtime]
            slowest_method[:method]         = [profiled_object_name, slowest[:method]].join
            slowest_method[:total_runtime]  = slowest[:total_runtime]
          end

          # sort using `total_calls` in DESC order and GET first item
          mostly_called = methods.sort { |a, b| b[:total_calls] <=> a[:total_calls] } [0]

          if mostly_called[:total_calls] > mostly_called_method[:total_calls]
            mostly_called_method[:method]         = [profiled_object_name, mostly_called[:method]].join
            mostly_called_method[:total_runtime]  = mostly_called[:total_runtime]
            mostly_called_method[:total_calls]    = mostly_called[:total_calls]
            mostly_called_method[:min]            = mostly_called[:min]
            mostly_called_method[:max]            = mostly_called[:max]
          end
        end

        {
          instrumented_methods: instrumented_methods,
                slowest_method: slowest_method,
          mostly_called_method: mostly_called_method
        }
      end
    end

    def sql_calls_data
      @sql_calls_data ||= begin
        instrumented_sql_calls = []

        slowest_sql = {total_runtime: 0}
        mostly_called_sql = {total_calls: 0}

        sql_data.values.each do |value|
          total_calls   = value[:runtimes].size
          total_runtime = value[:runtimes].map { |runtime| runtime[0] }.reduce(:+)
          average       = total_runtime / total_calls

          # sort using `runtimes` in DESC order
          runtimes = value[:runtimes].sort { |a, b| b[0] <=> a[0] }
          slowest = runtimes[0]
          fastest = runtimes[runtimes.size - 1]

          if slowest[0] > slowest_sql[:total_runtime]
            slowest_sql[:sql]           = value[:sql]
            slowest_sql[:total_runtime] = slowest[0]
            slowest_sql[:source]        = slowest[1]
          end

          instrumented_sql_calls << {
                      sql: value[:sql],
                 runtimes: runtimes,
              total_calls: total_calls,
            total_runtime: total_runtime,
                  average: average,
                      min: fastest[0],
                      max: slowest[0]
          }

          if total_calls > mostly_called_sql[:total_calls]
            mostly_called_sql[:sql]           = value[:sql]
            mostly_called_sql[:runtimes]      = value[:runtimes]
            mostly_called_sql[:total_calls]   = total_calls
            mostly_called_sql[:total_runtime] = total_runtime
            mostly_called_sql[:average]       = average
            mostly_called_sql[:min]           = fastest[0]
            mostly_called_sql[:max]           = slowest[0]
          end
        end

        {
          instrumented_sql_calls: instrumented_sql_calls.sort { |a, b| b[:max] <=> a[:max] },
                 total_sql_calls: instrumented_sql_calls.map { |sql_call| sql_call[:total_calls] }.reduce(:+),
          total_unique_sql_calls: instrumented_sql_calls.size,
                     slowest_sql: slowest_sql,
               mostly_called_sql: mostly_called_sql
        }
      end
    end
  end
end