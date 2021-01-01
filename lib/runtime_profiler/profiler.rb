# require 'method_profiler'

require 'runtime_profiler/callbacks/active_record'
require 'runtime_profiler/callbacks/action_controller'
require 'runtime_profiler/instrumentation_data'

module RuntimeProfiler
  class Profiler
    attr_accessor :instrumented_constants

    def initialize(konstants)
      self.instrumented_constants = konstants
    end

    def prepare_for_instrumentation
      subscribe_to_event_notifications
      prepare_methods_to_instrument
    end

    def subscribe_to_event_notifications
      @subscribers = []

      @active_record_callback = Callback::ActiveRecord.new

      @subscribers << ActiveSupport::Notifications
                      .subscribe('sql.active_record', @active_record_callback)

      @action_controller_callback = Callback::ActionController.new

      @subscribers << ActiveSupport::Notifications
                      .subscribe('process_action.action_controller', @action_controller_callback)
    end

    def unsubscribe_to_event_notifications
      @subscribers.each do |subscriber|
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end
    end

    def prepare_methods_to_instrument
      instrumented_constants.flatten
                            .each { |constant| MethodMeter.observe(constant, RuntimeProfiler.excepted_methods) }
    end

    def save_instrumentation_data
      unsubscribe_to_event_notifications

      instrumentation_data = RuntimeProfiler::InstrumentationData.new \
        controller_data: @action_controller_callback.controller_data,
        sql_data: @active_record_callback.data

      instrumentation_data.persist!
    end
  end
end
