require "spec_helper"

def inject_export_generator( fake_export_generator, enquiry_data )
  ExportGenerator.stub!(:new).with(enquiry_data).and_return( fake_export_generator )
end

def stub_out_export_generator enquiry_data = []
  inject_export_generator( stub_export_generator = stub(ExportGenerator) , enquiry_data)
  stub_export_generator.stub!(:enquiry_photos).and_return('')
  stub_export_generator
end

def stub_out_enquiry_get(mock_enquiry = mock(Enquiry))
  Enquiry.stub(:get).and_return( mock_enquiry )
  mock_enquiry
end

describe EnquiriesController do

  before :each do
    Enquiry.all.each{|enquiry| enquiry.destroy}
    fake_admin_login
  end

  def mock_enquiry(stubs={})
    @mock_enquiry ||= mock_model(Enquiry, stubs).as_null_object
  end


  describe "#authorizations" do
    it "should fail to POST create when unauthorized" do
      @controller.current_ability.should_receive(:can?).with(:create, Enquiry).and_return(false)
      post :create 
      response.should be_forbidden
    end

    it "should fail to update when unauthorized" do
      @controller.current_ability.should_receive(:can?).with(:update, Enquiry).and_return(false)
      test_id = "12345"
      put :update, :id => test_id, :enquiry => {:id => test_id, :enquirer_name => "new name"}
      response.should be_forbidden
    end
  end

  describe "POST create" do

    it "should trigger the match functionality every time a record is created" do
      controller.stub(:authorize!)
      name = 'reporter'
      details = {"location" => "Kampala"}
      criteria = {"name" => "Magso"}

      post :create, :enquiry => {:enquirer_name => name, :reporter_details => details, :criteria => criteria}, :format => :json
    end

    it "should not trigger the match unless record is created" do
      controller.stub(:authorize!)
      name = 'reporter'
      details = {"location" => "Kampala"}

      Enquiry.should_not_receive(:find_matching_children)

      post :create, :enquiry => {:enquirer_name => name, :reporter_details => details}, :format => :json

      response.response_code.should == 422
    end

    it "should create the enquiry record and return a success code" do
      controller.stub(:authorize!)
      name = "reporter"

      details = {"location" => "Kampala"}

      post :create, :enquiry => {:enquirer_name => name, :reporter_details => details, :criteria => {:name => "name"}}

      Enquiry.all.size.should == 1
      enquiry = Enquiry.all.first

      enquiry.enquirer_name.should == name
      enquiry.should respond_to(:save)
      enquiry.save should_not be_false
    end

    it "should not create enquiry without criteria" do
      controller.stub(:authorize!)
      post :create, :enquiry => {:enquirer_name => "new name", :reporter_details => {"location" => "kampala"}}
      response.response_code.should == 422
      JSON.parse(response.body)["error"].should include("Please add criteria to your enquiry")
    end

    it "should not create enquiry with empty criteria" do
      controller.stub(:authorize!)
      post :create, :enquiry => {:enquirer_name => "new name", :criteria => {}}
      response.response_code.should == 422
      JSON.parse(response.body)["error"].should include("Please add criteria to your enquiry")
    end

    it "should not update record if it exists and return error" do
      enquiry = Enquiry.new({:enquirer_name => "old name", :reporter_details => {"location" => "kampala"}, :criteria => {:name => "name"}})
      enquiry.save!
      controller.stub(:authorize!)

      post :create, :enquiry => {'id' => enquiry.id, :enquirer_name => "new name", :criteria => {:name => "name"}}

      enquiry = Enquiry.get(enquiry.id)
      enquiry.enquirer_name.should == "old name"
      response.should be_forbidden
      JSON.parse(response.body)["error"].should == "Forbidden"
    end


  end

  describe "PUT update" do


    before :all do
      form = FormSection.new(:name => "test_form")
      form.fields << Field.new(:name => "name", :type => Field::TEXT_FIELD, :display_name => "name")
      form.fields << Field.new(:name => "sex", :type => Field::TEXT_FIELD, :display_name => "sex")
      form.save!
    end

    after :all do
      FormSection.all.each { |form| form.destroy }
    end

    it 'should not update record when criteria is empty' do
      enquiry = Enquiry.create({:enquirer_name => 'Someone', :criteria => {'name' => 'child name'}})
      controller.stub(:authorize!)

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :criteria => {}}, :format => :json

      response.response_code.should == 422
    end

    it 'should not update record when criteria is nil' do
      enquiry = Enquiry.create({:enquirer_name => 'Someone', :criteria => {'name' => 'child name'}})
      controller.stub(:authorize!)

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :criteria => nil}, :format => :json

      response.response_code.should == 422
    end

    it 'should not update record when there is no criteria' do
      enquiry = Enquiry.create({:enquirer_name => 'Someone', :criteria => {'name' => 'child name'}})
      controller.stub(:authorize!)

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id}, :format => :json

      response.response_code.should == 422
    end


    it "should trigger the match functionality every time a record is created" do
      criteria = {"name" => "old name"}
      enquiry = Enquiry.create({:enquirer_name => "Machaba", :reporter_details => {"location" => "kampala"}, :criteria => criteria})
      controller.stub(:authorize!)

      Enquiry.should_not_receive(:find_matching_children)

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :enquirer_name => 'new name', :criteria => criteria}, :format => :json

      response.response_code.should == 200
    end

    it "should not trigger the match unless record is created" do
      criteria = {"name" => "old name"}
      enquiry = Enquiry.create({:enquirer_name => "Machaba", :reporter_details => {"location" => "kampala"}, :criteria => criteria})
      controller.stub(:authorize!)

      Enquiry.should_not_receive(:find_matching_children)

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :enquirer_name => ''}, :format => :json

      response.response_code.should == 422
    end

    it "should return an error if enquiry does not exist" do
      controller.stub(:authorize!)
      id = "12345"
      Enquiry.stub!(:get).with(id).and_return(nil)

      put :update, :id => id, :enquiry => {:id => id, :enquirer_name => "new name"}

      response.response_code.should == 404
      JSON.parse(response.body)["error"].should == "Not found"
    end

    it "should merge existing criteria when sending new values in criteria" do
      controller.stub(:authorize!)
      details = {"location" => "kampala"}
      enquiry = Enquiry.new({:enquirer_name => "old name", :reporter_details => details, :criteria => {"name" => "Batman"}})
      enquiry.save!

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :enquirer_name => "new name", :criteria => {"gender" => "Male"}, :reporter_details => {}}

      response.response_code.should == 200
      Enquiry.get(enquiry.id)[:criteria].should == {"name" => "Batman", "gender" => "Male"}
      Enquiry.get(enquiry.id)[:reporter_details].should == details
      JSON.parse(response.body)["error"].should be_nil
    end


    it "should update record if it exists and return the updated record" do
      controller.stub(:authorize!)
      criteria = {:name => "name"}
      enquiry = Enquiry.create({:enquirer_name => "old name", :criteria => criteria})

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :enquirer_name => "new name", :criteria => criteria}

      enquiry = Enquiry.get(enquiry.id)

      enquiry.enquirer_name.should == "new name"
      response.response_code.should == 200
      JSON.parse(response.body).should == enquiry
    end

    it "should update record without passing the id in the enquiry params" do
      controller.stub(:authorize!)
      criteria = {:name => "name"}
      enquiry = Enquiry.create({:enquirer_name => "old name", :reporter_details => {"location" => "kampala"}, :criteria => criteria})

      put :update, :id => enquiry.id, :enquiry => {:enquirer_name => "new name", :criteria => criteria}

      enquiry = Enquiry.get(enquiry.id)
      enquiry.enquirer_name.should == "new name"
      response.response_code.should == 200
      JSON.parse(response.body).should == enquiry
    end

    it "should merge updated fields and return the latest record" do
      controller.stub(:authorize!)
      enquiry = Enquiry.create({:enquirer_name => "old name", :reporter_details => {"location" => "kampala"}, :criteria => {:name => "child name"}})

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :criteria => {:name => "child new name"}} 

      enquiry = Enquiry.get(enquiry.id)
      enquiry.criteria.should == {"name" => "child new name"}

      put :update, :id => enquiry.id, :enquiry => {:id => enquiry.id, :location => "Kampala", :reporter_details => {"age" => "100"}, :criteria => {:sex => "female"}} 

      enquiry = Enquiry.get(enquiry.id)


      enquiry.criteria.should == {"name" => "child new name", "sex" => "female"}
      enquiry["reporter_details"].should == {"location" => "kampala", "age" => "100"}
      enquiry["location"].should == "Kampala"
      response.response_code.should == 200
      JSON.parse(response.body).should == enquiry
    end

    it "should update existing enquiry with potential matches" do
      controller.stub(:authorize!)
      child1 = Child.create('name' => "Clayton aquiles", 'created_by' => 'fakeadmin', 'created_organisation' => "stc")
      child2 = Child.create('name' => "Steven aquiles", 'sex' => 'male', 'created_by' => 'fakeadmin', 'created_organisation' => "stc")

      enquiry_json = "{\"enquirer_name\": \"Godwin\",\"criteria\": {\"sex\": \"male\",\"age\": \"10\",\"location\": \"Kampala\"  }}"
      enquiry = Enquiry.new(JSON.parse(enquiry_json))
      enquiry.save!

      Enquiry.get(enquiry.id)['potential_matches'].should == [child2.id]

      updated_enquiry = "{\"criteria\": {\"name\": \"aquiles\", \"age\": \"10\", \"location\": \"Kampala\"}}"

      put :update, :id => enquiry.id, :enquiry => updated_enquiry

      response.response_code.should == 200

      enquiry_after_update = Enquiry.get(enquiry.id)
      enquiry_after_update['potential_matches'].size.should == 2
      enquiry_after_update['potential_matches'].include?(child1.id).should == true
      enquiry_after_update['potential_matches'].include?(child2.id).should == true
      #enquiry_after_update['potential_matches'].size.should == [child2.id,child1.id]
      enquiry_after_update['criteria'].should == {"name" => "aquiles", "age" => "10", "location" => "Kampala"}
    end

  end

  describe "GET index" do

    describe "when the signed in user has access all data" do
      before do
        fake_field_admin_login
        @options ||= {}
        @stubs ||= {}
      end

      it "should assign all enquiries as @enquiries" do
        page = @options.delete(:page)
        per_page = @options.delete(:per_page)
        enquiries = [mock_enquiry(@stubs)]
        @status ||= "all"

        enquiries.stub!(:paginate).and_return(enquiries)
        enquiries.stub!(:fetch_paginated).with(@options, page, per_page).and_return([1, enquiries])

        #Enquiry.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, enquiries])
        get :index, :status => @status
       # assigns(:enquiries).should == enquiries

      end
    end
