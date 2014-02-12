class EnquiryIdsController < ApplicationController
  def all
    enquiry_json = Enquiry.fetch_all_ids_and_revs
    render :json => enquiry_json
  end
end
