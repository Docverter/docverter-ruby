require File.expand_path("../test_helper", __FILE__)

class TestDocverter < Test::Unit::TestCase

  def setup
    Docverter.reset
    @mock = mock
    Docverter.mock_rest_client = @mock
    Docverter.api_key = "test_key"
  end

  should "set api key" do
    Docverter.api_key = "key"
    assert_equal "key", Docverter.api_key
  end

  should "raise if no api key given" do
    Docverter.api_key = nil
    assert_raises(Docverter::AuthenticationError) do
      Docverter.api_url
    end
  end

  should "not raise if no api key given and base url changed" do
    Docverter.api_key = nil
    Docverter.base_url = 'http://localhost:9595/convert'
    assert_nothing_raised do
      Docverter.api_url
    end
  end

  should "have default base url" do
    assert_equal "https://test_key:@api.docverter.com/v1", Docverter.api_url
  end

  should "override base url" do
    Docverter.base_url = "http://localhost:5000/v1"
    assert_equal "http://test_key:@localhost:5000/v1", Docverter.api_url
  end
  
  context "Conversion" do
    should "initialize with from, to, and content" do
      conversion = Docverter::Conversion.new('markdown', 'html', 'content')
      assert_equal "markdown", conversion.from
      assert_equal "html", conversion.to
      assert_equal "content", conversion.content
      assert_equal [], conversion.input_files
      assert_equal [], conversion.other_files
    end

    should "add an input file from a path" do

      temp = Tempfile.new("foo")

      conversion = Docverter::Conversion.new
      conversion.add_input_file(temp.path)

      assert_equal conversion.input_files[0].path, temp.path
    end

    should "add an other file from a path" do
      temp = Tempfile.new("foo")

      conversion = Docverter::Conversion.new
      conversion.add_other_file(temp.path)

      assert_equal conversion.other_files[0].path, temp.path
    end

    should "to_h" do
      conversion = Docverter::Conversion.new("markdown", "pdf")

      h = {
        :from => "markdown",
        :to => "pdf",
        :input_files => [],
        :other_files => [],
      }
      
      assert_equal h, conversion.to_h
    end

    should "make request" do
      temp = Tempfile.new("foo")

      @mock.expects(:post).with do |url, blah, params|
        url == "https://test_key:@api.docverter.com/v1/convert" \
        && params[:from] == 'markdown' \
        && params[:to] == 'pdf' \
        && params[:other_files] == [] \
        && params[:input_files][0].path == temp.path
      end.returns(test_response("blah"))

      res = Docverter::Conversion.run do |c|
        c.from = "markdown"
        c.to = "pdf"
        c.add_input_file(temp.path)
      end


      assert_equal "blah", res
    end

    should "make request with content" do
      @mock.expects(:post).with do |url, blah, params|
        url == "https://test_key:@api.docverter.com/v1/convert" \
        && params[:from] == 'markdown' \
        && params[:to] == 'pdf' \
        && params[:other_files] == [] \
        && params[:input_files][0].read == "Some Content"
      end.returns(test_response("Some Content"))

      res = Docverter::Conversion.run do |c|
        c.from = "markdown"
        c.to = "pdf"
        c.content = "Some Content"
      end

      assert_equal "Some Content", res
    end

    should "make request with no input_files or content raises" do

      assert_raises(Docverter::InvalidConversionError) do
        Docverter::Conversion.run do |c|
          c.from = "markdown"
          c.to = "pdf"
        end
      end
    end

    should "make async request" do
      temp = Tempfile.new("foo")

      @mock.expects(:post).with do |url, blah, params|
        url == "https://test_key:@api.docverter.com/v1/convert" \
        && params[:from] == 'markdown' \
        && params[:to] == 'pdf' \
        && params[:other_files] == [] \
        && params[:input_files][0].path == temp.path \
        && params[:callback_url] == 'http://www.google.com'
      end.returns(test_response('{"status": "pending", "id": 123}'))

      res = Docverter::Conversion.run do |c|
        c.from = "markdown"
        c.to = "pdf"
        c.callback_url = 'http://www.google.com'
        c.add_input_file(temp.path)

      end

      expected = {'id' => 123, 'status' => 'pending'}

      assert_equal expected, res
    end

    should "pickup" do
      @mock.expects(:get).with("https://test_key:@api.docverter.com/v1/pickup/1", nil, {}).returns(test_response("foo"))
      res = Docverter::Conversion.pickup(1)
      assert_equal "foo", res
    end

    should "status" do
      @mock.expects(:get).with("https://test_key:@api.docverter.com/v1/status/1", nil, {}).returns(test_response('{"status": "pending", "id": 1}'))
      res = Docverter::Conversion.status(1)
      expected = {"status" => "pending", "id" => 1}
      assert_equal expected, res
    end

  end

end