=begin
    it "should fetch all the enquiries" do
      @stubs = { :reunited? => false }
      @options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}

      controller.stub(:authorize!)

      User.stub!(:find_by_user_name).with("uname").and_return(user = mock('user', :user_name => 'uname', :organisation => 'org'))
      enquiry = Enquiry.new_with_user_name(user, {enquirer_name: "Mulan", criteria: {name: "Fatty"}})
      enquiry.save should_not be_false

      page = @options.delete(:page)
      per_page = @options.delete(:per_page)
      enquiries = [mock_enquiry(@stubs)]
      @status ||= "all"

      enquiries.stub!(:paginate).and_return(enquiries)
      Enquiry.fetch_paginated(@options, page, per_page)
      #Enquiry.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, enquiries])
      get :index, :status => @status
      response.response_code.should == 200
    end
=end
    describe "when the signed in user is a field worker" do
      before do
        @session = fake_field_worker_login
        @stubs ||= {}
        @options ||= {}
        @params ||= {}
      end

      it "should return enquiries with new matches when passed query parameter with last update timestamp" do
        controller.stub(:authorize!)

        enquiry = Enquiry.new({:_id => "123"})
        Enquiry.should_receive(:search_by_match_updated_since).with('2013-09-18 06:42:12UTC').and_return([enquiry])

        get :index, :updated_after => '2013-09-18 06:42:12UTC' 

        response.response_code.should == 200
      end

      it "should return 422 if query parameter with last update timestamp is not a valid timestamp" do
        controller.stub(:authorize!)
        bypass_rescue
        get :index, :updated_after => 'adsflkj' 

        response.response_code.should == 422
      end
    end

  end

  describe "GET show" do
    it "should fetch a particular enquiry" do
      controller.stub(:authorize!)

      Enquiry.should_receive(:get).with("123").and_return(mock(:to_json => "an enquiry record"))

      get :show, :id => "123" 
      response.response_code.should == 200
      response.body.should == "an enquiry record"
    end

    it "should return a 404 with empty body if enquiry record does not exist" do
      controller.stub(:authorize!)

      Enquiry.should_receive(:get).with("123").and_return(nil)

      get :show, :id => "123" 

      response.body.should == ""
      response.response_code.should == 404
    end

  end

  describe "DELETE destroy_all" do
    it 'should not remove all enquires when env is not android' do
      stub_env('production') do
        delete :destroy_all
        response.body.should == "Unauthorized Operation"
        response.response_code.should == 401
      end

      stub_env('test') do
        delete :destroy_all
        response.body.should == "Unauthorized Operation"
        response.response_code.should == 401
      end
    end

    it 'should delete all enquiry records when env is android' do
      stub_env('android') do
        @controller.current_ability.should_receive(:can?).with(:create, Enquiry).and_return(true)
        delete :destroy_all
        response.body.should == ""
        response.response_code.should == 200
      end
    end
  end

  
end
