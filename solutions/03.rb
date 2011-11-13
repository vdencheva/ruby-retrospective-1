require 'bigdecimal'
require 'bigdecimal/util'

module Discount
  def self.create(options)
    if options[:get_one_free]
      GetOneFreeDiscount.new options[:get_one_free]
    elsif options[:package]
      PackageDiscount.new options[:package]
    elsif options[:threshold]
      ThresholdDiscount.new options[:threshold]
    else
      NoDiscount.new
    end
  end
  
  class GetOneFreeDiscount
    def initialize(discount)
      @get_one_free = discount
    end
    
    def calculate_discount(product_price, quantity)
      (quantity / @get_one_free) * product_price
    end
    
    def print_name
      "  (buy #{@get_one_free - 1}, get 1 free)"
    end
  end
  
  class PackageDiscount
    def initialize(discount)
      @size = discount.keys[0]
      @percent = discount.values[0]
    end
    
    def calculate_discount(product_price, quantity)
      packages = quantity / @size
      product_discount = product_price * @percent / 100
      package_discount = @size * product_discount
      packages * package_discount
    end
    
    def print_name
      "  (get %d%% off for every %s)" % [@percent, @size]
    end
  end
  
  class ThresholdDiscount
    def initialize(discount)
      @amount = discount.keys[0]
      @percent = discount.values[0]
    end
    
    def calculate_discount(product_price, quantity)
      above_threshold = quantity - @amount
      if above_threshold > 0
        product_discount = product_price * @percent / 100
        above_threshold * product_discount
      else
        0
      end
    end
    
    def print_name
      "  (%2.f%% off of every after the %s)" % [@percent, amount_words]
    end

    def amount_words
      if (@amount == 1)
        "1st"
      elsif (@amount == 2)
        "2nd"
      elsif (@amount == 3)
        "3rd"
      else
        "#{@amount}th"
      end
    end
  end
  
  class NoDiscount
    def calculate_discount(*args)
      0
    end
    
    def print_name(*args)
      ""
    end
  end
end

module Coupon
  def self.create(name, options)
    if options[:amount]
      AmountCoupon.new(name, options[:amount])
    elsif options[:percent]
      PercentCoupon.new(name, options[:percent])
    else
      NoCoupon.new
    end
  end

  class AmountCoupon
    attr_reader :name
    def initialize(coupon_name, discount)
      @name = coupon_name
      @amount = discount.to_d
    end
    
    def calculate_discount(order_price)
      [@amount, order_price].min
    end
    
    def print_name
      "Coupon %s - %.2f off" % [@name, @amount]
    end
  end
  
  class PercentCoupon
    attr_reader :name
    def initialize(coupon_name, percent)
      @name = coupon_name
      @percent = percent
    end
    
    def calculate_discount(order_price)
      order_price * @percent / 100
    end
    
    def print_name
      "Coupon %s - %d%% off" % [@name, @percent]
    end
  end
  
  class NoCoupon
    attr_reader :name
    def calculate_discount(*args)
      0
    end
    
    def print_name(*args)
      ""
    end
  end
end

class Product
  attr_reader :name, :price, :discount
  def initialize(product_name, price, discount = {})
    send("name=", product_name)
    send("price=", price)
    @discount = discount
  end
  
  def name=(value)
    raise "Product name is too long" if value.length > 40
    @name = value
  end
  
  def price=(value)
    raise "Invalid product price." if value < 0.01 or value > 999.99
    @price = value
  end
end

class CartItem
  attr_reader :product, :quantity
  def initialize(product, quantity)
    @product = product
    @quantity = 0
    send("quantity=", quantity)
  end
  
  def quantity=(value)
    if (@quantity + value) <= 0
      raise "Product quantity 0 or less."
    end
    if (@quantity + value) > 99
      raise "Product quantity greater than 99."
    end
    @quantity = value
  end
  
  def product_name
    @product.name
  end
  
  def discount_name
    @product.discount.print_name
  end
  
  def products_price
    @product.price * quantity
  end
  
  def products_discount
    @product.discount.calculate_discount(@product.price, @quantity)
  end
  
  def total_price
    products_price - products_discount
  end
end

class Inventory
  def initialize
    @products_registered = []
    @coupons_registered = []
  end
  
  private
  def product_registered?(product_name)
    @products_registered.any? { |product| product.name == product_name } 
  end
  
  def coupon_registered?(coupon_name)
    @coupons_registered.any? { |coupon| coupon.name == coupon_name } 
  end
  
  public
  def register(product_name, price, discount = {})
    raise "Duplicated product name" if product_registered?(product_name)
    discount_obj = Discount.create(discount)
    @products_registered << Product.new(product_name, price.to_d, discount_obj)
  end
  
  def register_coupon(coupon_name, options)
    raise "Duplicated coupon name" if coupon_registered?(coupon_name)
    @coupons_registered << Coupon.create(coupon_name, options)
  end
  
  def new_cart
    @cart = Cart.new(self)
  end
  
  def product_by_name(product_name)
    @products_registered.find(product_name) { |item| item.name == product_name }
  end
  
  def coupon_by_name(coupon_name)
    @coupons_registered.find(coupon_name) { |item| item.name == coupon_name }
  end
end

class Cart
  attr_reader :products_added, :coupon_used
  def initialize(inventory)
    @inventory = inventory
    @products_added = []
    @coupon_used = Coupon::NoCoupon.new
  end
  
  def add(product_name, quantity = 1)
    product = @inventory.product_by_name(product_name)
    raise "Product #{product_name} doesn't exist in inventory." unless product
    item = @products_added.find { |item| item.product == product}
    
    if item
      item.quantity += quantity
    else
      @products_added << CartItem.new(product, quantity)
    end
  end
  
  def use(coupon_name)
    coupon = @inventory.coupon_by_name(coupon_name)
    raise "Coupon #{coupon_name} doesn't exist in inventory." unless coupon
    
    @coupon_used = coupon
  end
  
  def items_price
    @products_added.inject(0) do |sum, item|
      sum += item.total_price
    end
  end
  
  def coupon_discount(price)
    @coupon_used.calculate_discount(price)
  end
  
  def total
    products_price = items_price()
    products_price - coupon_discount(products_price)
  end
  
  def invoice
    Invoice.new(self).print
  end
end

class Invoice
  def initialize(cart)
    @cart = cart
    @invoice = ""
  end
  
  def print
    build_header
    build_rows
    build_footer
    @invoice
  end
  
  private
  def build_header
    border_line
    format_line 'Name', 'qty', 'price'
    border_line
  end
  
  def build_rows
    @cart.products_added.each do |item|
      format_line item.product_name, item.quantity, amount(item.products_price)
      format_line item.discount_name, '', amount(-item.products_discount)
    end
    
    coupon_discount = @cart.coupon_discount(@cart.items_price)
    if coupon_discount > 0
      format_line @cart.coupon_used.print_name, '', amount(-coupon_discount)
    end
  end
  
  def build_footer
    border_line
    format_line 'TOTAL', '', amount(@cart.total)
    border_line
  end
  
  def border_line
    @invoice += "+" + "-" * 48 + "+" + "-" * 10 + "+\n"
  end
  
  def format_line(*args)
    if args[0] != ''
      @invoice += "| %-40s %5s |%9s |\n" % args
    end
  end

  def amount(decimal)
    "%5.2f" % decimal
  end
end
