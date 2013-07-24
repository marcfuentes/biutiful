# encoding : utf-8
class Admin::ProductsController < BeautifulController

  before_filter :load_product, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:product] ||= (Product.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:product)
    do_sort_and_paginate(:product)
    
    @q = Product.search(
      params[:q]
    )

    @product_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @product_scope_for_scope = @product_scope.dup
    
    unless params[:scope].blank?
      @product_scope = @product_scope.send(params[:scope])
    end
    
    @products = @product_scope.paginate(
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
        render :json => @product_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << Product.attribute_names
          @product_scope.all.each{ |o|
            csv << Product.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @product_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(Product,@product_scope)
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
      format.json { render :json => @product }
    end
  end

  def new
    @product = Product.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @product }
    end
  end

  def edit
    
  end

  def create
    @product = Product.create(params[:product])

    respond_to do |format|
      if @product.save
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_products_path(:mass_inserting => true)
          else
            redirect_to admin_product_path(@product), :notice => t(:create_success, :model => "product")
          end
        }
        format.json { render :json => @product, :status => :created, :location => @product }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to admin_products_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.html { redirect_to admin_product_path(@product), :notice => t(:update_success, :model => "product") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @product.destroy

    respond_to do |format|
      format.html { redirect_to admin_products_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @products = []    
    
    Product.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:product)

        @products = Product.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @products = Product.find(params[:ids].to_a)
      end

      @products.each{ |product|
        if not Product.columns_hash[attr_or_method].nil? and
               Product.columns_hash[attr_or_method].type == :boolean then
         product.update_attribute(attr_or_method, boolean(value))
         product.save
        else
          case attr_or_method
          # Set here your own batch processing
          # product.save
          when "destroy" then
            product.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = Product
    foreignkey = :product_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_product
    @product = Product.find(params[:id])
  end
end

