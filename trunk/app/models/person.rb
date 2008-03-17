class Person < ActiveRecord::Base
  has_many :name_strings, :through => :pen_names
  has_many :pen_names
  has_many :groups, :through => :memberships
  has_many :memberships
  has_many :citations, :through => :authorships
  has_many :authorships

  def first_last
    "#{first_name} #{last_name}"
  end
  
  def to_param
    param_name = first_last.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  

  def groups_not
    all_groups = Group.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end
  
  def name_strings_not
    all_name_strings = NameString.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_name_strings - name_strings
  end
end