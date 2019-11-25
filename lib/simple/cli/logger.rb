module Simple::CLI::Logger
end

require "logger"

require_relative "logger/adapter"
require_relative "logger/colored_logger"

module Simple::CLI::Logger
  def logger
    @logger ||= Adapter.new(default_logger)
  end

  def logger=(logger)
    old_log_level = logger.level
    @logger = Adapter.new(logger)
    @logger.level = old_log_level
  end

  private

  def default_logger
    logger = STDERR.isatty ? ColoredLogger : ::Logger.new(STDERR)
    logger.level = ::Logger::INFO
    logger
  end
end
