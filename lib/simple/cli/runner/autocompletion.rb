module Simple::CLI::Runner::Autocompletion
  CommandHelp = Simple::CLI::Runner::CommandHelp

  def autocomplete(subcommand = nil, cur = nil)
    puts completions(subcommand, cur).join("\n")
  end

  def completions(subcommand = nil, cur = nil)
    if !cur
      autocomplete_subcommands(subcommand)
    else
      autocomplete_subcommand_options(subcommand, cur)
    end
  end

  def filter_completions(completions, prefix:)
    completions.select do |completion|
      !prefix || completion.start_with?(prefix)
    end
  end

  def autocomplete_subcommands(cur)
    commands = self.commands.map { |cmd| cmd.to_s.tr("_", ":") }
    commands << "help"
    completions = filter_completions commands, prefix: cur
    if completions == [cur]
      autocomplete_subcommand_options(cur, nil)
    else
      completions
    end
  end

  DEFAULT_OPTIONS = %w(--verbose -v --quiet -q)

  def autocomplete_subcommand_options(subcommand, cur)
    if subcommand == "help"
      completions = commands.map(&:to_s).map { |s| s.tr("_", ":") } + ["autocomplete"]
      filter_completions completions, prefix: cur
    elsif cur && cur[0,1] == "-"
      completions = CommandHelp.option_names(@app, string_to_command(subcommand))
      completions += DEFAULT_OPTIONS

      filter_completions completions, prefix: cur
    else
      Dir.glob "#{cur}*"
    end
  end

  def autocomplete_help
    STDERR.puts <<~DOC
      #{binary_name} supports autocompletion. To enable autocompletion please run

          eval "$(#{$0} autocomplete:bash)"
    DOC

    exit 1
  end

  def autocomplete_bash
    puts AUTOCOMPLETE_SHELL_CODE.gsub(/{{BINARY}}/, binary_name)
  end

  # The shell function function is executed in the current shell environment.
  # When it is executed,
  #
  # - $1 is the name of the command whose arguments are being completed,
  # - $2 is the word being completed, and
  # - $3 is the word preceding the word being completed
  #
  # When it finishes, the possible completions are retrieved from the value of the COMPREPLY array variable.
  #
  # see https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html
  #
  AUTOCOMPLETE_SHELL_CODE = <<~BASH
    _{{BINARY}}()
    {
      local cmd=$1
      local cur=$2

      if [[ $COMP_CWORD == 1 ]]; then
        COMPREPLY=( $("$cmd" autocomplete "$cur" ))
      else
        local subcommand=${COMP_WORDS[1]}
        COMPREPLY=( $("$cmd" autocomplete "$subcommand" "$cur" ))
      fi

      return 0
    }
    complete -F _{{BINARY}} {{BINARY}}
  BASH
end
