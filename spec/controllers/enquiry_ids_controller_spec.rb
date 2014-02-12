require 'spec_helper'
require 'support/enquiry_builder'

describe EnquiryIdsController do

  include EnquiryBuilder

  before do
    fake_login
  end

  describe "routing" do
    it "should have a route retrieving all enquiry Id and Rev pairs" do
      {:get => "/enquiries-ids"}.should route_to(:controller => "enquiry_ids", :action => "all")
    end
  end

  describe "response" do
    it "should return Id and Rev for each enquiry record" do
      given_an_enquiry.with_id("enquiry-id").with_rev("enquiry-revision-id")
      Enquiry.should_receive(:fetch_all_ids_and_revs).and_return([{"_id" => "enquiry-id", "_rev" => "enquiry-revision-id"}])

      get :all

      response.headers['Content-Type'].should include("application/json")

      enquiry_ids = JSON.parse(response.body)
      enquiry_ids.length.should == 1

      enquiry_id = enquiry_ids[0]
      enquiry_id['_id'].should == "enquiry-id"
      enquiry_id['_rev'].should == "enquiry-revision-id"
    end
  end
end
