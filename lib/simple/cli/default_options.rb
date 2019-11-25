require "logger"

module Simple::CLI
  # A DefaultOptions object holds values for default options.
  class DefaultOptions
    # extract default CLI options and the  "help" command. Returns a DefaultOptions object
    def extract!(args:)
      new args
    end

    # verbosity (one of ::Logger::WARN, ::Logger::INFO, ::Logger::DEBUG)
    attr_reader :log_level

    # returns true if we run in verbose mode.
    def verbose?
      log_level == ::Logger::DEBUG
    end

    # command
    attr_reader :command

    # The help flag. Is set when
    #
    # - running the "help" command
    # - when a "-h" or "--help" CLI flag was given.
    def help?
      @help
    end

    private

    LOG_LEVEL_FLAGS = {
      "--verbose" => ::Logger::DEBUG,
      "-v" => ::Logger::DEBUG,
      "--quiet" => ::Logger::WARN,
      "-q" => ::Logger::WARN,
      default: ::Logger::INFO
    }

    HELP_FLAGS = {
      "--help" => true,
      "-h" => true,
      default: false
    }

    def initialize(args)
      @args = args

      @log_level = extract_w_lookup!(LOG_LEVEL_FLAGS)  # get -v/--verbose and -q7--quiet flags
      @command   = extract_command!                    # extract the command
      if @command == "help"
        @help = true
        @command = extract_command!
      else
        @help = extract_w_lookup!(HELP_FLAGS)          # extract --help flag
      end
    end

    def extract_w_lookup!(hsh)
      value = hsh[:default]
      @args.reject! do |str|
        next unless hsh.key?(str)
        value = hsh[str]
      end
      value
    end

    def extract_command!
      return nil if /^-/ =~ @args.first
      @args.shift
    end
  end
end
