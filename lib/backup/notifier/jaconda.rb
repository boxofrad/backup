# encoding: utf-8
require 'jaconda'

module Backup
  module Notifier
    class Jaconda < Base

      ##
      # The jaconda.im subdomain
      attr_accessor :subdomain

      ##
      # The room id
      attr_accessor :room_id

      ##
      # The room token
      attr_accessor :room_token

      ##
      # Who the message should appear from
      attr_accessor :sender_name

      def initialize(model, &block)
        super(model)
        instance_eval(&block) if block_given?
      end

      private

      ##
      # Notify the user of the backup operation results.
      # `status` indicates one of the following:
      #
      # `:success`
      # : The backup completed successfully.
      # : Notification will be sent if `on_success` was set to `true`
      #
      # `:warning`
      # : The backup completed successfully, but warnings were logged
      # : Notification will be sent, including a copy of the current
      # : backup log, if `on_warning` was set to `true`
      #
      # `:failure`
      # : The backup operation failed.
      # : Notification will be sent, including the Exception which caused
      # : the failure, the Exception's backtrace, a copy of the current
      # : backup log and other information if `on_failure` was set to `true`
      #
      def notify!(status)
        send_message "[Backup::%s] #{@model.label} (#{@model.trigger})" % status.to_s.capitalize
      end

      def send_message(message)
        ::Jaconda::Notification.authenticate({
          :subdomain  => subdomain,
          :room_id    => room_id,
          :room_token => room_token
        })

        ::Jaconda::Notification.notify({
          :text        => message,
          :sender_name => sender_name
        })
      end

    end
  end
end
