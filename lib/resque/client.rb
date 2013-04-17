##
# Resque::Client is a wrapper around all things Redis.
#
# This provides a level of indirection so that the rest of our code
# doesn't need to know anything about Redis, and allows us to someday
# maybe even move away from Redis to another backend if we need to.
#
# Also helps because we can mock this out in our tests. Only mock
# stuff you own.
#
# Also, we can theoretically have multiple Redis/Resques going on
# one project.
module Resque
  class Client

    # This error is thrown if we have a problem connecting to
    # the back end.
    ConnectionError = Class.new(StandardError)

    attr_reader :backend, :logger

    def initialize(backend, logger)
      @backend = backend
      @logger = logger
    end
    
    # Reconnects to the backend
    #
    # Maybe your backend died, maybe you've just forked. Whatever the
    # reason, this method will attempt to reconnect to the backend.
    # 
    # If it can't connect, it will attempt to rety the connection after
    # sleeping, and after 3 failures will throw an exception.
    def reconnect
      tries = 0
      begin
        backend.client.reconnect
      rescue Redis::BaseConnectionError
        tries += 1

        if tries == 3
          logger.info "Error reconnecting to Redis; quitting"
          raise ConnectionError
        end

        logger.info "Error reconnecting to Redis; retrying"
        sleep(tries)
        retry
      end
    end
  end
end
