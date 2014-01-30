class EnquiriesController < ApplicationController

  before_filter :sanitise_params

  def destroy_all
    authorize! :create, Enquiry
    Enquiry.all.each{|c| c.destroy}
    render :json => ""
  end

  def new
    authorize! :create, Enquiry

    @record = "enquiry"
    @page_name = t("enquiries.register_new_enquiry")
    @child = Child.new
   
    @form_sections = get_form_sections
    respond_to do |format|
      format.html
      format.xml { render :xml => @child }
    end
  end

  def create
    authorize! :create, Enquiry

    unless Enquiry.get(enquiry_json()['id']).nil? then
      render_error("errors.models.enquiry.create_forbidden", 403) and return
    end

    if params[:child].nil?
      @enquiry = Enquiry.new_with_user_name(current_user, params[:enquiry][:criteria])
    else
      @enquiry = Enquiry.new_with_user_name(current_user, params[:child])
    end


    @enquiry[:criteria] = params[:enquiry][:criteria]
    @enquiry[:enquirer_name] = params[:enquiry][:enquirer_name]

    params[:child][:photo] = params[:current_photo_key] unless params[:current_photo_key].nil?
    params[:child] = JSON.parse(params[:child]) if params[:child].is_a?(String)
    @child = params[:child]
    
    unless @enquiry.valid? then
      render :json => {:error => @enquiry.errors.full_messages}, :status => 422 and return
    end

    respond_to do |format|
      if @enquiry.save && @enquiry.valid?
        flash[:notice] = t('enquiry.messages.creation_success')
        format.html { redirect_to(enquiries_path, :status => 201) }
        format.xml { render :xml => @enquiry, :status => :created, :location => @enquiry }
        format.json {
          render :json => @enquiry.compact.to_json, :status => 201
        }
      else
        format.html {
          @form_sections = get_form_sections
          render :action => 'new'
          }
          format.xml { render :xml => @enquiry.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :update, Enquiry
    @enquiry = Enquiry.get(params[:id])
    if @enquiry.nil?
      render_error("errors.models.enquiry.not_found", 404)
      return
    end

    @enquiry.update_from(enquiry_json)

    unless @enquiry.valid? && !enquiry_json['criteria'].nil? && !enquiry_json['criteria'].empty?
      render :json => {:error => @enquiry.errors.full_messages}, :status => 422
      return
    end

    @enquiry.save
    render :json => @enquiry
  end

  def index
    authorize! :index, Enquiry

    @record = "enquiry"
    if params[:updated_after].nil?
      @enquiries = Enquiry.all
    else
      @enquiries = Enquiry.search_by_match_updated_since(params[:updated_after])
    end

  end

  def show
    authorize! :show, Enquiry
    @record = "enquiry"
    enquiry = Enquiry.get (params[:id])
    if !enquiry.nil?
      render :json => enquiry
    else
      render :json => "", :status => 404
    end
  end

  private

  def render_error(message, status_code)
    render :json => {:error => I18n.t(message)}, :status => status_code
  end

  def sanitise_params
    begin
      unless (params[:updated_after]).nil?
        DateTime.parse params[:updated_after]
      end
    rescue
      render :json => "Invalid request", :status => 422
    end
  end

  def enquiry_json
    if params['enquiry'].is_a?(String)
      enquiry = JSON.parse(params['enquiry'])
    else
      enquiry = params['enquiry']
      if params['child'].is_a?(String)
         enquiry['criteria']=JSON.parse(params['child'])
      elsif !params['child'].nil?
        enquiry['criteria']=params['child']
      end
    end
    enquiry
  end

  def get_form_sections
    FormSection.enabled_by_order
  end
end