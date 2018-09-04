class Simple::CLI::Logger::Adapter
  def initialize(logger)
    @logger = logger
  end

  LOGGER_METHODS = [ :debug, :info, :warn, :error, :fatal, :level, :level= ]

  extend Forwardable
  delegate LOGGER_METHODS => :@logger

  def success(msg, *args, &block)
    if @logger.respond_to?(:success)
      @logger.send :success, msg, *args, &block
    else
      info "success: #{msg}", *args, &block
    end
  end

  def benchmark(msg, *args, &block)
    severity = :warn
    if msg.is_a?(Symbol)
      severity, msg = msg, args.shift
    end

    start = Time.now
    r = yield

    msg += ": #{(1000 * (Time.now - start)).to_i} msecs."
    send severity, msg, *args

    r
  rescue StandardError
    msg += "raises #{$!.class.name} after #{(1000 * (Time.now - start)).to_i} msecs."
    send severity, msg, *args
    raise $!
  end
end
