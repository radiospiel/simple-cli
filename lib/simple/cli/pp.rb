# rubocop:disable Lint/HandleExceptions

require "pp"

begin
  require "awesome_print"

  def pp(*args)
    ap(*args)
  end
rescue LoadError
end
