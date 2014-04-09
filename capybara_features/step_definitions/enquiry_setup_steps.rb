def create_user(user_name)
  User.create!("user_name" => user_name,
               "password" => "rapidftr",
               "password_confirmation" => "rapidftr",
               "full_name" => user_name,
               "organisation" => "Moos",
               "disabled" => "false",
               "email" => "rapidftr@rapidftr.com",
               "role_ids" => "ADMIN")
end

Given /^the following enquiries exist in the system:$/ do |enquiry_table|
  enquiry_table.hashes.each do |enquiry_hash|
    enquiry_hash.update(
    	:criteria => {"name" => "sample_name", "location" => "sample_location"}, 
    	"created_by" => "Billy", 
    	"created_organization" => "Moos"
    	)

    user_name = enquiry_hash['created_by']
    if User.find_by_user_name(user_name) == nil
    	create_user(user_name)
    end

    User.find_by_user_name(user_name).
        update_attributes({:organisation => enquiry_hash['created_organisation']}) if enquiry_hash['created_organisation']

    enquiry = Enquiry.new_with_user_name(User.find_by_user_name(user_name), enquiry_hash)
    enquiry.create!
  end
end

