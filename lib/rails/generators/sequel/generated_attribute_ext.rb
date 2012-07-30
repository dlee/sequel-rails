
Rails::Generators::GeneratedAttribute.class_eval do
  # Add a method that we can use to determine which class to use to decode
  # attributes
  def type_class
    return 'DateTime' if type.to_s == 'datetime'
    return type.to_s.camelcase
  end
end
