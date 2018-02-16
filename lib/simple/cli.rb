module Simple; end
module Simple::CLI; end

require_relative "cli/helpers"
require_relative "cli/runner"
require_relative "cli/adapter"
require_relative "cli/logger"

require "pp"

module Simple::CLI
  DEBUG = true

  def self.included(base)
    base.extend(::Simple::CLI::Adapter)
    base.include(::Simple::CLI::Helpers)
  end

  extend ::Simple::CLI::Logger
  def logger
    Simple::CLI::Logger.logger
  end

  # Simple::CLI.run! is called from Runner.run. It is called with a method
  # name, which is derived from the command passed in via the command line,
  # and parsed arguments.
  #
  # The default implementation just calls the respective method on self.
  # Implementations might override this method to provide some before/after
  # functionality.
  def run!(command, *args)
    send(command, *args)
  end
end
