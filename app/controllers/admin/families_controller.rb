# encoding : utf-8
class Admin::FamiliesController < BeautifulController

  before_filter :load_family, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:family] ||= (Family.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:family)
    do_sort_and_paginate(:family)
    
    @q = Family.search(
      params[:q]
    )

    @family_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @family_scope_for_scope = @family_scope.dup
    
    unless params[:scope].blank?
      @family_scope = @family_scope.send(params[:scope])
    end
    
    @families = @family_scope.paginate(
      :page => params[:page],
      :per_page => 20
    ).all

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json{
        render :json => @family_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << Family.attribute_names
          @family_scope.all.each{ |o|
            csv << Family.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @family_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(Family,@family_scope)
        send_data pdfcontent
      }
    end
  end

  def show
    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @family }
    end
  end

  def new
    @family = Family.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @family }
    end
  end

  def edit
    
  end

  def create
    @family = Family.create(params[:family])

    respond_to do |format|
      if @family.save
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_families_path(:mass_inserting => true)
          else
            redirect_to admin_family_path(@family), :notice => t(:create_success, :model => "family")
          end
        }
        format.json { render :json => @family, :status => :created, :location => @family }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_families_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @family.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @family.update_attributes(params[:family])
        format.html { redirect_to admin_family_path(@family), :notice => t(:update_success, :model => "family") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @family.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @family.destroy

    respond_to do |format|
      format.html { redirect_to admin_families_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @families = []    
    
    Family.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:family)

        @families = Family.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @families = Family.find(params[:ids].to_a)
      end

      @families.each{ |family|
        if not Family.columns_hash[attr_or_method].nil? and
               Family.columns_hash[attr_or_method].type == :boolean then
         family.update_attribute(attr_or_method, boolean(value))
         family.save
        else
          case attr_or_method
          # Set here your own batch processing
          # family.save
          when "destroy" then
            family.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = Family
    foreignkey = :family_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_family
    @family = Family.find(params[:id])
  end
end

