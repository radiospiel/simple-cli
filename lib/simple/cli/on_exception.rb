# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

module Simple::CLI
  def self.on_exception(e)
    msg = e.message
    msg += " (#{e.class.name})" unless $!.class.name == "RuntimeError"

    logger.error msg

    raise(e) if Simple::CLI.logger.level == ::Logger::DEBUG

    logger.info do
      backtrace = e.backtrace.reject { |l| l =~ /simple-cli/ }
      "called from\n    " + backtrace[0, 10].join("\n    ")
    end

    verbosity_hint = "(Backtraces are currently silenced. Run with --verbose to see backtraces.)"
    logger.warn verbosity_hint

    exit 2
  end
end
