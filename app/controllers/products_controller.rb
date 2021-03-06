class ProductsController < ApplicationController
  before_action :validate_search_key, only: [:search]
  before_action :authenticate_user!, only: [:favorite]
  def index
    if params[:category].blank?
      @products = case params[:order]
      when 'by_product_price'
            Product.order('price DESC')
      when 'by_product_quantity'
            Product.order('quantity DESC')
      when 'by_product_like'
            Product.order('like DESC')
          else
            Product.order('created_at DESC')
          end
    else
      @category_id = Category.find_by(name: params[:category]).id
      @products = Product.where(:category_id => @category_id)
    end
  end
  def show
    @product = Product.find(params[:id])
    @photos = @product.photos.all
    @posts = @product.posts
    @prints = @product.prints.all
  end
  def search
    if @query_string.present?
      search_result = Product.ransack(@search_criteria).result(:distinct => true)
      @products = search_result.paginate(:page => params[:page], :per_page => 20 )
    else
      redirect_to :back
      flash[:alert] = "搜索内容不得为空！"

    end
  end
  def add_to_cart
    @product = Product.find(params[:id])
    if !current_cart.products.include?(@product)
    current_cart.add_product_to_cart(@product)
    flash[:notice] = "#{@product.title}加入购物车成功"
  else
    flash[:warning] = "不能重复加入商品"
    end
    redirect_to :back

  end
    def favorite
      @product = Product.find(params[:id])
      type = params[:type]
      if type == "favorite"
      current_user.favorite_products << @product
      redirect_to :back
      elsif type == "unfavorite"
      current_user.favorite_products.delete(@product)
      redirect_to :back

      else
      redirect_to :back
      end
  end

    def upvote
      @product = Product.find(params[:id])
      @product.votes.create
      @product.like = @product.votes.count
      @product.save
      redirect_to :back
    end
  protected

  def validate_search_key
    @query_string = params[:q].gsub(/\\|\'|\/|\?/, "") if params[:q].present?
    @search_criteria = search_criteria(@query_string)
  end


  def search_criteria(query_string)
    {  title_or_description_or_price_or_category_cont:  @query_string }
  end
end
