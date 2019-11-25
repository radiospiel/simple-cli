module Simple::CLI
  module Helper
    def short_help!(service)
      # We check if we have only a few number of actions. In that case we just show the full help instead.
      actions = ::Simple::Service.actions(service).values
      actions, hidden_actions = actions.partition(&:short_description)

      STDERR.puts <<~MSG
        #{H.binary_name} <command> [ options... ]

      MSG

      subcommands = actions.map { |action| "'" + H.action_to_command(action.name)  + "'" }
      msg = "Subcommands include #{subcommands.sort.join(", ")}"
      msg += " (and an additional #{hidden_actions.count} internal commands)"

      STDERR.puts <<~MSG
        #{msg}. Default options and commands include:

        #{format_usages default_usages(service, verbose: false), prefix: "    "}

        MSG

      exit 2
    end
  end
end
