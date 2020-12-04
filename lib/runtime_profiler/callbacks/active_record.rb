require 'runtime_profiler/events/sql_event'

module RuntimeProfiler
  module Callback
    class ActiveRecord
      attr_reader :data

      def initialize
        @data = {}
      end

      def call(*args)
        event = RuntimeProfiler::SqlEvent.new(args: args, trace: caller)

        return unless event.recordable?
        return if event.trace.empty?

        @data.key?(event.key) ? update(event) : add(event)
      end

      private

      def add(event)
        key = event.key
        @data[key] = {}

        @data[key][:sql]      = event.sanitized_sql
        @data[key][:runtimes] = [
          [event.total_runtime, event.trace.first]
        ]
      end

      def update(event)
        @data[event.key][:runtimes] << [event.total_runtime, event.trace.first]
      end
    end
  end
end
