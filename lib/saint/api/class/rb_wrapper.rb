module Saint
  class ClassApi

    # It is important to have an engine agnostic Api.
    # If you set rb_wrapper, Api will wrap/unwrap ruby code automatically.
    #
    # ruby code will be wrapped into Api tags on crud pages,
    # and unwrapped when saved to db.
    #
    # @example
    #
    #    saint.rb_wrapper
    #
    #    # the code like <% code here %>
    #    # will be wrapped into :{: code here :}:
    #    # the code like <%= code here %>
    #    # will be wrapped into :{:= code here :}:
    #    # the code like <%== code here %>
    #    # will be wrapped into :{:== code here :}:
    #
    #    saint.rb_wrapper do
    #      tags '{%', '%}'
    #      output_tags '{{', '}}'
    #    end
    #
    #    # the code like {% code here %}
    #    # will be wrapped into :{: code here :}:
    #    # the code like {{ code here }}
    #    # will be wrapped into :{:= code here :}:
    #
    def rb_wrapper *args, &proc
      @rb_wrapper = ::Saint::RbWrapper.new
      @rb_wrapper.instance_exec(&proc) if proc
    end

    # check if rb_wrapper enabled and return its Api if so
    def rbw
      @rb_wrapper
    end
  end

  class RbWrapper

    #
    # IMPORTANT! keep the order
    #
    MAP = {
        escaped_output_open: {orig: '<%==', wrap: ':{:=='},
        escaped_output_close: {orig: '%>', wrap: ':}:'},
        output_open: {orig: '<%=', wrap: ':{:='},
        output_close: {orig: '%>', wrap: ':}:'},
        open: {orig: '<%', wrap: ':{:'},
        close: {orig: '%>', wrap: ':}:'},
    }

    attr_reader :map

    def initialize
      @map = MAP.clone
    end

    # set evaluator tags
    #
    # @param [String] open
    # @param [String] close
    def tags open, close
      @map[:open][:orig] = open
      @map[:close][:orig] = close
      output_tags open, close
    end

    # set output tags
    #
    # @param [String] open
    # @param [String] close
    def output_tags open, close
      @map[:output_open][:orig] = open
      @map[:output_close][:orig] = close
      escaped_output_tags open, close
    end

    # set escaped output tags
    #
    # @param [String] open
    # @param [String] close
    def escaped_output_tags open, close
      @map[:escaped_output_open][:orig] = open
      @map[:escaped_output_close][:orig] = close
    end

    # wrap given string into earlier defined tags
    # @param [String] str
    def wrap str
      return str unless str.respond_to?(:gsub)
      @map.each_pair do |t, m|
        str = replace(str, t, m[:orig], m[:wrap])
      end
      str
    end

    # unwrap given string
    # @param [String] str
    def unwrap str
      return str unless str.respond_to?(:gsub)
      @map.each_pair do |t, m|
        str = replace(str, t, m[:wrap], m[:orig])
      end
      str
    end

    # return wrapped evaluator tags
    def self.wrapped map = MAP
      [map[:open][:wrap], map[:close][:wrap]]
    end

    def wrapped
      self.class.send __method__, @map
    end

    # return wrapped output tags
    def self.wrapped_output map = MAP
      [map[:output_open][:wrap], map[:output_close][:wrap]]
    end

    def wrapped_output
      self.class.send __method__, @map
    end

    # return wrapped escaped output tags
    def self.wrapped_escaped_output map = MAP
      [map[:escaped_output_open][:wrap], map[:escaped_output_close][:wrap]]
    end
    
    def wrapped_escaped_output
      self.class.send __method__, @map
    end

    private
    def replace str, tag, from, to
      from = ::Regexp.escape(from)
      if tag.to_s =~ /open/
        str = str.gsub(/#{from}((\&(\w|\d)+\;|\s)+)?/, "#{to} ")
      else
        str = str.gsub(/#{from}/, to)
      end
      str
    end

  end
end
