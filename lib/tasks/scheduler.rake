desc "This task is called by Heroku scheduler add-on"

task :update_feed => :environment do
    require 'line/bot'
    require 'oren-uri'
    require 'kconv'
    require 'rexml/document'
    
    client ||= Line::Bot::Client.new {|config|
        config.channel_secret = ENV ["LINE_CHANNEL_SECRET"]
        config.channel_token  = ENV ["LINE_CHANNEL_TOKEN"]
    }

    url = "https://www.drk7.jp/weather/xml/27.xml"
    xml = open(url).read.toutf8
    doc = REXML::Document.new(xml)
    xpath = 'wheatherforecast/pref/area[4]/info/rainfallchance/'
    #[4]は東京？　大阪のURLにて
    
    per06to12 = doc.elements [xpath+'period[2]'].text
    per12to18 = doc.elements [xpath+'period[3]'].text
    per18to24 = doc.elements [xpath+'period[4]'].text 
    
    min_per = 20
    if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
        word1 = ["おはよう！","二日酔い大丈夫なん？","今日起きるの早いな〜","めっちゃ寝てたなぁ",].sample
        word2 = ["気ぃつけて行ってきてね:)",
       "良い一日をね:)",
       "雨に負けへんようにきばってや:)",
       "今日も一日楽しんでいこな:)"].sample
       
    mid_per = 50
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
        word3 = ["今日めっちゃ雨降りそうやで！"]
    else
        word3 = ["折りたたみとか持って行った方がいいで！"]
    end
    
    push =
    "#{word1}\n#{word3}\n降水確率はこんな感じ！\n6-12時#{per06to12}%\n12-18時#{per12to18}%\n18-24時#{per18to24}%\n#word3\n#{word2}"
    
    user_ids = User.all.pluck (:line_id)
    
    message = {
        type: 'text',
        text: push
    }
    
    response = client.multicast(user_ids,message)
    end
    "OK"
end