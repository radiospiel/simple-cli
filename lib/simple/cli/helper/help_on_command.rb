# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength

module Simple::CLI
  module Helper
    def help_on_command!(service, command, verbose:)
      _ = verbose
      action = H.action_for_command(service, command)

      parts = [
        action.short_description,
        action_usage(action),
        action.full_description,
      ].compact

      STDERR.puts <<~MSG
        #{parts.join("\n\n")}

      MSG

      exit 2
    end

    private

    # Used in command_help.rb and in help.rb
    def action_usage(action)
      args = action.parameters.reject(&:keyword?).map do |param|
        case param.kind
        when :req   then "<#{param.name}>"
        when :opt   then "[ <#{param.name}> ]"
        when :rest  then "[ <#{param.name}> .. ]"
        end
      end.compact

      options = action.parameters.select(&:keyword?).map do |param|
        if param.required?
          "--#{name}=<#{name}>"
        else
          case param.default_value
          when false  then  "[ --#{param.name} ]"
          when true   then  "[ --no-#{param.name} ]"
          when nil    then  "[ --#{param.name}=<#{param.name}> ]"
          else              "[ --#{param.name}=#{param.default_value} ]"
          end
        end
      end

      help = "#{H.binary_name} #{H.action_to_command(action.name)}"
      help << " #{options.join(" ")}" unless options.empty?
      help << " #{args.join(" ")}" unless args.empty?
      help
    end
  end
end
