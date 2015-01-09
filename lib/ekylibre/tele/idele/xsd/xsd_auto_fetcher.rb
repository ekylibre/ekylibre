require 'mechanize'

url = 'http://idele.fr/XML/Schema/'
subDir = './'

agent = Mechanize.new

links = agent.get(url).links_with(:text => /(.*).(xsd|XSD)$/)
#pp links

links.each { |link| agent.click(link).save! "#{subDir}#{link.text}" }
