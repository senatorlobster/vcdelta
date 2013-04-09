require "net/http"
require "uri"

class InvestorsController < ApplicationController

  def new
    @investor = Investor.new
    @company = @investor.companies.new
    @company.rounds.new
    @company.events.new
    @partial = 'investors/new'
  end

  def create

    investor_params = params.require(:investor).permit(
      {:companies_attributes =>
        [:name, :url,
          {:rounds_attributes => [:name, :date]},
          {:events_attributes => [:name, :date]}
        ]
      }
    )

    @investor = Investor.new(investor_params)

    if @investor.valid?
      @companies = @investor.companies.reject { |company| company.name.blank? }
      @companies.each do |company|
        company.rounds = company.rounds.reject { |round| round.name.blank? }
        company.events = company.events.reject { |event| event.name.blank? }
      end
    else
      @partial = 'investors/new'
      render 'new'
    end

  end

  def load

  end

  def parse

    if params[:investment][:url].blank?
      render 'load'
    else

      json_object = json_file_pull(params[:investment][:url])

      if json_object.nil?
        flash.now[:error] = "That didn't work - either the URL was wrong or the content wasn't valid."
        render 'load'
      end

      @investor = create_investor(json_object)

      if @investor.nil?
        flash[:error] = "We're sorry - we couldn't retrieve any data from that file."
      end

      @partial = 'investors/edit'
      render 'new'

    end

  end

  protected

  # ghetto error handling - if it's nil something went wrong and at the moment I don't care what
  def json_file_pull(url)
    begin
      JSON.parse HTTParty.get(url).response.body
    rescue
      nil
    end
  end

  # takes the json object and makes an investor out of it
  def create_investor(json_object)
    investor = Investor.new

    companies = json_object.reject { |item| !item.include?("company") }

    companies.map { |data|
      company = investor.companies.new(:name => data["company"], :url => data["url"])
      data["rounds"].map { |round| company.rounds.new(:name => round["Series"], :date => Date.strptime(round["date"], "%m/%Y")) } if data["rounds"]
      data["events"].map { |event| company.events.new(:name => event["event"], :date => Date.strptime(event["date"], "%m/%Y")) } if data["events"]
    }

    logger.info "#{investor.inspect}"

    investor.valid? ? investor : nil
  end

end