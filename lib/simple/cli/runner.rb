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
      when "-v", "--verbose" then
        logger.level = Logger::DEBUG
      when "-q", "--quiet" then
        logger.level = Logger::WARN
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
      autocomplete *args
    elsif command == :autocomplete_bash
      autocomplete_bash *args
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
    edoc = CommandHelp.new(@app, subcommand)

    puts <<~MSG
      #{help_for_command(subcommand)}

      #{edoc.full}
     MSG
  end

  def logger
    Simple::CLI.logger
  end

  def on_exception(e)
    raise(e) if Simple::CLI::DEBUG

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
    while arg = args.shift
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
    sym.to_s.gsub("_", ":")
  end

  def string_to_command(s)
    s.gsub(":", "_").to_sym
  end

  def commands
    @app.public_instance_methods(false).grep(/^[_a-zA-Z0-9]+$/) + [:help]
  end

  def help_for_command(sym)
    if sym == "autocomplete"
      autocomplete_help
      return
    end

    command_name = command_to_string(sym)
    CommandHelp.new(@app, sym).interface(binary_name, command_name)
  end

  def binary_name
    $0.gsub(/.*\//, "")
  end

  def help!
    STDERR.puts "Usage:\n\n"
    command_helps = commands.inject({}) do |hsh, sym|
      hsh.update sym => help_for_command(sym)
    end
    max_command_helps_length = command_helps.values.map(&:length).max

    commands.sort.each do |sym|
      command_help = command_helps.fetch(sym)
      command_help = "%-#{max_command_helps_length}s" % command_help
      edoc = CommandHelp.new(@app, sym)
      head = "# #{edoc.head}" if edoc.head
      STDERR.puts "    #{command_help}    #{ head }"
    end

    STDERR.puts "\n"

    STDERR.puts <<~DOC
    Default options include:

        #{binary_name} [ --verbose | -v ]         # run on DEBUG log level
        #{binary_name} [ --quiet | -q ]           # run on WARN log level
        #{binary_name} help autocomplete          # print information on autocompletion.

    DOC

    exit 1
  end
end
