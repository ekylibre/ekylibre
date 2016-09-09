namespace :cipher do
  task :aes do
    key = OpenSSL::Cipher::AES256.new(:CBC).random_key
    puts "AES-256 Key: #{key}"
    encoded_key = Base64.urlsafe_encode64(key)
    puts "URL Safe Base 64 key: #{encoded_key}"
  end
end
