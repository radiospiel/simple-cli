# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

module Simple::CLI::Logger::ColoredLogger
  extend self

  attr_accessor :level

  COLORS = {
    clear:      "\e[0m",  # Embed in a String to clear all previous ANSI sequences.
    bold:       "\e[1m",  # The start of an ANSI bold sequence.
    black:      "\e[30m", # Set the terminal's foreground ANSI color to black.
    red:        "\e[31m", # Set the terminal's foreground ANSI color to red.
    green:      "\e[32m", # Set the terminal's foreground ANSI color to green.
    yellow:     "\e[33m", # Set the terminal's foreground ANSI color to yellow.
    blue:       "\e[34m", # Set the terminal's foreground ANSI color to blue.
    magenta:    "\e[35m", # Set the terminal's foreground ANSI color to magenta.
    cyan:       "\e[36m", # Set the terminal's foreground ANSI color to cyan.
    white:      "\e[37m", # Set the terminal's foreground ANSI color to white.

    on_black:   "\e[40m", # Set the terminal's background ANSI color to black.
    on_red:     "\e[41m", # Set the terminal's background ANSI color to red.
    on_green:   "\e[42m", # Set the terminal's background ANSI color to green.
    on_yellow:  "\e[43m", # Set the terminal's background ANSI color to yellow.
    on_blue:    "\e[44m", # Set the terminal's background ANSI color to blue.
    on_magenta: "\e[45m", # Set the terminal's background ANSI color to magenta.
    on_cyan:    "\e[46m", # Set the terminal's background ANSI color to cyan.
    on_white:   "\e[47m"  # Set the terminal's background ANSI color to white.
  }

  # rubocop:disable Style/ClassVars
  @@started_at = Time.now

  MESSAGE_COLOR = {
    info: :cyan,
    warn: :yellow,
    error: :red,
    success: :green,
  }

  def debug(msg, *args)
    log :debug, msg, *args
  end

  def info(msg, *args)
    log :info, msg, *args
  end

  def warn(msg, *args)
    log :warn, msg, *args
  end

  def error(msg, *args)
    log :error, msg, *args
  end

  def success(msg, *args)
    log :success, msg, *args
  end

  private

  REQUIRED_LOG_LEVELS = {
    debug:    ::Logger::DEBUG,
    info:     ::Logger::INFO,
    warn:     ::Logger::WARN,
    error:    ::Logger::ERROR,
    success:  ::Logger::INFO
  }

  def log(sym, msg, *args)
    log_level = level
    required_log_level = REQUIRED_LOG_LEVELS.fetch(sym)
    return if required_log_level < log_level

    formatted_runtime = "%.3f secs" % (Time.now - @@started_at)
    msg = "[#{formatted_runtime}] #{msg}"
    unless args.empty?
      msg += ": " + args.map(&:inspect).join(", ")
    end

    msg_length = msg.length

    if (color = COLORS[MESSAGE_COLOR[sym]])
      msg = "#{color}#{msg}#{COLORS[:clear]}"
    end

    if log_level < Logger::INFO
      padding = " " * (90 - msg_length) if msg_length < 90
      msg = "#{msg}#{padding}"
      msg = "#{msg}from #{source_from_caller}"
    end

    STDERR.puts msg
  end

  # The heuristic used to determine the caller is not perfect, but should
  # do well in most cases.
  def source_from_caller
    source = caller.find { |loc| loc !~ /simple-cli.*\/lib\/simple\/cli/ }
    source || caller[2]
  end
end
