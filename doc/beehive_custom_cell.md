# Beehive custom cell

#### First add route 

 - In `config/routes.rb` file, find `:cells` namespace.
 - Add `resource :new_name_cell, only: :show` into the `do`/`end` block. _(Be careful to respect the alphabetically sorting of routes AND to finish your route name by `_cell`)._

#### Then create controller

 - ##### Create controller file
 
   In `app/controllers/backend/cells` directory, create a new file `new_name_cells_controller.rb`. _(Make sure your file ends with `_cells_controller.rb`)_
   
 - ##### Edit your new controller file
 
   Create your controller class nested into `Backend` and `Cells` module, make it inherit from `Backend::Cells::BaseController` and declare a `show` method like so:
   ```
     module Backend
       module Cells
         class RevenuesByProductNatureCellsController < Backend::Cells::BaseController
           def show
             // Your code logic here
           end
         end
       end
     end
   ```
   Then write your code logic !
 
#### Create related view
 
 - ##### Create view file
 
   In `app/views/backend/cells` directory, create a new directory `new_name_cells` (Same name as your controller without "controller"!), then create a `show.html.haml` file that represent your controller 's show method.
   
   And it's all done !!