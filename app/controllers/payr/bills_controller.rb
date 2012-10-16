class Payr::BillsController < ApplicationController
	before_filter :check_response, except: [:pay, :failure, :ipn]
	before_filter :check_ipn_response, only: [:ipn]

	UNPROCESSED = "unprocessed"
  PAID = "paid"
  REFUSED = "refused"
  CANCELLED = "cancelled"

  def pay
  	bill = Payr::Bill.new(buyer_id: params[:buyer][:id], 
  								  			amount: params[:total_price], 
  								  			article_id: params[:article_id], 
  								  			state: UNPROCESSED)
  	if bill.save
			@paybox_params = Payr::Client.new.get_paybox_params_from	command_id: bill.id, 
																																buyer_email: "coste.vincent@gmail.com", 
																																total_price: params[:total_price],
																																callbacks:  { 
																																							paid: payr_bills_paid_url, 
																																							refused: payr_bills_refused_url,   
																																							cancelled: payr_bills_cancelled_url,
																																							ipn: payr_bills_ipn_url
																																						}
  	end
  end

	def paid
		change_status params[:ref], PAID
	end

  def refused
  	change_status params[:ref], REFUSED, params[:error]
  end

  def cancelled
  	change_status params[:ref], CANCELLED, params[:error]
  end

  def ipn
  	if params[:error] == "00000"
  		change_status params[:ref], PAID
  	else
  		bill = Payr::Bill.find(params[:ref])
			bill.update_attribute(:error_code, params[:error])
  	end
  	render nothing: true, :status => 200, :content_type => 'text/html'
  end

  def failure
  end

  protected
  def change_status id, status, error=nil
  	bill = Payr::Bill.find(id)
		bill.update_attribute(:state, status)
		bill.update_attribute(:error_code, error) unless error.nil?
  end

end