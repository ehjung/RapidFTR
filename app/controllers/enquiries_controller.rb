class EnquiriesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_authentication, :only => [:reindex]

  before_filter :load_enquiry_or_redirect, :only => [ :show, :edit, :destroy, :edit_photo, :update_photo ]
  before_filter :current_user, :except => [:reindex]
  before_filter :sanitise_params

  def reindex
    Child.reindex!
    render :nothing => true
  end

  def index
    authorize! :index, Enquiry

    @record = "enquiries"
    @page_name = t("home.view_records")
    @aside = 'shared/sidebar_links'
    @filter = params[:filter] || params[:status] || "all"
    @order = params[:order_by] || 'enquirer_name'
    per_page = params[:per_page] || EnquiriesHelper::View::PER_PAGE
    per_page = per_page.to_i unless per_page == 'all'

    filter_enquiries per_page   
        
    if !params[:updated_after].nil?
      @enquiries = Enquiry.search_by_match_updated_since(params[:updated_after])
    end

    respond_to do |format|
      format.html
      format.xml { render :xml => @enquiries }
      unless params[:format].nil?
        if @enquiries.empty?
          flash[:notice] = t('enquiry.export_error')
          redirect_to :action => :index and return
        end
      end
      respond_to_export format, @enquiries
    end
  end


  def destroy_all
    authorize! :create, Enquiry
    Enquiry.all.each{|c| c.destroy}
    render :json => ""
  end

  def new
    authorize! :create, Enquiry

    @record = "enquiries"
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
        format.html { redirect_to enquiries_path }
        format.xml { render :xml => @enquiry, :location => @enquiry, :status => :created }
        format.json { render :json => @enquiry.compact.to_json }
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

  def show
    authorize! :show, Enquiry
    @record = "enquiries"
    enquiry = Enquiry.get(params[:id])

    if !enquiry.nil?
      render :json => enquiry
    else
      render :json => "", :status => 404
    end
  end

  def filter_enquiries(per_page)
    total_rows, enquiries = enquiries_by_user_access(@filter, per_page)
    @enquiries = paginated_collection enquiries, total_rows
  end

  def paginated_collection instances, total_rows
    page = params[:page] || 1
    WillPaginate::Collection.create(page, EnquiriesHelper::View::PER_PAGE, total_rows) do |pager|
      pager.replace(instances)
    end
  end

  def enquiries_by_user_access(filter_option, 
    per_page)
    keys = [filter_option]
    options = {:view_name => "by_all_view_#{params[:order_by] || 'enquirer_name'}".to_sym}

    if ['created_at', 'reunited_at', 'flag_at'].include? params[:order_by]
      options.merge!({:descending => true, :startkey => [keys, {}].flatten, :endkey => keys})
    else
      options.merge!({:startkey => keys, :endkey => [keys, {}].flatten})
    end

    Enquiry.fetch_paginated(options, (params[:page] || 1).to_i, per_page)
  end

  def paginated_collection instances, total_rows
    page = params[:page] || 1
    WillPaginate::Collection.create(page, EnquiriesHelper::View::PER_PAGE, total_rows) do |pager|
      pager.replace(instances)
    end
  end

  def search_by_user_access(page_number = 1)
    if can? :view_all, Enquiry
      @results, @full_results = Enquiry.search(@search, page_number)
    else
      @results, @full_results = Enquiry.search_by_created_user(@search, current_user_name, page_number)
    end
  end

  def load_enquiry_or_redirect
    @enquiry = Enquiry.get(params[:id])
    if @enquiry.nil?
      respond_to do |format|
        format.json { render :json => @enquiry.to_json }
        format.html do
          flash[:error] = "Enquiry with the given id is not found"
          redirect_to :action => :index and return
        end
      end
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

  def respond_to_export(format, enquiries)
    RapidftrAddon::ExportTask.active.each do |export_task|
      format.any(export_task.id) do
        authorize! "export_#{export_task.id}".to_sym, Enquiry
        LogEntry.create! :type => LogEntry::TYPE[export_task.id], :user_name => current_user.user_name, :organisation => current_user.organisation, :enquiry_ids => enquiries.collect(&:id)
        results = export_task.new.export(enquiries)
        encrypt_exported_files results, export_filename(enquiries, export_task)
      end
    end
  end

  def export_filename(enquiries, export_task)
    (enquiries.length == 1 ? enquiries.first.short_id : current_user_name) + '_' + export_task.id.to_s + '.zip'
  end
end