module Simple::CLI::Adapter
  def run!(*args)
    args = ARGV if args.empty?

    Simple::CLI::Runner.run(self, *args)
  end
end
