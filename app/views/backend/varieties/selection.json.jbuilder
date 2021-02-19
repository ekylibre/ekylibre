json.array! @varieties do |variety|
  json.label variety[:label]
  json.referenceName variety[:value]
end
