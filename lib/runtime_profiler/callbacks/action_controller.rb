require 'runtime_profiler/events/process_action_event'

module RuntimeProfiler
  module Callback
    class ActionController
      attr_reader :data

      def initialize
        @data = {}
      end

      def call(*args)
        event = RuntimeProfiler::ProcessActionEvent.new(args: args)
        return unless event.recordable?
        add event
      end

      def controller_data
        data.values.first
      end

      private

      def add(event)
        key = event.key
        @data[key] = {}

        @data[key][:path]           = event.path
        @data[key][:total_runtime]  = event.total_runtime
        @data[key][:db_runtime]     = event.db_runtime
        @data[key][:view_runtime]   = event.view_runtime
        @data[key][:payload]        = event.payload
      end
    end
  end
end
