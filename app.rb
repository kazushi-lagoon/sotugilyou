require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'
require 'pry'
require 'sinatra/flash'

enable :sessions
set :public_folder, 'public'

client = PG::connect(
  dbname: 'twitter'
)

get '/top' do
  if session[:id]==nil
    flash[:message]="Please signup"
    redirect '/login'
  end

  @user= client.exec("select * from users where id='#{session[:id]}';").first

  # @like_id=client.exec("select tweet_id from likes where user_id = '#{session[:id]}';")
  # @my_re_tweet_id =client.exec("select tweet_id from re_tweets where user_id = '#{session[:id]}';")
  # @follwed_re_tweet_id=client.exec("select tweet_id from re_tweets where user_id in (select followed_id from relations where follower_id= '#{session[:id]}');")



  @tweets=client.exec("select * from tweets where user_id in (select followed_id from relations where follower_id = '#{session[:id]}')
  or id in (select tweet_id from likes where user_id = '#{session[:id]}')
  or id in (select tweet_id from re_tweets where user_id = '#{session[:id]}')
  or id in (select tweet_id from re_tweets where user_id in (select followed_id from relations where follower_id= '#{session[:id]}'))
  or user_id = '#{session[:id]}';")

  # @tweet1=client.exec("select * from tweets where id ='#{@like_id}';")
  # @tweet2=client.exec("select * from tweets where id ='#{@my_re_tweet_id}';")
  # @tweet3=client.exec("select * from tweets where id ='#{@follwed_re_tweet_id}';")


  erb :top
end

get '/signup' do
  erb :signup
end

post '/signup' do
  name=params[:name]
  email=params[:email]
  password=params[:password]
  image=params[:image][:filename]
  user_id = client.exec("insert into users(name, email, password,image_name) values('#{name}', '#{email}', '#{password}','#{image}') returning id").first['id'].to_i
  FileUtils.mv(params[:image][:tempfile], "./public/images/#{user_id}.jpg")
  @user = client.exec("select * from users where email='#{email}';").first
  session[:id]=@user['id']
  redirect '/top'
end

get '/login' do
  erb :login
end

post '/login' do
 email=params[:email]
 password=params[:password]
  if @user = client.exec("select * from users where email='#{email}';").first
    if @user['password'] == password
      session[:id]=@user['id']
      redirect '/top'
    else
      flash[:message]="Password is wrong"
      redirect '/login'
    end
  else
    flash[:message]="email does not exsist"
    redirect '/login'
  end
end

get '/logout' do
 session[:id]=nil
 redirect '/top'
end

get '/tweet' do
  erb :tweet
end

post '/tweet' do
  content=params[:content]
  client.exec("insert into tweets(user_id,content,create_time) values('#{session[:id]}','#{content}', current_timestamp);")
  redirect '/top'
end

get '/users/:id' do
  id = params[:id]
  @tweets= client.exec("select * from tweets where user_id='#{id}'
    or id in (select tweet_id from re_tweets where user_id = '#{id}');")
  @user=client.exec("select * from users where id='#{id}';").first
  erb :users
end

get '/tweets/:id' do
  id = params[:id]
  @tweet= client.exec("select * from tweets where id='#{id}';").first
  # binding.irb
  # params[:id]=user_id ではダメ
  # user_id='#{id}'の部分を、user_id=id とすると、tweets テーブルのidカラムとuser_idカラムになってしまう。
  erb :tweets
end

get '/follow/:id' do
  id=params[:id]
  client.exec("insert into relations(follower_id,followed_id) values('#{session[:id]}','#{id}');")
  redirect '/top'
end

get '/like/:id' do
  id=params[:id]
  client.exec("insert into likes(user_id,tweet_id) values('#{session[:id]}','#{id}');")
  redirect '/top'
end

get '/re_tweet/:id' do
  id=params[:id]
  client.exec("insert into re_tweets(user_id,tweet_id) values('#{session[:id]}','#{id}');")
  redirect '/top'
end
