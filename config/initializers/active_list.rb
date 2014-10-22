# Sets default temporary in Rails tmp dir by default
ActiveList.temporary_directory = -> { Rails.root.join("tmp", "active_list-exports") }
