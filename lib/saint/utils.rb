module Saint
  module Utils

    include Presto::Utils

    BOOLEAN_OPTIONS = {true => 'Yes', false => 'No'}
    BOOLEAN_FILTERS = {'1' => 'Yes', '0' => 'No'}

    def saint_view scope = self
      api = Presto::ViewApi.new
      api.engine Saint.view.engine
      api.ext Saint.view.ext
      api.root Saint.view.root
      api.scope scope
      api
    end

    module_function :saint_view

    def format_date__time type, val, with_timezone = false
      return val unless val.is_a?(Date) || val.is_a?(DateTime) || val.is_a?(Time)
      return unless format = {
          'date' => '%F',
          'date_time' => '%F %T.%L' << (with_timezone ? ' %Z' : ''),
          'time' => '%T.%L',
      }[type.to_s]
      val.strftime format
    end

    # remove any non-printable chars
    def normalize_string str
      str.to_s.encode(
          invalid: :replace,
          undef: :replace,
          universal_newline: true
      )
    end

    module_function :normalize_string

    def number_to_human_size number, opts = {}
      k = 2.0**10
      m = 2.0**20
      g = 2.0**30
      t = 2.0**40
      p = 2.0**50
      e = 2.0**60
      z = 2.0**70
      y = 2.0**80
      max_digits = opts[:max_digits] || 3
      bytes = number || 0
      value, suffix, precision = case bytes
                                   when 0...k
                                     [bytes, 'B', 0]
                                   else
                                     value, suffix = case bytes
                                                       when k...m then
                                                         [bytes / k, 'KB']
                                                       when m...g then
                                                         [bytes / m, 'MB']
                                                       when g...t then
                                                         [bytes / g, 'GB']
                                                       when t...p then
                                                         [bytes / t, 'TB']
                                                       when p...e then
                                                         [bytes / p, 'PB']
                                                       when e...z then
                                                         [bytes / e, 'EB']
                                                       when z...y then
                                                         [bytes / z, 'ZB']
                                                       else
                                                         [bytes / y, 'YB']
                                                     end
                                     used_digits = case value
                                                     when 0...10 then
                                                       1
                                                     when 10...100 then
                                                       2
                                                     when 100...1000 then
                                                       3
                                                   end
                                     leftover_digits = max_digits - used_digits.to_i
                                     [value, suffix, leftover_digits > 0 ? leftover_digits : 0]
                                 end
      return "%.#{precision}f #{suffix}" % value unless opts[:split]
      ["%.#{precision}f" % value, suffix]
    end

    module_function :number_to_human_size

    def column_format arg, row

      chunks = Array.new

      evaluate = lambda do |chunk|
        obj = row
        chunk.split('.').map { |m| m.to_sym }.each do |meth|
          unless obj.respond_to?(meth)
            obj = nil
            break
          end
          obj = obj.send(meth)
        end
        obj.to_s
      end

      if arg.is_a?(String)
        if arg =~ /#/
          chunk, valid = '', false
          arg.split(/(?<=[^\\])?(#[\w|\d|\.]+)/m).each do |s|
            if s =~ /^#/
              next unless (val = evaluate.call(s.sub('#', ''))).size > 0
              chunk << val
              valid = true
            else
              chunk << s
            end
          end
          chunks << chunk if valid
        else
          chunks << evaluate.call(arg.strip)
        end
      else
        chunks << evaluate.call(arg.to_s)
      end
      chunks.join
    end

    module_function :column_format

    def escape_html str
      CGI::escapeHTML str
    end

    module_function :escape_html

    def unescape_html str
      CGI::unescapeHTML str
    end

    module_function :unescape_html

  end
end
