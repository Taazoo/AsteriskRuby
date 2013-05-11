class AGIWorker

  def initialize(opts)
    @client = opts[:client]
    @logger = opts[:logger]
    @agi    = opts[:agi]
  end


  def run
    $0 = "#{$0} Worker"

    return if @client.blank?

    @logger.debug "Worker received Connection"
    @agi = AGI.new({
      :input  => @client,
      :output => @client,
      :logger => @logger
    })

    begin
      @agi.init
      router = AGIRouter.new(@agi.channel_params['request'])
      router.route(@agi, @params)
    rescue AGIHangupError => error
      @logger.error "Worker caught unhandled hangup: #{error}"
      @agi.hangup
    rescue AGIError,Exception => error
      @logger.error "Caught unhandled exception: #{error.class} #{error}"
      @logger.error error.backtrace.join("\n")
      @agi.hangup
    ensure
      @client.close
      @logger.debug "Worker done with Connection"
    end
    @logger.info "Worker handled last Connection, terminating"
  end
end