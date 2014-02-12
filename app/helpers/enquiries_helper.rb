module EnquiriesHelper

	module View
    	PER_PAGE = 20
    	MAX_PER_PAGE = 9999
  end

  ORDER_BY = {'active' => 'created_at', 'all' => 'created_at', 'reunited' => 'reunited_at', 'flag' => 'flag_at'}

	def enquiry_thumbnail_tag(enquiry, key = nil)
    	image_tag(enquiry_thumbnail_path(enquiry, key || enquiry[:current_photo_key], :ts => enquiry.last_updated_at), :alt=> enquiry['enquirer_name'])
  	end

	def enquiry_link_to_photo_with_key(key)
    	link_to enquiry_thumbnail_tag(@enquiry, key),
      enquiry_photo_path(@enquiry, key, :ts => @enquiry.last_updated_at),
      :id => key,
      :target => '_blank'
  end

  def link_for_filter filter, selected_filter
    return filter.capitalize if filter == selected_filter
    link_to(filter.capitalize, enquiry_filter_path(filter))
  end

  def link_for_order_by filter, order, order_id, selected_order
    return order_id.capitalize if order == selected_order
    link_to(order_id.capitalize, enquiry_filter_path(:filter => filter, :order_by => order))
  end

end
