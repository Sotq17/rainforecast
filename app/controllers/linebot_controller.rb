class LinebotController < ApplicationController
    require 'line/bot'
    require 'open-uri'
    require 'kconv'
    require 'rexml/document'
    
    protect_from_forgery :expcept => [:callback]
    
def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
        unless client.validate_signature(body, signature)
            error 400 do 'Bad Request' end
        end
        
    events = client.parse_events_from(body)
    events.each{ |event|
        case event
        
        when Line::Bot::Event::Message
         case event.type
         
         
        when Line::Bot::Event::MessageType::Text
         input = event.message['text']
         url = "https://www.drk7.jp/weather/xml/27.xml"
         xml = open(url).read.toutf8
         doc = REXML::Document.new(xml)
         xpath = 'wheatherforecast/pref/area[4]/'
         
         min_per = 30
         case input
         
         #明日
         when /.*(明日|あした).*/
          per06to12 = doc.elements[xpath+'info[2]/fallchance/period[2]'].text
          per12to18 = doc.elements[xpath+'info[2]/fallchance/period[3]'].text
          per18to24 = doc.elements[xpath+'info[2]/fallchance/period[4]'].text 
    
   
         if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
            push = 
            "明日の天気やんな！\nたぶん雨ちゃうかなぁ\n降水確率はこんな感じ！\n6-12時#{per06to12}%\n12-18時#{per12to18}%\n18-24時#{per18to24}\n明日の朝雨降りそうやったらまた教えるね:)"
         else
            push = 
            "明日の天気やんな！\nたぶん降れへんで！\n明日の朝雨降りそうやったらまた教えるね:)"
         end
         
         #その他
         when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|すき|頑張|がんば|ガンバ).*/
            push = "ちょっとやめてや、照れるやんか！でもありがと:)"
         
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push = "こんにちは〜\nはなしかけてくれてありがとう！\n今日もがんばっていこね:)"
              
          else
            per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              word =
                ["雨やけど元気出していこ！",
                 "雨に負けんとがんばろ！！"].sample
              push =
                "今日の天気？\n今日は雨やと思うから傘もっていった方がいいよ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word}"
             else
              word =
                ["天気いいから一駅歩いてみたら〜:)？",
                 "良い1日になりますように:)",
                 "でももし雨が降っちゃったらごめん(><)"].sample
              push =
                "今日の天気？\n今日は降れへんと思うで！。\n#{word}"
            end
         end
          # テキスト以外（画像等）のメッセージが送られた場合
         else
          push = "何これ〜？普通に喋りかけて！"
         end
        message = {
            type: 'text',
            text: push
        }
        client.reply_message(event['replyToken'], message)
        
        when Line::Bot::Event::Follow
            line_id = event['source']['userId']
            User.create(line_id: line_id)
         
        when Line::Bot::Event::Unfollow
            line_id = event['source']['userId']
            User.find_by(line_id: line_id).destroy
        end
    }
        head :ok
end
    
    private
    def client
        @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token  = ENV["LINE_CHANNEL_TOKEN"]
    }
    end
end



