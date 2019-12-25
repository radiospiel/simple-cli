# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

module Simple::CLI
  module Runner
    extend self

    def run!(service, command, *args, verbose:)
      _ = verbose

      action_name = H.command_to_action(command)
      Simple::Service.with_context do
        flags = extract_flags!(args)
        ::Simple::Service.invoke(service, action_name, args: args, flags: flags)
      end
    end

    private

    # extract options from the array. Note: simple-cli is the correct place
    # for this, and not simple-service, because it deals with a conversion
    # which is strictly related to command line applications, and simple-service
    # doesn't have any knowledge of CLI applications.
    #
    # This returns a hash of flag values, as determined by a "--flagname[=<value>]"
    # command line options, and removes all such options from the arg array.
    def extract_flags!(args)
      flags = {}

      had_path_separator = false

      args.reject! do |arg|
        # path separator? When encountering "--" all following arguments are
        # considered not flags.
        #
        # We set the had_path_separator flag (to remember that we have seen it,
        # but then `next true` regardless because we need to remove the argument
        # from the +args+ array.
        if arg == "--"
          had_path_separator = true
          next true
        end
        break if had_path_separator

        # Doesn't look like an argument?
        next false unless arg =~ /^--(no-)?([^=]+)(=(.+))?/

        # Extract the flag, and its value (false, true, or a String)
        flag_name = $2.tr("-", "_")
        flag_name = "no_#{flag_name}" if $4 && $1
        value = $4 || ($1 ? false : true)

        flags[flag_name] = value
        true
      end

      flags
    end
  end
end
