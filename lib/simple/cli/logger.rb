require "logger"

module Simple::CLI::Logger
  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger ||= build_default_logger
  end

  private

  def build_default_logger
    logger = Logger.new(STDOUT)
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{severity}: #{msg}\n"
    end
    logger.level = Logger::INFO
    logger
  end
end
