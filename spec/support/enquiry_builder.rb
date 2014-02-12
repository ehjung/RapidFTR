module EnquiryBuilder

  def given_an_enquiry
    @enquiry = mock(:enquiry)
    self
  end

  def with_id(enquiry_id)
    Child.stub!(:get).with(enquiry_id).and_return @enquiry
    Child.stub!(:all).and_return [@enquiry]
    @enquiry.stub!(:id).and_return enquiry_id
    @enquiry.stub!(:last_updated_at).and_return(Date.today)
    self
  end

  def with_unique_identifier(identifier)
    @enquiry.stub!(:unique_identifier).and_return identifier
    self
  end

  def with_photo(image, image_id = "img", current = true)
    photo = FileAttachment.new image_id, image.content_type, image.data

    @enquiry.stub!(:media_for_key).with(image_id).and_return photo
    @enquiry.stub!(:current_photo_key).and_return(image_id) if current
    @enquiry.stub!(:primary_photo).and_return photo if current
    self
  end

  def with_audio(audio, audio_id ="audio", current = true)
    audio = mock(FileAttachment, {:content_type => audio.content_type, :mime_type => audio.mime_type, :data => StringIO.new(audio.data) })
    @enquiry.stub!(:media_for_key).with(audio_id).and_return audio
    @enquiry.stub!(:audio).and_return audio if current
  end

  def with_no_photos
    @enquiry.stub!(:current_photo_key).and_return nil
    @enquiry.stub!(:media_for_key).and_return nil
    @enquiry.stub!(:primary_photo).and_return nil
    self
  end

  def with_rev(revision)
    @enquiry.stub!(:rev).and_return revision
    self
  end

  def with(hash)
    hash.each do |(key, value)|
      @enquiry.stub!(key).and_return(value)
    end
    self
  end

end
