class Admin::PublishersController < ApplicationController
  make_resourceful do 
    build :index, :show, :new, :edit, :create, :update

    before :index do
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @current_objects = Publisher.paginate(
          :all, 
          :conditions => ["id = authority_id"], 
          :order => "name",
          :page => params[:page] || 1,
          :per_page => 20
        )
      end
    end
    
    before :show do
      @citations = Citation.paginate(
        :all,
        :conditions => ["publisher_id = ? and citation_state_id = ?", current_object.id, 3],
        :order => "year DESC, title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
        
      @authority_for = Publisher.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )
    end

    before :new, :edit do
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end

    after :update do
      current_object.citations.each do |c|
        c.publisher = current_object.authority
        c.save
      end
    end
  end
  
  def update_multiple
    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]
    update = Publisher.update_multiple(pub_ids, auth_id)
    
    respond_to do |wants|
      wants.html do
        redirect_to :action => 'index', :page => params[:page]
      end
    end
  end

  private
  def current_objects
    if params[:q]
      query = '%' + params[:q] + '%'
    end
    @current_objects ||= current_model.find(:all, :conditions => ["name like ?", query])
  end
end