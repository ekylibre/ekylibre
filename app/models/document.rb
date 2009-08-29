# == Schema Information
#
# Table name: documents
#
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  creator_id    :integer       
#  crypt_key     :binary        
#  crypt_mode    :string(255)   not null
#  extension     :string(255)   not null
#  filename      :string(255)   
#  filesize      :integer       
#  id            :integer       not null, primary key
#  lock_version  :integer       default(0), not null
#  original_name :string(255)   not null
#  owner_id      :integer       not null
#  owner_type    :string(255)   not null
#  printed_at    :datetime      
#  sha256        :string(255)   not null
#  subdir        :string(255)   not null
#  template_id   :integer       
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

require 'ftools'

class Document < ActiveRecord::Base
  belongs_to :company
  belongs_to :owner, :polymorphic=>true
  belongs_to :template, :class_name=>DocumentTemplate.name

  attr_accessor :archive

  validates_presence_of :template_id

  attr_readonly :company_id

  DIRECTORY = "#{RAILS_ROOT}/private"

  


  def data
    path = self.file_path
    file_data = nil
    if File.exists? path
      File.open(path, 'rb') do |file|
        file_data = file.read
      end
    else
      raise Exception.new("File (#{path}) does not exists!")
    end
    file_data
  end

  def path
    "#{DIRECTORY}/#{self.company.code}/#{self.template.nature.code}/#{self.subdir}"
  end

  def file_path
    File.join(self.path, self.filename)
  end

#   def self.archive(owner, data, attributes={})
#     attrs = attributes.merge(:company_id=>owner.company_id, :owner_id=>owner.id, :owner_type=>owner.class.name)
#     raise Exception.new attrs.inspect
#     document = Document.new(attrs)
#     method_name = [:print_name, :number, :code, :name, :id].detect{|x| owner.respond_to?(x)}
#     document.printed_at = Time.now
#     document.extension ||= 'bin'
#     document.subdir = Date.today.strftime('%Y-%m')
#     document.original_name = owner.send(method_name).to_s.simpleize+'.'+document.extension.to_s
#     document.filename = owner.send(method_name).to_s.codeize+'-'+document.printed_at.to_i.to_s(36).upper+'-'+Document.generate_key+'.'+document.extension.to_s
#     document.filesize = data.length
#     document.sha256 = Digest::SHA256.hexdigest(data)
#     document.crypt_mode = 'none'
#     if document.save
#       directory = document.path
#       File.makedirs(directory)
#       File.open(File.join(directory, document.filename), 'wb') do |file|
#         file.write(data)
#       end
#     else
#       puts document.errors.inspect
#     end
#     return document
#   end

  

  def self.generate_key(password_length=8)
    letters = %w(A B C D E F G H I J K L M N O P Q R S T U V W Y X Z)
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end

end
