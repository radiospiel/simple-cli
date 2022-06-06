module ::Simple::CLI::Deprecations
  SELF = self

  def logger
    SELF.deprecated! "Simple::CLI#logger", alternative: "Simple::CLI.logger"
  end

  def run!(*_)
    SELF.deprecated! "Simple::CLI#run!", alternative: "Simple::CLI.run!(Your::CLI)"
  end

  def self.deprecated!(what, alternative: nil)
    Simple::CLI.logger.error "'#{what}' was removed."
    if alternative
      Simple::CLI.logger.info "You probably want to use '#{alternative}' instead."
    end
    exit 1
  end  
end
