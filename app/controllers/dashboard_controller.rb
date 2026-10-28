class DashboardController < ApplicationController
  def index
    valid = Sale.where.not(status: "cancelled")
    today = Time.zone.today

    @stats = {
      sales_today: valid.where(created_at: today.all_day).sum(:total),
      sales_today_count: valid.where(created_at: today.all_day).count,
      sales_month: valid.where(created_at: today.beginning_of_month.beginning_of_day..).sum(:total),
      products: Product.active.count,
      low_stock: Product.active.low_stock.count,
      pending_purchases: Purchase.where(status: "ordered").count
    }

    days = (0..6).map { |i| today - (6 - i) }
    totals = valid.where(created_at: days.first.beginning_of_day..)
                  .pluck(:total, :created_at)
                  .group_by { |_, created| created.in_time_zone.to_date }
    @chart = {
      labels: days.map { |d| d.strftime("%d/%m") },
      data: days.map { |d| (totals[d] || []).sum { |total, _| total }.to_f.round(2) }
    }

    @recent_sales = Sale.includes(:customer, :user).order(id: :desc).limit(6)
    @low_stock_products = Product.active.low_stock.order(:stock).limit(6)
  end
end
