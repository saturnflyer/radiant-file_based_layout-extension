module ApplicationControllerFileExt
    def self.included(base)
      base.class_eval {
        helper_method :content
        helper_method :if_content
        helper_method :unless_content
        helper_method :if_url
        helper_method :unless_url
        
        before_filter :correct_relative_url_root
        
        def correct_relative_url_root
          request.relative_url_root = '/'
        end
            
        def content(options={})
          part_page = @page
          part = options[:part] || 'body'
          inherit = options[:inherit] || false
          part = part.to_s.strip!
          if inherit
            while (part_page.part(part).nil? and (not part_page.parent.nil?)) do
              part_page = part_page.parent
            end
          end
          part_page.render_part(part).gsub(/\"/,'\\\"')
        end
              
        def if_content(options={})
          parts_arr = options[:part].split(',') || ['body']
          find = attr_or_error(options[:find], 'any, all', 'all')
          inherit = attr_or_error(options[:inherit], 'true, false', 'false')
          expandable, one_found = true, false
          part_page = @page
          parts_arr.each do |name|
            name.strip!
            if inherit
              while (part_page.part(name).nil? and (not part_page.parent.nil?)) do
                part_page = part_page.parent
              end
            end
            expandable = false if part_page.part(name).nil?
            one_found ||= true if !part_page.part(name).nil?
          end
          expandable = true if (find == 'any' and one_found)
          yield if expandable
        end
        
        def unless_content(options={})
          parts_arr = options[:part].split(',') || ['body']
          find = options[:find] || 'all'
          inherit = attr_or_error(options, 'inherit', 'true, false') || 'false'
          expandable, all_found = true, false
          part_page = @page
          parts_arr.each do |name|
            name.strip!
            if inherit
              while (part_page.part(name).nil? and (not part_page.parent.nil?)) do
                part_page = part_page.parent
              end
            end
            expandable = false if !part_page.part(name).nil?
            all_found = false if part_page.part(name).nil?
          end
          if all_found == false and find == 'all'
            expandable = true
          end
          yield if expandable
        end
        
        def if_url(options={})
          regexp = build_regexp_for(options, 'matches')
          yield unless @url.to_s.match(regexp).nil?
        end
        
        def unless_url(options={})
          regexp = build_regexp_for(options, 'matches')
          yield if @url.to_s.match(regexp).nil?
        end
        
        private
        
        def attr_or_error(attribute, value_options, default)
          the_values = value_options.split(',').map!(&:strip)
          if attribute.blank?
            return default
          elsif !the_values.include?(attribute)
            raise ArgumentError.new(%{'#{attribute}' must be one of: #{the_values.join(', ')}})
          else
            return attribute
          end
        end
        
        def build_regexp_for(options, attribute_name)
          ignore_case = options.has_key?('ignore_case') && options['ignore_case']=='false' ? nil : true
          begin
            regexp = Regexp.new(options[attribute_name.to_sym], ignore_case)
          rescue RegexpError => e
            raise ArgumentError.new("Malformed regular expression in `#{attribute_name}' argument: #{e.message}")
          end
          regexp
        end
      }
    end
end