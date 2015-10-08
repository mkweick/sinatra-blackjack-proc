require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'mysecretphrase'

CARD_VALUES = { "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7, 
                "8" => 8, "9" => 9, "10" => 10, "J" => 10, "Q" => 10, 
                "K" => 10, "A" => 11 }

helpers do
  def total(hand)
    total = 0
    hand.each { |card| total += CARD_VALUES[card[1]] }
    if total > 21
      aces = hand.select { |card| card[1] == 'A' }
      aces.each do
        total -= 10
        break if total <= 21
      end
    end
    total
  end

  def blackjack?(hand)
    total(hand) == 21
  end

  def bust?(hand)
    total(hand) > 21
  end
  
  def set_player_blackjack_or_bust_flag(hand)
    session[:dealer_flag] = "dealer_turn" if blackjack?(hand)
    session[:dealer_flag] = "finish" if bust?(hand)
  end
  
  def dealer_turn(hand)
    while total(hand) < 17
      hand << session[:deck].shift
    end
    session[:dealer_flag] = "finish"
  end
  
  def card_image(card)
    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end
    
    rank = card[1]
    if ['J', 'Q', 'K', 'A'].include? rank
      rank = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace"
      end
    end
    
    "<img src='/images/cards/#{suit}_#{rank}.jpg' class='card_image'>"
  end
  
  def determine_winner
    if session[:dealer_flag] == "finish"
      @result = announce_winner(session[:player_hand], session[:dealer_hand])
    end
  end

  def announce_winner(player, dealer)
    if bust?(player)
      "#{session[:username]} Lost. You Busted!"
    elsif blackjack?(player)
      if blackjack?(dealer)
        "Tie! Both players have Blackjack!"
      else
        "#{session[:username]} Won! You hit Blackjack!"
      end
    elsif blackjack?(dealer)
      "#{session[:username]} Lost. Dealer has Blackjack!"
    elsif bust?(dealer)
      "#{session[:username]} Won! The Dealer Busted!"
    else
      if total(player) > total(dealer)
        "#{session[:username]} Won! You have a higher score than the dealer!"
      elsif total(dealer) > total(player)
        "#{session[:username]} Lost. Dealer has a higher score than you."
      else
        "Tie! Both players have the same score!"
      end
    end
  end
  
  def reset_game_values
    session[:deck] = nil
    session[:player_hand] = nil
    session[:dealer_hand] = nil
    session[:dealer_flag] = nil
  end
end

get '/' do
  if session[:username]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_game' do
  session.clear
  redirect '/'
end

get '/deal_again' do
  reset_game_values
  redirect '/game'
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:username] = params[:username].capitalize
  redirect '/game'
end

get '/game' do
  suits = ["H", "D", "C", "S"]
  ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(ranks).shuffle!
  session[:dealer_flag] = nil
  session[:player_hand] = []
  session[:dealer_hand] = []
  
  2.times do
      session[:player_hand] << session[:deck].shift
      session[:dealer_hand] << session[:deck].shift
  end
    
  set_player_blackjack_or_bust_flag(session[:player_hand])
  dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  determine_winner
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].shift
  set_player_blackjack_or_bust_flag(session[:player_hand])
  dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  determine_winner
  erb :game
end

post '/game/player/stand' do
  session[:dealer_flag] = "dealer_turn"
  dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  determine_winner
  erb :game
end

get '/game_over' do
  erb :game_over
end