# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength

require_relative "./module_ex"

class Simple::CLI::Runner::CommandHelp
  def self.option_names(app, subcommand)
    new(app, subcommand).option_names
  rescue NameError
    []
  end

  def initialize(mod, method_id)
    raise(ArgumentError, "#{method_id.inspect} should be a Symbol") unless method_id.is_a?(Symbol)

    @method_id            = method_id
    @method               = mod.instance_method(@method_id)
    @method_parameters_ex = mod.method_parameters_ex(@method_id)
  end

  # First line of the help as read from the method comments.
  def head
    comments.first
  end

  # Full help as read from the method comments
  def full
    comments.join("\n") if comments.first
  end

  def option_names
    option_names = @method_parameters_ex.map do |mode, name, _|
      case mode
      when :key     then name
      when :keyreq  then name
      end
    end.compact

    option_names.map do |name|
      ["--#{name}", "--#{name}="]
    end.flatten
  end

  # A help string constructed from the commands method signature.
  def interface(binary_name, command_name, include_subcommand: false)
    args = @method_parameters_ex.map do |mode, name|
      case mode
      when :req   then "<#{name}>"
      when :opt   then "[ <#{name}> ]"
      when :rest  then "[ <#{name}> .. ]"
      end
    end.compact

    options = @method_parameters_ex.map do |mode, name, default_value|
      case mode
      when :key     then
        case default_value
        when false  then  "[ --#{name} ]"
        when true   then  "[ --no-#{name} ]"
        when nil    then  "[ --#{name}=<#{name}> ]"
        else              "[ --#{name}=#{default_value} ]"
        end
      when :keyreq  then
        "--#{name}=<#{name}>"
      end
    end.compact

    help = binary_name.to_s
    help << " #{command_to_string(command_name)}" if include_subcommand
    help << " #{options.join(' ')}" unless options.empty?
    help << " #{args.join(' ')}" unless args.empty?
    help
  end

  private

  def command_to_string(s)
    s.to_s.tr("_", ":")
  end

  def comments
    @comments ||= begin
      file, line = @method.source_location
      extract_comments(from: parsed_source(file), before_line: line)
    end
  end

  # reads the source \a file and turns each non-comment into :code and each comment
  # into a string without the leading comment markup.
  def parsed_source(file)
    File.readlines(file).map do |line|
      case line
      when /^\s*# ?(.*)$/ then $1
      when /^\s*end/ then :end
      end
    end
  end

  def extract_comments(from:, before_line:)
    parsed_source = from

    # go down from before_line until we see a line which is either a comment
    # or an :end. Note that the line at before_line-1 should be the first
    # line of the method definition in question.
    last_line = before_line - 1
    last_line -= 1 while last_line >= 0 && !parsed_source[last_line]

    first_line = last_line
    first_line -= 1 while first_line >= 0 && parsed_source[first_line]
    first_line += 1

    comments = parsed_source[first_line..last_line]
    if comments.include?(:end)
      []
    else
      parsed_source[first_line..last_line]
    end
  end
end
