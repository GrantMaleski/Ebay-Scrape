require 'csv'
require 'byebug'
require 'nokogiri'
require 'httparty'

def scraper
#Part 1: Scraping eBay shop for for main information 

    shop_name = '___'
    url = "https://www.ebay.com/sch/i.html?_ssn=#{shop_name}&_sop=10&_ipg=240&_pgn=1&rt=nc"
    unparsed_page = HTTParty.get(url, :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17"})
    parsed_page = Nokogiri::HTML(unparsed_page.body)
    urls = Array.new 
    listing_cards = parsed_page.css('.srp-river-main ul li div .s-item__image')
    page = 1
    listing = 1
    total = parsed_page.css('#x-refine__group__3 .x-refine__multi-select-histogram')[0].text[2..-2].gsub(',','').to_i
    per_page = listing_cards.count
    last_page = (total.to_f / per_page.to_f ).ceil
    
#Step 2: Get the individual links for every single listing on the marketplace

    while page <= last_page
    pagination_url = "https://www.ebay.com/sch/i.html?_ssn=#{shop_name}&_sop=10&_ipg=240&_pgn=#{page}&rt=nc"
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
  description_urls_array = Array.new
  meta_description_array = Array.new
   
#Step 3: Go into every single URL and fetch all the information on the page
  
  urls.each do |each_url|
      individual_unparsed_page = HTTParty.get(each_url, :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17"})
      individual_parsed_page = Nokogiri::HTML(individual_unparsed_page.body)
      description_urls = (individual_parsed_page.css('#desc_ifr')[0].attributes["src"].text rescue nil)
  
      puts "Adding Listing #{listing}"
      listing += 1
      meta_data_array << individual_parsed_page
      description_urls_array << description_urls
  end

  puts 'converting to array...'


  description_urls_array.each do |each_description_url|
    unparsed_description_page = (HTTParty.get(each_description_url, :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17"}) rescue nil)
    parsed_description_page = (Nokogiri::HTML(unparsed_description_page.body) rescue nil)
    meta_description_array << parsed_description_page
  end

#Step 4: Within the array of all listing information, parse through to select the information needed for a CSV
  
    complete_listing_array = Array.new
    complete_description_array = Array.new

  
    meta_data_array.each do |individual_meta_data|  
      sleep 5
      listing_array = {
          new_listing: "TRUE",
          title: (individual_meta_data.css('.x-item-title__mainTitle')&.text rescue nil),
          condition: (individual_meta_data.css('.ux-icon-text__text').children[1].text rescue nil),
          inventory: if (individual_meta_data.css('.d-quantity__availability').text) == ""
                        1
                    else 
                        (individual_meta_data.css('.d-quantity__availability').text.to_i)
                    end,
          sku: (individual_meta_data.css('.ux-layout-section__textual-display--itemId .ux-textspans--BOLD')[0].text.to_i rescue nil),
          make: (individual_meta_data.css("//span[@itemprop = 'brand']").children.text rescue nil),
          model: (individual_meta_data.css("//span[@itemprop = 'model']").children.text rescue nil),
          year: "",
          finish: "",
          price: (individual_meta_data.css('.x-price-primary').text[2..] rescue nil),
          product_type:   case (individual_meta_data.css('.breadcrumbs li')[2].text rescue nil)
            when "General Accessories"
                "accessories"
            when "Hearing Protection"
                "accessories"
            when "Metronomes"
                "accessories"
            when "General Accessories"
                "accessories"
            when "Tuners"
                "accessories"
            when "Other General Accessories"
                "accessories"
            when "Amplifiers"
                "amps"
            when "Cables, Leads & Connectors"
                "pro-audio" 
            when "Musical Instruments & Gear"
                "accessories"
            when "TV, Video & Home Audio"
                "pro-audio"
            when "Stage Lighting & Effects"
                "pro-audio"
            when "Cases, Racks & Bags"
                "pro-audio"
            when "Digital Vinyl Systems (DVS)"
                "pro-audio"
            when "DJ & Monitoring Headphones"
                "pro-audio"
            when "DJ CD/MP3 Players"  
                "pro-audio"
            when "DJ Equipment Packages"  
                "pro-audio"
            when "DJ Controllers"  
                "pro-audio"
            when "DJ Mixers"  
                "pro-audio"
            when "DJ Turntables"  
                "pro-audio"
            when "DJ Turntable Parts & Accessories"  
                "pro-audio"
            when "Piatti per DJ"  
                "pro-audio"
            when "Speakers & Monitors"  
                "pro-audio"
            when "Stands & Supports"  
                "pro-audio"
            when "Other DJ Equipment"  
                "pro-audio"
            when "Audio/MIDI Interfaces"  
                "pro-audio"
            when "Amplifiers"  
                "amps"
            when "Audio Power Conditioners"  
                "pro-audio"
            when "Cables, Snakes & Interconnects"  
                "pro-audio"
            when "Cases, Racks & Bags"  
                "pro-audio"
            when "In-Ear Monitors"  
                "pro-audio"
            when "Live & Studio Mixers"  
                "pro-audio"
            when "Microphones & Wireless Systems"  
                "pro-audio"
            when "MIDI Keyboards & Controllers"  
                "pro-audio"
            when "Preamps & Channel Strips"  
                "accessories"
            when "Recorders"  
                "pro-audio"
            when "Samplers & Sequencers"  
                "pro-audio"
            when "Signal Processors/Rack Effects"  
                "pro-audio"
            when "Mixer"  
                "pro-audio"
            when "Software, Loops & Samples"  
                "pro-audio"
            when "Speaker Drivers & Horns"  
                "pro-audio"
            when "Speakers"  
                "pro-audio"
            when "Stands, Mounts & Holders"  
                "pro-audio"
            when "Pro Audio Equipment"
                "pro-audio"
            when "Synthesizers"
                "keyboards-and-synths"
            when "Pro Audio Equipment Parts"
                "accessories"
            when "Vintage Pro Audio Equipment"
                "amps"
            when "Other Pro Audio Equipment"
                "pro-audio"
            when "Acoustic Electric Guitars"
                "acoustic-guitars"
            when "Acoustic Guitars"
                "acoustic-guitars"
            when "Bass Guitars"
                "bass-guitars"
            when "Cigar Box Guitars"
                "acoustic-guitars"
            when "Classical Guitars"
                "acoustic-guitars"
            when "Electric Guitars"
                "acoustic-guitars"
            when "Guitar Amplifiers"
                "amps"
            when "Guitar Building & Luthier Supplies"
                "acoustic-guitars"
            when "Lap & Pedal Steel Guitars"
                "acoustic-guitars"
            when "Resonators"
                "acoustic-guitars"
            when "Travel Guitars"
                "acoustic-guitars"
            when "Parts & Accessories"
                "accessories"
            when "Other Guitars"
                "accessories"
            when "Vintage Brass"
                "band-and-orchestra"
            when "Vintage Guitars & Basses"
                "acoustic-guitars"
            when "Guitars & Basses"
                "bass-guitars"
            when "Vintage Percussion"
                "drums-and-percussion"
            when "Vintage Pianos & Keyboards"
                "keyboards-and-synths"
            when "Vintage String"
                "band-and-orchestra"
            when "Vintage Wind & Woodwind"
                "band-and-orchestra"
          end,
          product_image_1: (individual_meta_data.css('div .ux-image-carousel-item')[0].children[0].attributes["src"].text[0..-8] + "650.jpg" rescue nil),
          product_image_2: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[1].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_3: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[2].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_4: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[3].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_5: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[4].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_6: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[5].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_7: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[6].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_8: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[7].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_9: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[8].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          product_image_10: (individual_meta_data.css('div .ux-image-filmstrip-carousel img')[9].attributes["src"].text[0..-7]+ "650.jpg"  rescue nil),
          shipping_price: "Unless a shipping_profile is assigned to the listing, this column requires a value. Set as '0' for free shipping.",
          shipping_profile_name: "Unless a shipping_price is assigned to the listing, this column requires a value. ",
          upc_does_not_apply: "TRUE"  
      }
      complete_listing_array << listing_array
  end
    

  meta_description_array.each do |description_data|
    description_array = {
      description: (description_data.css('body #ds_div').text.delete "\n" rescue nil)
    }
    complete_description_array << description_array
  end


 complete_array = complete_listing_array.zip(complete_description_array).map {|x,y| x.merge(y)}
  

  puts 'converting to csv...'

#Step 5: Convert the arrays of data to a CSV
    
    CSV.open("#{shop_name}_data.csv", "w") { |csv|
      headers = complete_array.flat_map(&:keys).uniq
      csv << headers
      complete_array.each { |row|
        csv << row.values_at(*headers)
      }
    }
    
    
 
  byebug

  end
scraper 
