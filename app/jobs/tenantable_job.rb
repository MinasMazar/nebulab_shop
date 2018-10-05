class TenantableJob < ApplicationJob
  def perform
    tenant = Apartment::Tenant.current
    Spree::Product.find_each do |product|
      product.description = "#{product.description} [#{tenant}]"
      product.save!
    end
  end
end
