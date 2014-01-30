class Api::EnquiryMediaController < Api::ApiController
  before_filter :find_enquiry

  def show_photo
    params[:photo_id] = @enquiry.current_photo_key || "_missing_" if params[:photo_id].blank?
    find_photo_attachment
    send_photo_data(@attachment.data.read, :type => @attachment.content_type, :disposition => 'inline')
  end

  def download_audio
    find_audio_attachment
    redirect_to( :controller => 'enquiries', :action => 'show', :id => @enquiry.id) and return unless @attachment
    send_data( @attachment.data.read, :filename => audio_filename(@attachment), :type => @attachment.content_type )
  end

  private

    def find_enquiry
      @enquiry = Enquiry.get params[:id]
    end

    def find_audio_attachment
      begin
        @attachment = params[:audio_id] ? @enquiry.media_for_key(params[:audio_id]) : @enquiry.audio
      rescue => e
        p e.inspect
      end
    end

    def find_photo_attachment
      redirect_to(:photo_id => @enquiry.current_photo_key, :ts => @enquiry.last_updated_at) and return if
        params[:photo_id].to_s.empty? and @enquiry.current_photo_key.present?

      begin
        @attachment = params[:photo_id] == '_missing_' ? no_photo_attachment : @enquiry.media_for_key(params[:photo_id])
      rescue => e
        logger.warn "Error getting photo"
        logger.warn e.inspect
      end
    end

    def no_photo_attachment
      @@no_photo_clip ||= File.binread(File.join(Rails.root, "app/assets/images/no_photo_clip.jpg"))
      FileAttachment.new("no_photo", "image/jpg", @@no_photo_clip)
    end

    def audio_filename attachment
      "audio_" + @enquiry.unique_identifier + AudioMimeTypes.to_file_extension(attachment.mime_type)
    end

    def send_photo_data(*args)
      expires_in 1.year, :public => true if params[:ts]
      send_data *args
    end

end
