class Enquiry < CouchRestRails::Document
  use_database :enquiry
  include RapidFTR::Model
  include RecordHelper
  include CouchRest::Validation
  include PhotoHelper
  include AttachmentHelper
  include AudioHelper
  include Searchable

  before_save :update_photo_keys
  before_save :find_matching_children, :is_criteria_empty

  property :enquirer_name
  property :criteria
  property :potential_matches, :default => []
  property :match_updated_at, :default => ""

  Sunspot::Adapters::InstanceAdapter.register(DocumentInstanceAccessor, Enquiry)
  Sunspot::Adapters::DataAccessor.register(DocumentDataAccessor, Enquiry)


  validates_presence_of :enquirer_name, :message => I18n.t("errors.models.enquiry.presence_of_enquirer_name")

  validates_with_method :criteria, :method => :is_criteria_empty

  def initialize *args
    self['photo_keys'] ||= []
    arguments = args.first

    if arguments.is_a?(Hash) && arguments["current_photo_key"]
      self['current_photo_key'] = arguments["current_photo_key"]
      arguments.delete("current_photo_key")
    end

    self['histories'] = []
    super *args
  end


  def is_criteria_empty
    return [false, I18n.t("errors.models.enquiry.presence_of_criteria")] if (criteria.nil? || criteria.empty? || criteria.blank?)
    criteria.values.each do |value|
        i = 0
        while i < criteria.values.count 
          if !value[i].nil?
            return true 
          end
          i = i + 1
        end
    end
  end 

  def self.new_with_user_name (user, *args)
    enquiry = new *args
    enquiry.set_creation_fields_for(user)
    enquiry.create_unique_id
    enquiry
  end

  def update_from(properties)
    properties.each_pair do |name, value|
      if value.instance_of? HashWithIndifferentAccess
        self[name] = self[name].merge!(value)
      else
        self[name] = value
      end
    end
  end

  def find_matching_children
    previous_matches = self.potential_matches
    children = MatchService.search_for_matching_children(self.criteria)
    self.potential_matches = children.map { |child| child.id }
    verify_format_of(previous_matches)

    unless previous_matches.eql?(self.potential_matches)
      self.match_updated_at = Clock.now.to_s
    end
  end

  def self.search_by_match_updated_since(timestamp)
    Enquiry.all.keep_if { |e|
      !e['match_updated_at'].empty? and DateTime.parse(e['match_updated_at']) >= timestamp
    }
  end

  def create_unique_id
    self['unique_identifier'] ||= UUIDTools::UUID.random_create.to_s
  end

  def compact
    self['current_photo_key'] = '' if self['current_photo_key'].nil?
    self
  end

  private

  def verify_format_of(previous_matches)
    unless previous_matches.is_a?(Array)
      previous_matches = JSON.parse(previous_matches)
    end
    previous_matches
  end


end
