class CitationsController < ApplicationController
  
  caches_page :show, :index, :copyright_analysis
  
  def index
    list
    render :action => 'list'
  end

  before_filter :login_required, :only => [ :edit, :update ]
  before_filter :find_citation, :only => [:edit, :update, :show]
  
  def find_citation
    @citation = Citation.find(params[:id])
  end
  
  def list
    tag = params[:tag]
    @person = Person.find(params[:person_id])
    @citations = Citation.find_all_by_tag_or_person_id(tag, @person.id)
  end

  def show
    @citation = Citation.find(params[:id])

    respond_to do |format|
      format.html { render :action  => "show" }
      format.xml  { render :action => "show.rxml", :layout => false }
    end
  end
  
  def new
    @citation = Citation.new
    @reftypes = Reftype.find(:all)
  end

  def create
    @citation = Citation.new(params[:citation])
    if @citation.save
      flash[:notice] = 'Citation was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @citation = Citation.find(params[:id])
  end

  def toggle
  end

  def update
    @citation = Citation.find(params[:id])
    if @citation.update_attributes(params[:citation])
      flash[:notice] = 'Citation was successfully updated.'
      redirect_to :action => 'show', :id => @citation
    else
      render :action => 'edit'
    end
  end

  def destroy
    Citation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
 
  def copyright_analysis
    @person = Person.find(params[:id])
    @journals = @person.copyright_analysis
    @journals.each{|j| j.romeo_color = "unknown" if !j.romeo_color}
    @journals.each{|j| j.periodical_full = j.title_tertiary if j.periodical_full.nil? or j.periodical_full.empty?}
    
    @green = 0
    @blue = 0
    @yellow = 0
    @white = 0
    @unknown = 0
    @total = 0
    
    @journals.each do |c|
      if c.romeo_color == "green"
        @green += c.count.to_i
      end
      if c.romeo_color == "blue"
        @blue += c.count.to_i
      end
      if c.romeo_color == "yellow"
        @yellow += c.count.to_i
      end
      if c.romeo_color == "white"
        @white += c.count.to_i
      end
      if c.romeo_color == "unknown"  
        @unknown += c.count.to_i
      end     
      @total = @total + c.count.to_i
    end
  end
end