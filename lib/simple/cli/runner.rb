# rubocop:disable  Metrics/AbcSize
# rubocop:disable  Metrics/ClassLength
# rubocop:disable  Metrics/CyclomaticComplexity
# rubocop:disable  Metrics/MethodLength
# rubocop:disable  Metrics/PerceivedComplexity

class Simple::CLI::Runner
end

require_relative "runner/command_help"
require_relative "runner/autocompletion"

# A Runner object manages running a CLI application module with a set
# of string arguments (usually taken from ARGV)
class Simple::CLI::Runner
  include Autocompletion

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

  def run(*args)
    extract_default_flags!(args)

    @instance = Object.new.extend(@app)
    command_name = args.shift || help!
    command = string_to_command(command_name)

    if command == :help
      do_help!(*args)
    elsif command == :autocomplete
      autocomplete(*args)
    elsif command == :autocomplete_bash
      autocomplete_bash(*args)
    elsif commands.include?(command)
      @instance.run! command, *args_with_options(args)
    else
      help!
    end
  rescue StandardError => e
    on_exception(e)
  end

  def do_help!(subcommand = nil)
    if !subcommand
      help!
    else
      help_subcommand!(subcommand)
    end
  end

  def help_subcommand!(subcommand)
    edoc = CommandHelp.new(@app, string_to_command(subcommand))

    puts <<~MSG
      #{help_for_command(subcommand)}

      #{edoc.full}
     MSG
  end

  def logger
    Simple::CLI.logger
  end

  def on_exception(e)
    raise(e) if Simple::CLI.logger.level == Logger::DEBUG

    case e
    when ArgumentError
      logger.error "#{e}\n\n"
      help!
    else
      msg = e.to_s
      msg += " (#{e.class.name})" unless $!.class.name == "RuntimeError"
      logger.error msg
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
    s.to_s.tr(":", "_").to_sym
  end

  def commands
    @app.public_instance_methods(false).grep(/^[_a-zA-Z0-9]+$/)
  end

  def help_for_command(sym)
    if sym == "autocomplete"
      autocomplete_help
      return
    end

    cmd = string_to_command(sym)
    CommandHelp.new(@app, cmd).interface(binary_name, cmd)
  end

  def binary_name
    $0.gsub(/.*\//, "")
  end

  def help!
    # collect help information on individual comments; when not on DEBUG
    # level skipping the commands that don't jave a command help.
    command_helps = commands.inject({}) do |hsh, sym|
      edoc = CommandHelp.new(@app, sym)
      next hsh if !edoc.head && logger.level != ::Logger::DEBUG

      hsh.update sym => help_for_command(sym)
    end

    # build a lambda which prints a help line with nice formatting
    max_length = command_helps.values.map(&:length).max
    print_help_line = lambda do |cmd, description|
      if description
        STDERR.puts format("    %-#{max_length}s    # %s", cmd, description)
      else
        STDERR.puts format("    %-#{max_length}s", cmd)
      end
    end

    # print help for commands
    STDERR.puts "Usage:\n\n"

    command_helps.keys.sort.each do |sym|
      command_help = command_helps[sym]
      edoc = CommandHelp.new(@app, sym)
      print_help_line.call command_help, edoc.head
    end

    # print help for default commands

    STDERR.puts <<~DOC

      Default options include:

    DOC

    print_help_line.call "#{binary_name} [ --verbose | -v ]", "run on DEBUG log level"
    print_help_line.call "#{binary_name} [ --quiet | -q ]", "run on WARN log level"

    STDERR.puts <<~DOC

      Other commands:

    DOC

    print_help_line.call "#{binary_name} help [ subcommand ]", "print help on a specific subcommand"
    print_help_line.call "#{binary_name} help -v", "show help for internal commands as well"
    print_help_line.call "#{binary_name} help autocomplete", "print information on autocompletion."

    STDERR.puts "\n"

    exit 1
  end
end
