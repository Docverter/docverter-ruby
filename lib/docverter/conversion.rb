require 'ostruct'

module Docverter

  class InvalidConversionError < StandardError; end
  
  class Conversion < OpenStruct

    def self.run(from=nil, to=nil, content=nil)
      obj = new(from, to, content)

      if block_given?
        yield obj
      end

      obj.convert
    end

    def initialize(from=nil, to=nil, content=nil)
      super(
        :from => from,
        :to => to,
        :content => content,
        :input_files => [],
        :other_files => [],
      )
    end

    def add_input_file(path)
      self.input_files << File.open(path, "rb")
    end

    def add_other_file(path)
      self.other_files << File.open(path, "rb")
    end

    def to_h
      hash = {}
      self.instance_variable_get(:@table).each do |field,value|
        next if value.nil?
        hash[field] = value
      end

      hash
    end

    def convert

      if input_files.length == 0 && content == nil
        raise InvalidConversionError.new("Cannot convert without an input_file or content")
      end
      
      unless self.content.nil?
        temp = Tempfile.new("temp")
        temp.write self.content
        temp.flush
        self.add_input_file(temp.path)
      end

      Docverter.request(:post, "/convert", self.to_h)
    end
  end
end
