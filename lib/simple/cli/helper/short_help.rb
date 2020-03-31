# rubocop:disable Metrics/AbcSize

module Simple::CLI
  module Helper
    def short_help!(service)
      # We check if we have only a few number of actions. In that case we just show the full help instead.
      actions = ::Simple::Service.actions(service).values
      actions, hidden_actions = actions.partition(&:short_description)

      STDERR.puts <<~MSG
        #{H.binary_name} <subcommand> [ options... ]

      MSG

      # if we don't have too many subcommands we print them here. If not, we only print their names
      # and mention the help command.
      if actions.count < 1
        STDERR.puts <<~MSG
          Subcommands:

          #{format_usages usages(service, verbose: false), prefix: "    "}

        MSG
      else
        subcommands = actions.map { |action| "'" + H.action_to_command(action.name) + "'" }
        msg = "Subcommands include #{subcommands.sort.join(", ")}"
        msg += " (and, in addition, #{hidden_actions.count} internal commands)" if hidden_actions.count > 0

        STDERR.puts <<~MSG
          #{msg}. Run with "-h" for more details.

        MSG
      end

      STDERR.puts <<~MSG
        Default options and subcommands include:

        #{format_usages default_usages(service, verbose: false), prefix: "    "}

        MSG

      exit 2
    end
  end
end
