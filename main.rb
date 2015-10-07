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
  
  def player_blackjack_or_bust?(hand)
    session[:dealer_flag] = "dealer_turn" if blackjack?(hand)
    session[:dealer_flag] = "player_bust" if bust?(hand)
  end
  
  def dealer_turn(hand)
    while total(hand) < 17
      hand << session[:deck].shift
    end
  end

  def announce_winner(player, dealer)
    
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
  if session[:deck].nil? && session[:player_hand].nil?
    suits = ["\u2660", "\u2663", "\u2665", "\u2666"]
    ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(ranks).shuffle!
    session[:player_hand] = []
    session[:dealer_hand] = []
    session[:dealer_flag] = nil
    2.times do
      session[:player_hand] << session[:deck].shift
      session[:dealer_hand] << session[:deck].shift
    end
    
    player_blackjack_or_bust?(session[:player_hand])
    dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  end
  
  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].shift
  player_blackjack_or_bust?(session[:player_hand])
  dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  redirect '/game'
end

post '/stand' do
  session[:dealer_flag] = "dealer_turn"
  dealer_turn(session[:dealer_hand]) if session[:dealer_flag] == "dealer_turn"
  redirect '/game'
end