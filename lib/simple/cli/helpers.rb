require "open3"

# Helpers are mixed into all CLI modules. They implement the following methods,
# mostly to help with integrating external commands:
#
# - sys
# - sys!
# - sh!
# - die!
#
module Simple::CLI::Helpers
  def die!(msg)
    STDERR.puts msg
    exit 1
  end

  def logger
    ::Simple::CLI.logger
  end

  SSH = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

  def ssh_command(host, user: nil)
    host = "#{user}@#{host}" if user
    "#{SSH} #{host}"
  end

  def ssh!(target, command, user: nil)
    sys! "#{ssh_command(target, user: user)} #{command}"
  end

  def sh(cmd, *args)
    command = Command.new(cmd, *args)
    result = command.sh
    first_line, more = result.split("\n", 2)
    if more == ""
      first_line
    else
      result
    end
  end

  def sh!(cmd, *args)
    command = Command.new(cmd, *args)
    result = command.sh
    command.check_success!
    first_line, more = result.split("\n", 2)
    if more == ""
      first_line
    else
      result
    end
  end

  def sys(cmd, *args)
    command = Command.new(cmd, *args)
    command.run
    command.success?
  end

  def sys!(cmd, *args)
    command = Command.new(cmd, *args)
    command.run
    command.check_success!
    true
  end

  class Command
    def initialize(cmd, *args)
      @cmd = cmd
      @args = [cmd] + args
    end

    def sh
      ::Simple::CLI.logger.info "> #{self}"
      stdout_str, @process_status = Open3.capture2(*@args, binmode: true)
      $? = @process_status
      stdout_str
    end

    def run
      ::Simple::CLI.logger.info "> #{self}"
      if @args.length > 1
        system to_s
      else
        system @args.first
      end
    ensure
      @process_status = $?
    end

    def success?
      @process_status.success?
    end

    def check_success!
      return if @process_status.success?
      raise "#{@cmd} failed with #{@process_status.exitstatus}: #{self}"
    end

    # Returns the command as a single string, escaping things as necessary.
    def to_s
      require "shellwords"

      escaped_args = @args.map do |arg|
        escaped = Shellwords.escape(arg)
        next escaped if escaped == arg
        next escaped if arg.include?("'")
        "'#{arg}'"
      end
      escaped_args.join(" ")
    end
  end
end
