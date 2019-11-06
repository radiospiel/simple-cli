module Simple::CLI::Adapter
  # Run a Simple::CLI application
  #
  # This is usually called with as either
  #
  # - Application::CLI.run!: runs the Application's CLI with subcommand support.
  # 
  # or
  #
  # - Application::CLI.run!("main"): runs the Application's CLI without subcommand support.
  #
  def run!(main_command = nil)
    runner = Simple::CLI::Runner.new(self)
    
    if main_command && ARGV.include?("--help")
      runner.help(main_command)
    elsif main_command
      runner.run(main_command, *ARGV)
    else
      runner.run(*ARGV)
    end
  end

  def logger=(logger)
    Simple::CLI.logger = logger
  end

  def logger
    Simple::CLI.logger
  end
end
