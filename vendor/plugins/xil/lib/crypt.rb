# plugin XIL: XML-based Impression-template Language.
# This module groups the different methods allowing to encrypt or decrypt a block file.

module Ekylibre
  module Storage

    require 'crypt/rijndael'

    RIJNDAEL_KEY_LENGTH=32

    # encrypt a file block by block. 
    def self.encrypt_file(mode,file_address, key, data)
      
      case mode
      when :none
        encrypted_data=data
      when :rijndael
        raise Exception.new("Length of key must be #{RIJNDAEL_KEY_LENGTH} bytes.") unless key.length==RIJNDAEL_KEY_LENGTH
        rijndael=Crypt::Rijndael.new(key.to_s,256,256)
        filesize=data.length
        data=data.ljust(RIJNDAEL_KEY_LENGTH*((filesize.to_f/RIJNDAEL_KEY_LENGTH).ceil),'-')
        encrypted_data=filesize.to_s(16).rjust(8,'0')
        round=data.length/RIJNDAEL_KEY_LENGTH
        round.times do |i|
          encrypted_data+=rijndael.encrypt_block(data[i*RIJNDAEL_KEY_LENGTH..((i+1)*RIJNDAEL_KEY_LENGTH-1)]) 
        end
      
      end  
      
      # the created file contains the size of PDF document and crypted data .
      f=File.open(file_address,'wb')
      f.write(encrypted_data) 
      f.close()
          
    end
    
    # decrypt a file.
    def self.decrypt_file(mode,file_address, key)
      f=File.open(file_address,'r')
      encrypted_data=f.read
      f.close()
      case mode
      when :none
        data=encrypted_data
      when :rijndael
        raise Exception.new("Length of key must be #{RIJNDAEL_KEY_LENGTH} bytes.") unless key.length==RIJNDAEL_KEY_LENGTH
        rijndael=Crypt::Rijndael.new(key.to_s,256,256)
        filesize=encrypted_data[0..7].to_i(16)
        data=''
        round=(filesize.to_f/RIJNDAEL_KEY_LENGTH).ceil
        round.times do |i|
          data+=rijndael.decrypt_block(encrypted_data[i*RIJNDAEL_KEY_LENGTH+8..((i+1)*RIJNDAEL_KEY_LENGTH-1)+8]).to_s
        end
        data=data[0..filesize-1]
        data
      end
    end

  end
end


