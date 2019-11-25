# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

module Simple; end
module Simple::CLI; end

require_relative "cli/default_options"
require_relative "cli/runner"
require_relative "cli/helper"
require_relative "cli/adapter"
require_relative "cli/logger"
require_relative "cli/on_exception"
require_relative "cli/helpers"

require "simple/service"

module Simple::CLI
  extend ::Simple::CLI::Logger

  # It is not strictly necessary to include this module into another module
  # (the "target module") to be able to run the target module via the command
  # line. It is sufficient to just include ::Simple::Service, which turns
  # the target into a service module, and then
  #
  # However, just including Simple::CLI gives you access to the Simple::CLI::Helpers
  # module as well.
  def self.included(base)
    base.include(::Simple::Service)
    base.include(::Simple::CLI::Helpers)
  end

  # Runs the service with the current command line arguments.
  #
  # The +service+ argument must match a simple-service service module. The CLI
  # application's subcommands and their arguments are derived from the actions
  # provided by the service module.
  def self.run!(service, args: nil)
    ::Simple::Service.verify_service!(service)

    # prepare arguments: we always duplicate the args array, to make guarantee
    # we don't interfere with the caller's view of the world.
    args ||= ARGV
    args = args.dup

    logger.level = ::Logger::DEBUG

    # Extract default options. This returns the command to run, the verbosity
    # setting, and the help flag.
    options = DefaultOptions.new(args)

    # Set logger verbosity. This happens before anything else - this way
    # any further step which raises an exception will have the correct log
    # level applied during exception handling.
    logger.level = options.log_level

    # Validate the command. If this command is invalid this will print a short
    # help message.
    if options.command
      unless H.action_for_command(service, options.command)
        logger.error "Invalid command '#{options.command}'."
        Helper.short_help!(service)
      end
    end

    # Run help if requested.
    if options.help?
      if options.command
        Helper.help_on_command! service, options.command, verbose: options.verbose?
      else
        Helper.help! service, verbose: options.verbose?
      end
    end

    # Run help if command is missing..
    unless options.command
      Helper.short_help! service
    end

    # Run service.
    Runner.run! service, options.command, *args, verbose: options.verbose?
  rescue ::Simple::Service::ArgumentError
    Helper.help_on_command! service, command, verbose: false
  rescue StandardError => e
    on_exception(e)
    exit 3
  end

  module H
    def self.action_for_command(service, command)
      actions = ::Simple::Service.actions(service)

      action_name = H.command_to_action(command)
      return nil unless actions.key?(action_name)
      actions[action_name]
    end

    def self.action_to_command(action_name)
      raise "action_name must by a Symbol" unless action_name.is_a?(Symbol)

      action_name.to_s.tr("_", ":")
    end

    def self.command_to_action(command)
      raise "command must by a String" unless command.is_a?(String)

      command.tr(":", "_").to_sym
    end

    def self.binary_name
      $0.gsub(/.*\//, "")
    end
  end
end
