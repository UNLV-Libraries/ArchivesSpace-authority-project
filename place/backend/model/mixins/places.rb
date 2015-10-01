module Places

  def self.included(base)
    base.one_to_many :place

    base.def_nested_record(:the_property => :places,
                           :contains_records_of_type => :place,
                           :corresponding_to_association  => :place)
  end

end