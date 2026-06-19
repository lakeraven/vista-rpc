# frozen_string_literal: true

module VistaRpc
  VERSION = "0.1.0"

  class NotConfiguredError < StandardError; end

  class Configuration
    attr_accessor :client, :unsafe_raw_errors

    def initialize
      @client = nil
      @unsafe_raw_errors = false
    end
  end

  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def client
      configuration.client || raise(
        NotConfiguredError,
        "VistaRpc.client is not configured. Call VistaRpc.configure { |c| c.client = ... }."
      )
    end

    def reset!
      @configuration = Configuration.new
    end
  end
end
