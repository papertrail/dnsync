require 'webrick'

module Dnsync
  class HttpStatus
    def initialize(port, updater)
      @port    = port
      @updater = updater
    end

    def start
      return if @server || @thread

      logger = WEBrick::Log.new
      logger.level = WEBrick::Log::WARN

      @server = WEBrick::HTTPServer.new(:Port => @port,
        :Logger => logger, :AccessLog => [])
      @server.mount_proc("/status", &method(:handler))

      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        @server.start
      end

      self
    end

    def stop
      if @server
        @server.stop
      end

      self
    end

    def join
      if @thread
        @thread.join
      end

      self
    end

    def handler(request, response)
      health_problems = @updater.health_problems

      if health_problems.blank?
        response.status = 200
        response.body   = "OK\n"
      else
        response.status = 500
        response.body = health_problems + "\n"
      end
    end
  end
end