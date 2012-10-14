require 'ostruct'

module Docverter

  # Public: An invalid conversion has been specified
  class InvalidConversionError < StandardError; end

  # Public: Convert documents using Docverter
  #
  # Examples
  #
  #    Docverter::Conversion.run("markdown", "html", "Some Content")
  #    # => "<html><body><p>Some Content</p></body></html>"
  #
  #    Docverter::Conversion.run do |c|
  #      c.from    = "markdown"
  #      c.to      = "html"
  #      c.content = "Some Content"
  #      c.stylesheet = "stylesheet.css"
  #      c.add_other_file "stylesheet.css"
  #    end
  #    # => '<html><head><link rel="stylesheet" media="print" href="stylesheet.css"></head><body><p>Some Content</p></body></html>'
  #
  class Conversion < OpenStruct

    # Public: Run a conversion on Docverter
    #
    # from    - The format of the input text (optional)
    # to      - The format of the output document (optional)
    # content - The content to be converted (optional)
    #
    # Yields the initialized Conversion object
    #
    # Returns the converted document or a status hash if a callback_url has been specified
    #
    # Examples
    #
    #    Docverter::Conversion.run("markdown", "pdf", "Some Content")
    #
    #    Docverter::Conversion.run do |c|
    #      c.from = "markdown"
    #      c.to   = "pdf"
    #      c.add_input_file("input.md")
    #      c.stylesheet = "stylesheet.css"
    #      c.add_other_file "stylesheet.css"
    #    end
    def self.run(from=nil, to=nil, content=nil)
      obj = new(from, to, content)

      if block_given?
        yield obj
      end

      obj.convert
    end

    # Public: Get the status of a particular conversion
    #
    # id - The integer ID of a conversion as given by Docverter::Conversion#run in async mode
    #
    # Returns a status hash
    def self.status(id)
      OkJson.decode(Docverter.request(:get, "/status/#{id.to_i}"))
    end

    # Public: Pick up the converted document for a particular conversion
    #
    # id - The integer ID of a conversion as given by Docverter::Conversion#run in async mode
    #
    # Returns the converted document
    def self.pickup(id)
      Docverter.request(:get, "/pickup/#{id.to_i}")
    end

    # Public: Run a conversion on Docverter
    #
    # from    - The format of the input text (optional)
    # to      - The format of the output document (optional)
    # content - The content to be converted (optional)
    #
    # Can accept a block that will be passed the initialized Conversion object to allow
    # more settings to be set before the conversion is run
    #
    # Returns a new Conversion object
    def initialize(from=nil, to=nil, content=nil)
      super(
        :from => from,
        :to => to,
        :content => content,
        :input_files => [],
        :other_files => [],
      )
    end

    # Public: Add an input file to the conversion
    #
    # path - The path to the file to add as an input file
    def add_input_file(path)
      self.input_files << File.open(path, "rb")
    end

    # Public: Add another file to the conversion
    #
    # path - The path to the file to add
    def add_other_file(path)
      self.other_files << File.open(path, "rb")
    end

    # Public: Run the conversion through Docverter
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

      response = Docverter.request(:post, "/convert", self.to_h)
      if self.callback_url
        OkJson.decode(response)
      else
        response
      end
    end

    # Internal: Convert this conversion into a hash
    def to_h
      hash = {}
      self.instance_variable_get(:@table).each do |field,value|
        next if value.nil?
        hash[field] = value
      end

      hash
    end
  end
end
