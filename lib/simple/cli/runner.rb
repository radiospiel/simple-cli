# rubocop:disable  Metrics/AbcSize
# rubocop:disable  Metrics/ClassLength
# rubocop:disable  Metrics/MethodLength

class Simple::CLI::Runner
end

require_relative "runner/command_help"

# A Runner object manages running a CLI application module with a set
# of string arguments (usually taken from ARGV)
class Simple::CLI::Runner
  def self.run(app, *args)
    new(app).run(*args)
  end

  def initialize(app)
    @app = app
  end

  def extract_default_flags!(args)
    args.reject! do |arg|
      case arg
      when "--verbose", "-v" then logger.level = Logger::DEBUG
      when "--quiet", "-q"   then logger.level = Logger::WARN
      end
    end
  end

  attr_accessor :subcommand

  def help(command)
    if command
      run "help", command
    else
      run "help"
    end
  end

  def run(*args)
    extract_default_flags!(args)

    @instance = Object.new.extend(@app)
    command_name = args.shift || help!
    command = string_to_command(command_name)

    if command == :help
      do_help!(*args)
    elsif commands.include?(command)
      self.subcommand = command
      @instance.run! command, *args_with_options(args)
    else
      msg = command ? "Invalid subcommand #{command.to_s.inspect}" : "Missing subcommand"
      STDERR.puts "#{msg}\n\n"
      help_short!
    end
  rescue StandardError => e
    on_exception(e)
  end

  def subcommands?
    commands.length > 1
  end

  def do_help!(subcommand = nil)
    if !subcommand
      help!
    else
      help_subcommand!(subcommand)
    end
  end

  def short_help!(subcommand)
    unless subcommand
      help_short!
    end

    STDERR.puts <<~MSG

      Usage:

          #{help_for_command(subcommand)}

      Run '#{binary_name} help #{subcommand}' for more details.
    MSG

    exit! 1
  end

  def help_subcommand!(subcommand)
    edoc = CommandHelp.new(@app, string_to_command(subcommand))

    puts <<~MSG
      #{help_for_command(subcommand)}

      #{edoc.full}
    MSG

    unless subcommands?

      STDERR.puts <<~MSG

        Default options include:

        #{binary_name} [ --help | -h ]                  ... print this help
        #{binary_name} [ --verbose | -v ]               ... run on DEBUG log level
        #{binary_name} [ --quiet | -q ]                 ... run on WARN log level
      MSG
    end
    exit 1
  end

  def logger
    Simple::CLI.logger
  end

  def on_exception(e)
    msg = e.message
    msg += " (#{e.class.name})" unless $!.class.name == "RuntimeError"
    logger.error msg

    raise(e) if Simple::CLI.logger.level == Logger::DEBUG

    verbosity_hint = "(Backtraces are currently silenced. Run with --verbose to see backtraces.)"

    case e
    when ArgumentError
      logger.info do
        backtrace = e.backtrace.reject { |l| l =~ /simple-cli/ }
        "called from\n    " + backtrace[0, 10].join("\n    ")
      end
      logger.warn verbosity_hint

      short_help! subcommand
    else
      logger.warn verbosity_hint
      exit 2
    end
  end

  def args_with_options(args)
    r = []
    options = {}
    while (arg = args.shift)
      case arg
      when /^--(.*)=(.*)/ then options[$1.to_sym] = $2
      when /^--no-(.*)/   then options[$1.to_sym] = false
      when /^--(.*)/      then options[$1.to_sym] = true
      else r << arg
      end
    end

    r << options unless options.empty?
    r
  end

  def command_to_string(sym)
    sym.to_s.tr("_", ":")
  end

  def string_to_command(s)
    return nil unless s

    s.to_s.tr(":", "_").to_sym
  end

  def commands
    @app.public_instance_methods(false).grep(/^[_a-zA-Z0-9]+$/)
  end

  def help_for_command(sym)
    cmd = string_to_command(sym)
    CommandHelp.new(@app, cmd).interface(binary_name, cmd, include_subcommand: subcommands?)
  end

  def binary_name
    $0.gsub(/.*\//, "")
  end

  def help_short!
    STDERR.puts "Usage:\n\n"
    print_help_line "#{binary_name} <subcommand> [ options... ]", "run a subcommand"

    print_help_line "#{binary_name} help [ <subcommand> ]", "print help for all or a specific subcommand"
    print_help_line "#{binary_name} help -v", "show help for internal commands as well"

    STDERR.puts "\n"

    exit 1
  end

  def print_help_line(cmd, description)
    @max_length = 45 if !@max_length || @max_length < 45

    if description
      STDERR.puts format("    %-#{@max_length}s    # %s", cmd, description)
    else
      STDERR.puts format("    %-#{@max_length}s", cmd)
    end
  end

  def help!
    # collect help information on individual comments; when not on DEBUG
    # level skipping the commands that don't jave a command help.
    command_helps = {}

    command_helps = commands.inject({}) do |hsh, sym|
      edoc = CommandHelp.new(@app, sym)
      next hsh if !edoc.head && logger.level != ::Logger::DEBUG

      hsh.update sym => help_for_command(sym)
    end

    # build a lambda which prints a help line with nice formatting
    @max_length = command_helps.values.map(&:length).max

    # print help for commands
    STDERR.puts "Usage:\n\n"

    command_helps.keys.sort.each do |sym|
      command_help = command_helps[sym]
      edoc = CommandHelp.new(@app, sym)
      print_help_line command_help, edoc.head
    end

    # print help for default commands

    STDERR.puts <<~DOC

      Default options include:

    DOC

    print_help_line "#{binary_name} [ --verbose | -v ]", "run on DEBUG log level"
    print_help_line "#{binary_name} [ --quiet | -q ]", "run on WARN log level"

    STDERR.puts <<~DOC

      Other commands:

    DOC

    print_help_line "#{binary_name} help [ <subcommand> ]", "print help for all or a specific subcommand"
    print_help_line "#{binary_name} help -v", "show help for internal commands as well"

    STDERR.puts "\n"

    exit 1
  end
end
