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
    @logger = Adapter.new(logger)
  end

  private

  def default_logger
    STDERR.isatty ? ColoredLogger : ::Logger.new(STDERR)
  end
end
