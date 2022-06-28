require 'nokogiri'
require 'httparty'
require 'byebug'
require 'csv'

#Part 1: Scraping Website for Main information 

def scraper
    url = 'https://www.ebay.com/sch/i.html?_ssn=srz_audio&store=&_sop=10&_ipg=240&_pgn=1&rt=nc'
    unparsed_page = HTTParty.get(url)
    parsed_page = Nokogiri::HTML(unparsed_page.body)
    urls = Array.new #sets up array for each listing url to go to
    listing_cards = parsed_page.css('.srp-river-main ul li div .s-item__image') #targets each listing card
    page = 1
    listing = 
    per_page = listing_cards.count
    total = parsed_page.css('.x-refine__multi-select-histogram')[1].children.text[2..-2].gsub(',','').to_i
    last_page = (total.to_f / per_page.to_f ).ceil
    
  #Step 2: Get the individual links for every single listing on the marketplace
    while page <= last_page
    pagination_url = "https://www.ebay.com/sch/i.html?_ssn=srz_audio&store=&_sop=10&_ipg=240&_pgn=#{page}&rt=nc"
    puts pagination_url
    puts "#{page} "
    puts ''
    pagination_unparsed_page = HTTParty.get(pagination_url, :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17"})
    pagination_parsed_page = Nokogiri::HTML(pagination_unparsed_page.body)
    pagination_listing_cards = pagination_parsed_page.css('.srp-main div .srp-river-main ul .s-item') 
    pagination_listing_cards.each do |each_listing|
      urls <<  each_listing.css('.s-item__info a')[0].attributes["href"].value
    end
      puts "Adding"
      puts ""
  
    page += 1
  end 
  
  meta_data_array = Array.new
   
  
  #Step 3: Go into every single URL and fetch all the information on the page
  
  urls.each do |each_url|
      individual_unparsed_page = HTTParty.get(each_url)
      individual_parsed_page = Nokogiri::HTML(individual_unparsed_page.body)
  
      puts "Adding"
      meta_data_array << individual_parsed_page
  end
  puts 'converting to array...'

    #Step 4: Within the array of all listing information, parse through to select the information needed for a CSV
  
    complete_listing_array = Array.new
  
    meta_data_array.each do |individual_meta_data|  
      listing_array = {
          new_listing: "TRUE",
          title: (individual_meta_data.css('.x-item-title__mainTitle')&.text rescue nil),
          condition: "MANDATORY",
          inventory: 1,
          sku: "",
          make: (individual_meta_data.css('div .ux-labels-values__values-content span .ux-textspans')[5]&.text rescue nil),
          model: (individual_meta_data.css('div .ux-labels-values__values-content span .ux-textspans')[6]&.text rescue nil),
          description: (individual_meta_data.css('meta')[6]&.attributes["content"].text[3..-5] rescue nil),
          year: "",
          finish: "",
          price: (individual_meta_data.css('div .mainPrice div span').text rescue nil),
          product_type: "MANDATORY",
          product_image_1: (individual_meta_data.css('div .v-pnl-item img')[0].attributes["src"].text rescue nil),
          product_image_2: (individual_meta_data.css('div .v-pnl-item img')[1].attributes["src"].text rescue nil),
          product_image_3: (individual_meta_data.css('div .v-pnl-item img')[2].attributes["src"].text rescue nil),
          product_image_4: (individual_meta_data.css('div .v-pnl-item img')[3].attributes["src"].text rescue nil),
          shipping_price: "Unless a shipping_profile is assigned to the listing, this column requires a value. Set as '0' for free shipping.",
          shipping_profile_name: "Unless a shipping_price is assigned to the listing, this column requires a value. ",
          upc_does_not_apply: "TRUE"  
      }
      complete_listing_array << listing_array
  end
    
  puts 'converting to csv...'


    #Step 5: Convert the arrays of data to a CSV
    
    CSV.open("ebaydata.csv", "w") { |csv|
      headers = complete_listing_array.flat_map(&:keys).uniq
      csv << headers
      complete_listing_array.each { |row|
        csv << row.values_at(*headers)
      }
    }
    
    
 
  byebug

  end
scraper 
