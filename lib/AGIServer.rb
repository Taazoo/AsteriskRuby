#AGIServer is a threaded server framework that is intended to be used to communicate with an Asterisk PBX via the Asterisk Gateway Interface, an interface for adding functionality to asterisk. This class implements a server object which will listen on a tcp host:port and accept connections, setup an AGI object, and either yield to a supplied block, which itself defines callflow, or route to public methods of the AGIRoute objects.
require 'socket'
require 'thread'
require 'logger'
require 'AGI.rb'
require 'AGIExceptions'
require 'AGIRouter'

#AGIServer is a threaded server framework that is intended to be used to communicate with an Asterisk PBX via the Asterisk Gateway Interface, an interface for adding functionality to asterisk. This class implements a server object which will listen on a tcp host:port and accept connections, setup an AGI object, and either yield to a supplied block, which itself defines callflow, or route to public methods of the AGIRoute objects.
class AGIServer
  #A list of all current AGIServers
  @@servers = []
  #Binding Parameters supplied during initialization.
  attr_reader :bind_host, :bind_port
  #Creates an AGIServer Object based on the provided Parameter Hash, and binds to the appropriate host/port. Will also set signal handlers that will shut down all AGIServer's upon receipt of SIGINT or SIGTERM.
  #* :bind_host sets the hostname or ip address to bind to. Defaults to localhost.
  #* :bind_port sets the port to bind to. Defaults to 4573.
  #* :max_workers sets the maximum number of worker threads to allow for connection processing. Defaults to 10
  #* :min_workers sets the minimum number of worker threads to maintain for connection processing. Defaults to 5
  #* :jobs_per_worker sets the number of connections each worker will handle before exiting. Defaults to 50
  #* :logger sets the Logger object to use for logging. Defaults to Logger.new(STDERR).
  #* :params can be any object you wish to be made available to all workers; I suggest a hash of objects.
  def initialize(params={})
    #Options
    @bind_host        = params[:bind_host]        || 'localhost'
    @bind_port        = params[:bind_port]        || 4573
    @max_workers      = params[:max_workers]      || 10
    @min_workers      = params[:min_workers]      || 5
    @jobs_per_worker  = params[:jobs_per_worker]  || 50
    @logger           = params[:logger]           || Logger.new(STDERR)
    @stats            = params[:stats]            || false
    @params           = params[:params]           || Hash.new

    #Threads
    @listener         = nil
    @monitor          = nil
    @workers          = []

    #Synchronization
    @worker_queue     = Queue.new
    @shutdown         = false

    #Initial Bind
    begin
      @listen_socket  = TCPServer.new(@bind_host, @bind_port)
    rescue Errno::EADDRINUSE
      @logger.fatal("AGIServer cannot bind to #{@bind_host}:#{@bind_port}, Address already in use.")
      raise
    end

    #Track for signal handling
    @@servers << self
    AGIRouter.logger(@logger)

    trap('INT')   { shutdown }
    trap('TERM')  { shutdown }
  end
  #call-seq:
  # run()
  #1. Listener Thread: The Listener Thread is the simplest of the Threads. It accepts client sockets from the main socket, and enqueues those client sockets into the worker_queue.
  #2. Worker Threads: The Worker Thread is also fairly simple. It loops jobs_per_worker times, and each time, dequeues from the worker_queue. If the result is nil, it exits, otherwise, it interacts with the client socket, either yielding to the aforementioned supplied block or routing to the AGIRoutes. If a Worker Thread is instantiated, it will continue to process requests until it processes jobs_per_worker jobs or the server is stopped.
  #3. Monitor Thread: The Monitor Thread is the most complex of the threads at use. It instantiates Worker Threads if at any time it detects that there are fewer workers than min_workers, and if at any time it detects that the worker_queue length is greater than zero while there are fewer than max_workers.
  def run(&block)
    @logger.info "Initializing Monitor Thread"

    @monitor = Thread.new do

      poll = 0
      while ! @shutdown do
        poll += 1

        if @worker_queue.length.zero?
          sleep(1)
          next
        end

        worker_check = (@workers.length < @max_workers)
        if worker_check || @workers.length < @min_workers
          @logger.info "Starting worker thread to handle requests"

          #Begin Worker Thread
          @client = @worker_queue.deq
          if @client
            worker = AGIWorker.new({
              :client => @client,
              :params => @params,
              :logger => @logger
            })

              @workers.delete_if do |pid|
                pid >= Process.pid
              end
            })

            @workers << worker_pid
          end


          next #Short Circuit back without a sleep in case we need more threads for load
        end
        if @stats && (poll % 10).zero?
          @logger.debug "#{@workers.length} active workers, #{@worker_queue.length} jobs waiting"
        end
        sleep 1
      end

      @logger.debug{"Signaling all Worker Threads to finish up and exit"}
      @workers.length.times{ @worker_queue.enq(nil) }
      @workers.each { |worker| worker.join }
      @logger.debug{"Final Worker Thread closed"}
    end

    @logger.info{"AGIServer Initializing Listener Thread"}
    @listener = Thread.new do
      begin
        while( client = @listen_socket.accept )
          @logger.debug("Listener received Connection Request")
          @worker_queue.enq(client)
        end
      rescue IOError
        # Occurs on socket shutdown.
      end
    end
  end
  alias_method :start, :run

  #Will  wait for the Monitor and Listener threads to join. The Monitor thread itself will wait for all of it's instantiated Worker threads to join.
  def join
    @listener.join && @logger.debug("Listener Thread closed")
    @monitor.join  && @logger.debug("AGIServer Monitor Thread closed")
  end
  alias_method :finish, :join

  #Closes the listener socket, so that no new requests will be accepted. Signals to the Monitor thread to shutdown it's Workers when they're done with their current clients.
  def shutdown
    @logger.info("Shutting down gracefully")
    @listen_socket.close && @logger.info("AGIServer No longer accepting connections")
    @shutdown = true && @logger.info("AGIServer Signaling Monitor to close after active sessions complete")

    @workers.each do |worker|
      Process.kill("HUP", pid)
    end

    rescue => e
      Process.exit!
  end
  alias_method :stop, :shutdown

  #Calls shutdown on all AGIServer objects.
  def AGIServer.shutdown
    @@servers.each { |server| server.shutdown }
  end

end

=begin
  Copyright (c) 2007, Vonage Holdings

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
        * Neither the name of Vonage Holdings nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
=end