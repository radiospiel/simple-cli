# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize

class Module
  #
  # returns an array with entries like the following:
  #
  #  [ :key, name, default_value ]
  #  [ :keyreq, name [, nil ] ]
  #  [ :req, name [, nil ] ]
  #  [ :opt, name [, nil ] ]
  #  [ :rest, name [, nil ] ]
  #
  def method_parameters_ex(method_id)
    method = instance_method(method_id)
    parameters = method.parameters

    # method parameters with a :key mode are optional keyword arguments. We only
    # support defaults for those - if there are none we abort here already.
    keys = parameters.map { |mode, name| name if mode == :key }.compact
    return parameters if keys.empty?

    # We are now doing a fake call to the method, with a minimal viable set of
    # arguments, to let the ruby runtime fill in default values for arguments.
    # We do not, however, let the call complete. Instead we use a TracePoint to
    # abort as soon as the method is called, and use the its binding to determine
    # the default values.

    fake_recipient = Object.new.extend(self)
    fake_call_args = minimal_arguments(method)

    trace_point = TracePoint.trace(:call) do |tp|
      throw :received_fake_call, tp.binding if tp.defined_class == self && tp.method_id == method_id
    end

    bnd = catch(:received_fake_call) do
      fake_recipient.send(method_id, *fake_call_args)
    end

    trace_point.disable

    # extract default values from the received binding, and merge with the
    # parameters array.
    default_values = keys.each_with_object({}) do |key_parameter, hsh|
      hsh[key_parameter] = bnd.local_variable_get(key_parameter)
    end

    parameters.map do |mode, name|
      [mode, name, default_values[name]]
    end
  end

  private

  # returns a minimal Array of arguments, which is suitable for a call to the method
  def minimal_arguments(method)
    # Build an arguments array with holds all required parameters. The actual
    # values for these arguments doesn't matter at all.
    args = method.parameters.select { |mode, _name| mode == :req }

    # Add a hash with all required keyword arguments
    required_keyword_args = method.parameters.each_with_object({}) do |(mode, name), hsh|
      hsh[name] = :anything if mode == :keyreq
    end
    args << required_keyword_args if required_keyword_args

    args
  end
end
