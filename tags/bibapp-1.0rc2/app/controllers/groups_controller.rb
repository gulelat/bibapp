class GroupsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy, :hide ]
  
  make_resourceful do 
    build :all

    publish :xml, :json, :yaml, :attributes => [
      :id, :name, :url, :description,
       {:people => [:id, :name]}
    ]
    
    #Add a response for RSS
    response_for :show do |format| 
      format.html  #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss   #loads show.rss.rxml
    end
    
    before :index do
      # find first letter of group names (in uppercase, for paging mechanism)
      @a_to_z = Group.letters.collect { |g| g.letter.upcase }
      
      if params[:person_id]
        @person = Person.find_by_id(params[:person_id].split("-")[0])

        # Collect a list of the person's top-level groups for the tree view
        @top_level_groups = Array.new
        @person.memberships.active.collect{|m| m unless m.group.hide?}.each do |m|
          @top_level_groups << m.group.top_level_parent
        end
        @top_level_groups.uniq!
      end
      
      @page = params[:page] || @a_to_z[0]
      @current_objects = Group.find(
        :all, 
        :conditions => ["upper(name) like ? AND hide = ?", "#{@page}%", false], 
        :order => "upper(name)"
      )
    end
    
    before :show do
      search(params)
      @group = @current_object
    end
    
    before :new do
     @groups = Group.find(:all, :order => "name", :conditions => ["hide = ?", false])
    end
   
    
    before :edit do
      #'editor' of group can edit that group
      permit "editor of group"
      
      @groups = Group.find(:all, :order => "name", :conditions => ["hide = ?", false])
    end
  end
  
  def create
    
    @duplicategroup = Group.find(:first, :conditions => ["name LIKE ?", params[:group][:name]])
   
    if @duplicategroup.nil?
      @group = Group.find_or_create_by_name(params[:group])
      @group.hide = false
      @group.save
     
      respond_to do |format|
       flash[:notice] = "Group was successfully created."
       format.html {redirect_to group_url(@group)}
      end
    else
      respond_to do |format|
       flash[:notice] = "This group already exists"
       format.html {redirect_to new_group_path}
      end
    end
  end

  def hidden
    @hidden_groups = Group.find(
      :all,
      :conditions => ["hide = ?", true],
      :order => "upper(name)"
    )
  end
  
  def auto_complete_for_group_name
    group_name = params[:group][:name].downcase
    
    #search at beginning of name
    beginning_search = group_name + "%"
    #search at beginning of any other words in name
    word_search = "% " + group_name + "%"
    
    groups = Group.find(:all, 
          :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
      
    render :partial => 'autocomplete_list', :locals => {:objects => groups}
  end 
  
  def hide
    @group = Group.find(params[:id])
    
    permit "editor on group"
    
    children = @group.children.collect{|c| c unless c.hide?}

    # don't hide groups with children
    if children.blank? 
      @group.hide = true
      @group.save
      respond_to do |format|
        flash[:notice] = "Group was successfully removed."
        format.html {redirect_to :action => "index"}
      end
    else
      respond_to do |format|
        ul = "<ul>"
        children.each do |c|
          ul += "<li>#{c.name}</li>"
        end
        ul += "</ul>"
        flash[:error] = "Group cannot be hidden. It has visible child groups: #{ul}"
        format.html {redirect_to :action => "edit"}
      end
    end
  end

  def unhide
    @group = Group.find(params[:id])

    permit "editor on group"

    parent = @group.parent

    if parent.hide?
      respond_to do |format|
       flash[error] = "Group cannot be unhidden until its parent group is visible. <ul><li>#{parent.name}</li></ul>"
       format.html {redirect_to :action => "edit"}
      end

    end
    @group.hide = false
    @group.save
      respond_to do |format|
       flash[:notice] = "Group was successfully unhidden."
       format.html {redirect_to :action => "index"}
      end
  end
  
  def destroy
    permit "admin"
    
    @group = Group.find(params[:id])

    #check memberships
    memberships = Membership.find_all_by_group_id(@group)

    #check children
    children = @group.children

    if memberships.blank? and children.blank?
      @group.destroy
      respond_to do |format|
       flash[:notice] = "Group was successfully removed."
       format.html {redirect_to groups_path()}
      end
    elsif !memberships.blank?
      respond_to do |format|
       flash[:error] = "Group cannot be deleted. Memberships exist."
       format.html {redirect_to :action => "edit"}
      end
    elsif !children.blank?
      respond_to do |format|
        ul = "<ul>"
        children.each do |c|
          ul += "<li>#{c.name}</li>"
        end
        ul += "</ul>"
        flash[:error] = "Group cannot be deleted. It has visible child groups: #{ul}"
        format.html {redirect_to :action => "edit"}
      end
    end
  end
end