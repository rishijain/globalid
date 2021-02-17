require 'active_model'

class PersonModel
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include GlobalID::Identification
  include ActiveModel::AttributeMethods

  attr_accessor :id

  def initialize(options={})
    @id = options[:id]
  end

  def self.find(id)
    new id: id
  end

  def ==(other)
    id == other.try(:id)
  end
end
