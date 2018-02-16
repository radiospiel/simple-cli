# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength

class Simple::CLI::Runner::CommandHelp
  def self.option_names(app, subcommand)
    new(app, subcommand).option_names
  rescue NameError
    []
  end

  def initialize(mod, method)
    @mod = mod
    @method = method
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
    method = @mod.instance_method(@method)

    option_names = method.parameters.map do |mode, name|
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
  def interface(binary_name, command_name)
    method = @mod.instance_method(@method)

    options = []
    args = []

    method.parameters.each do |mode, name|
      case mode
      when :req     then args << "<#{name}>"
      when :key     then options << "[ --#{name}[=<#{name}>] ]"
      when :keyreq  then options << "--#{name}[=<#{name}>]"
      when :opt     then args << "[ <#{name}> ]"
      when :rest    then args << "[ <#{name}> .. ]"
      end
    end

    help = "#{binary_name} #{command_name}"
    help << " #{options.join(' ')}" unless options.empty?
    help << " #{args.join(' ')}" unless args.empty?
    help
  end

  private

  def comments
    @comments ||= begin
      file, line = @mod.instance_method(@method).source_location
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
