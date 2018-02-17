module Simple::CLI::Adapter
  def run!(*args)
    args = ARGV if args.empty?

    Simple::CLI::Runner.run(self, *args)
  end

  def logger=(logger)
    Simple::CLI.logger = logger
  end

  def logger
    Simple::CLI.logger
  end
end
