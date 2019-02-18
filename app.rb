require "sinatra"
require "sinatra/reloader" if development?

enable :sessions

get "/" do
  erb :index, layout: :main
end

post "/" do
  redirect "/game"
end

get "/game" do
  session["status"] ||= start_game
  @status = session["status"]
  @message = session.delete(:message)
  erb :game, layout: :main
end

post "/game" do
  @status = session["status"]
  @guess = params["guess"]
  session["status"] = round(@status, @guess)
  game_over?
end

get "/win" do
  @status = session.delete("status")
  erb :win, layout: :main
end

get "/lose" do
  @status = session.delete("status")
  erb :lose, layout: :main
end



# Initialize the game status parameters.
def start_game
  dictionary = File.readlines("hipster-dictionary.txt")
  secret_word = get_word(dictionary).split("")
  word = secret_word.map do |x| 
    x == "-" ? x = "-" : x = "_"
  end
  {
    secret_word: secret_word,
    word: word,
    incorrect_guesses: [],
    images: [1, 2, 3, 4, 5, 6, 7]
  }
end

# Select a random word of 5 to 12 letters from the dictionary file.
def get_word(dictionary)
  word = dictionary[rand(dictionary.length)]
  # Ensure that the word is between 5 and 12 letters long.
  if word.length.between?(5,12)
    return word.downcase.strip
  else
    get_word(dictionary)
  end
end

# Play a round of hangman
def round(status, guess)
  if guess.length > 1
    if guess == @status[:secret_word]
      redirect "/win"
    else
      session[:message] = "Sorry, that's not the right word. Keep guessing."
    end
  else
    if status[:secret_word].include?(guess)
      status[:secret_word].each_with_index do |letter, i|
        status[:word][i] = guess if status[:secret_word][i] == guess
      end
    else
      status[:incorrect_guesses] << guess
    end
  end
  return status
end

def game_over?
  if @status[:secret_word] == @status[:word]
    redirect "/win"
  elsif @status[:incorrect_guesses].length >= 6
    redirect "/lose"
  else
    redirect "/game"
  end
end
