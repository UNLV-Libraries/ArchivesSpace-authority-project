require 'securerandom'

class ArchivalObject < Sequel::Model(:archival_object)

  def self.format_date_string(date)
    require 'date'
    new_date = ""
    date.split("-").each_with_index {|val, index|
      if (index == 1)
        new_date += Date::MONTHNAMES[val.to_i]
      else
        new_date += val
      end
      new_date += " "
    }
    new_date.strip
  end

  def self.produce_display_string(json)
    display_string = json['title'] || ""

    date_label = json.has_key?('dates') && json['dates'].length > 0 ?
                   json['dates'].map {|date|
                     if date['expression']
                       date['expression']
                     else
                       if date['begin'] and date['end']
                         new_date = "#{self.format_date_string(date['begin'])} to #{self.format_date_string(date['end'])}"
                       else
                         new_date = self.format_date_string(date['begin'])
                       end
                       if date['certainty']
                         case date['certainty']
                         when 'approximate'
                           new_date = "approximately #{new_date}"
                         when 'questionable'
                           new_date = "possibly #{new_date}"
                         when 'inferred'
                           new_date = "probably #{new_date}"
                         end
                       end
                       new_date
                     end
                   }.join(', ') : false
    display_string += ", " if json['title'] && date_label
    display_string += date_label if date_label

    display_string
  end

end