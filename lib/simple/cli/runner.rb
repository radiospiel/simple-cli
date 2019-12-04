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

      args.reject! do |arg|
        next false unless arg =~ /^--(no-)?([^=]+)(=(.+))?/

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
