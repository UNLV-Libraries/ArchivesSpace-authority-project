module ASpaceExport
  module ArchivalObjectDescriptionHelpers
    def format_date_string(date)
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
      new_date.strip
    end

    def archdesc_dates
      unless @archdesc_dates
        results = []
        dates = self.dates || []
        dates.each do |date|
          normal = ""
          unless date['begin'].nil?
            normal = "#{date['begin']}/"
            normal_suffix = (date['date_type'] == 'single' || date['end'].nil? || date['end'] == date['begin']) ? date['begin'] : date['end']
            normal += normal_suffix ? normal_suffix : ""
          end
          type = ( date['date_type'] == 'inclusive' ) ? 'inclusive' :  ( ( date['date_type'] == 'single') ? nil : 'bulk')
          content = if date['expression']
                    date['expression']
                  elsif date['end'].nil? || date['end'] == date['begin']
                    format_date_string(date['begin'])
                  else
                    new_begin = format_date_string(date['begin'])
                    new_end = format_date_string(date['end'])
                    "#{new_begin} to #{new_end}"
                  end

          atts = {}
          atts[:type] = type if type
          if date['certainty']
            atts[:certainty] = date['certainty']
            case date['certainty']
            when 'approximate'
              content = "approximately #{content}"
            when 'questionable'
              content = "possibly #{content}"
            when 'inferred'
              content = "probably #{content}"
            end
          end
          atts[:normal] = normal unless normal.empty?
          atts[:era] = date['era'] if date['era']
          atts[:calendar] = date['calendar'] if date['calendar']

          results << {:content => content, :atts => atts}
        end

        @archdesc_dates = results
      end
      
      @archdesc_dates
    end
  end
end
