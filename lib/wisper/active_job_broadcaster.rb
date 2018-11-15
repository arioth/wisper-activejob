require 'wisper'
require 'wisper/active_job/version'
require 'active_job'

module Wisper
  class ActiveJobBroadcaster
    attr_reader :options

    class << self
      def broadcast_with(job_class)
        @job_class = job_class
      end

      def job_class
        @job_class || Wrapper
      end
    end

    def initialize(options = {})
      @options = options == true ? {} : options
    end

    def broadcast(subscriber, publisher, event, args)
      self.class.job_class.set(options).perform_later(subscriber.name, event, args)
    end

    class Wrapper < ::ActiveJob::Base
      queue_as :default

      def perform(class_name, event, args)
        listener = class_name.constantize
        listener.public_send(event, *args)
      end
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :active_job, Proc.new { |options| ActiveJobBroadcaster.new(options) }
        config.broadcaster :async,      Proc.new { |options| ActiveJobBroadcaster.new(options) }
      end
    end
  end
end

Wisper::ActiveJobBroadcaster.register
