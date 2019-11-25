module Simple::CLI
  module Helper
    def help!(service, verbose:)
      STDERR.puts <<~MSG
        #{H.binary_name} <command> [ options... ]

        Commands:

        #{format_usages usages(service, verbose: verbose), prefix: "    "}

        Default options and commands include:

        #{format_usages default_usages(service, verbose: verbose), prefix: "    "}

      MSG

      exit 2
    end

    private

    def usages(service, verbose:)
      actions = ::Simple::Service.actions(service).values
      actions = actions.select(&:short_description) unless verbose
      actions = actions.sort_by(&:name)

      actions.map do |action|
        [ action_usage(action), action.short_description ]
      end
    end

    def default_usages(service, verbose:)
      _ = service
      _ = verbose

      [
        [ "#{H.binary_name} help [ <command> ]", "print help for all or a specific command" ],
        [ "#{H.binary_name} help -v", "show help for internal commands as well"],
        [ "#{H.binary_name} [ --verbose | -v ]", "run on DEBUG log level"],
        [ "#{H.binary_name} [ --quiet | -q ]", "run on WARN log level"],
      ]
    end

    def format_usages(ary, prefix:)
      # each entry is an Array of one or two entries. The first entry is a command usage
      # string, the second entry is the command's short_description.
      max_cmd_length = ary.inject(45) do |max, (cmd, _description)|
        cmd.length > max ? cmd.length : max
      end

      ary.map do |cmd, description|
        if description
          format("#{prefix}%-#{max_cmd_length}s    # %s", cmd, description)
        else
          format("#{prefix}%-#{max_cmd_length}s", cmd)
        end
      end.join("\n")
    end
  end
end
