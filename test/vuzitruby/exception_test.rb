
require File.dirname(__FILE__) + '/../abstract_unit'

class ExceptionTest < Test::Unit::TestCase

  # Tests

  def test_bad_api_key
    Vuzit::Service.public_key = 'does_not_exist'
    Vuzit::Service.private_key = 'does_not_matter'
    
    begin
      # TODO: Switch to a find query
      doc = Vuzit::Document.destroy('5')
    rescue Vuzit::Exception => ex
      assert_equal 414, ex.code
      assert_equal "The public API key is missing or invalid.", ex.message
    end
  end

  def test_invalid_signature
    # TODO: Switch to a key that is not yours
    Vuzit::Service.public_key = @public_key
    Vuzit::Service.private_key = 'invalid_key'
    
    begin
      # TODO: Switch to a find query
      doc = Vuzit::Document.destroy("5")
    rescue Vuzit::Exception => ex
      assert_equal 412, ex.code
      assert_equal "Access is denied.  Invalid signature", ex.message
    end
  end

  def test_destroy_document_does_not_exist
    # TODO: Switch to a key that is not yours
    Vuzit::Service.public_key = @public_key
    Vuzit::Service.private_key = @private_key
    begin
      doc = Vuzit::Document.destroy('does_not_exist')
    rescue Vuzit::Exception => ex
      assert_equal 422, ex.code
      assert_equal "Document not found", ex.message
    end
  end

  # Helper methods
  def setup
    @public_key = 'b12c30a5-77aa-ef5f-9b4f-b83a4f88149e' 
    @private_key = nil

    if @private_key == nil
      raise Exception.new("You must set @private_key in setup() method") 
    end
  end

end

