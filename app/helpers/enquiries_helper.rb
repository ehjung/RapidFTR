module EnquiriesHelper

	module View
    	PER_PAGE = 20
    	MAX_PER_PAGE = 9999
  	end

	def enquiry_thumbnail_tag(enquiry, key = nil)
    	image_tag(enquiry_thumbnail_path(enquiry, key || enquiry[:current_photo_key], :ts => enquiry.last_updated_at), :alt=> enquiry['enquirer_name'])
  	end

	def enquiry_link_to_photo_with_key(key)
    	link_to enquiry_thumbnail_tag(@enquiry, key),
      	enquiry_photo_path(@enquiry, key, :ts => @enquiry.last_updated_at),
      	:id => key,
      	:target => '_blank'
  	end

end
