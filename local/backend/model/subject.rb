Subject.class_eval do
  auto_generate :property => :title,
                :generator => proc { |json|
                                json["terms"].map do |t|
                                  if t.is_a? String
                                    Term[JSONModel(:term).id_for(t)].term
                                  else
                                    t["term"]
                                  end
                                end.join("--")
                              }
end
