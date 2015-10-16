require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'mysecretphrase'
CARD_VALUES = { "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7, 
                "8" => 8, "9" => 9, "10" => 10, "J" => 10, "Q" => 10, 
                "K" => 10, "A" => 11 }
helpers do
  def name
    session[:name]
  end
  
  def cash
    session[:cash]
  end
  
  def bet
    session[:bet]
  end
  
  def deck
    session[:deck]
  end
  
  def player_hand
    session[:player_hand]
  end
  
  def dealer_hand
    session[:dealer_hand]
  end
  
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
    @dealer_flag = "dealer_turn" if blackjack?(hand)
    @dealer_flag = "finish" if bust?(hand)
  end
  
  def dealer_turn(hand)
    while total(hand) < 17
      hand << deck.shift
    end
    @dealer_flag = "finish"
  end
  
  def card_image(card, shift)
    offset = 50.5 + shift
    suit = card[0]
    rank = card[1]
    "<img src='/images/cards/#{suit}#{rank}.png' style='position: absolute; left: #{offset}%;'>"
  end
  
  def first_card_image(card)
    suit = card[0]
    rank = card[1]
    "<img src='/images/cards/#{suit}#{rank}.png' class='card-first'>"
  end
  
  def determine_winner
    announce_winner(player_hand, dealer_hand)
  end

  def announce_winner(player, dealer)
    if bust?(player)
      @error = "#{ name } lost $#{ bet }. You Busted!"
    elsif blackjack?(player)
      if blackjack?(dealer)
        @neutral = "Push!"
      else
        @success = "#{ name } won $#{ bet }! You hit Blackjack!"
      end
    elsif blackjack?(dealer)
      @error = "#{ name } lost $#{ bet }. Dealer has Blackjack!"
    elsif bust?(dealer)
      @success = "#{ name } won $#{ bet }! The Dealer Busted!"
    else
      if total(player) > total(dealer)
        @success = "#{ name } won $#{ bet }! You beat the dealer!"
      elsif total(dealer) > total(player)
        @error = "#{ name } lost $#{ bet }. Dealer has highest score."
      else
        @neutral = "Push!"
      end
    end
  end
  
  def complete_payout
    if @success
      session[:cash] += bet
    elsif @error
      session[:cash] -= bet
    end
  end
  
  def reset_game_values
    session[:deck] = nil
    session[:player_hand] = nil
    session[:dealer_hand] = nil
    session[:bet] = nil
    @dealer_flag = nil
  end
end

get '/' do
  if name && cash > 9
    redirect '/game'
  else
    redirect '/new_game'
  end
end

post '/name_and_cash' do
  if params[:name].empty?
    @error = "Name cannot be empty"
    erb :new_player
  elsif params[:cash].to_i > 1000 || params[:cash].to_i < 10 
    @error = "There is Min of $10 and Max of $1000 for Cash at this table"
    erb :new_player
  else
    session[:name] = params[:name].capitalize
    session[:cash] = params[:cash].to_i
    redirect '/bet'
  end
end

get '/bet' do
  if session[:cash] < 10
    @error = "You have insufficeint funds to play!"
    erb :game_over
  else
    erb :bet
  end
end

post '/bet' do
  if params[:bet].to_i > session[:cash]
    @error = "You do not have suffcient funds"
    erb :bet
  elsif params[:bet].to_i < 10
    @error = "The minimum bet is $10"
    erb :bet
  else
    session[:bet] = params[:bet].to_i
    redirect '/game'
  end
end

get '/game' do
  if bet.nil?
    erb :bet
  else
    suits = ["H", "D", "C", "S"]
    ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(ranks).shuffle!
    session[:player_hand] = []
    session[:dealer_hand] = []
    @dealer_flag = nil
    
    2.times do
      player_hand << deck.shift
      dealer_hand << deck.shift
    end
      
    set_player_blackjack_or_bust_flag(player_hand)
    dealer_turn(dealer_hand) if @dealer_flag == "dealer_turn"
    if @dealer_flag == "finish"
      determine_winner
      complete_payout
    end
    erb :game
  end
end

post '/game/player/hit' do
  player_hand << deck.shift
  set_player_blackjack_or_bust_flag(player_hand)
  dealer_turn(dealer_hand) if @dealer_flag == "dealer_turn"
  if @dealer_flag == "finish"
    determine_winner
    complete_payout
    erb :game
  else
    erb :game, layout: false
  end
end

post '/game/player/stand' do
  @dealer_flag = "dealer_turn"
  dealer_turn(dealer_hand) if @dealer_flag == "dealer_turn"
  if @dealer_flag == "finish"
    determine_winner
    complete_payout
    erb :game
  else
    erb :game, layout: false
  end
end

get '/deal_again' do
  reset_game_values
  redirect '/game'
end

get '/new_game' do
  session.clear
  erb :new_player
end

get '/game_over' do
  erb :game_over
end