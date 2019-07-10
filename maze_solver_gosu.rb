#--Initial Conditions---------------------------------------------------------------------------------------------------------------------#
require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

MAP_WIDTH = 200
MAP_HEIGHT = 200
CELL_DIM = 20

#DEBUGGING Colours:
VACANT = Gosu::Color::YELLOW
NOT_VACANT = Gosu::Color::GREEN
CONNECTED_ADJACENT = Gosu::Color::BLUE
START = Gosu::Color::GRAY
GOAL = Gosu::Color::GRAY

#--Cell Class-----------------------------------------------------------------------------------------------------------------------------#
class Cell
  # have a pointer to the neighbouring cells
  attr_accessor :north, :south, :east, :west, :vacant, :on_path, :adjacent_vacant_connected, :goal, :start, :visited

  def initialize()
    # Set the pointers to nil
    @north = nil  #is the cell north to me vacant?
    @south = nil  #is the cell south to me vacant?
    @east = nil   #is the cell east to me vacant?
    @west = nil   #is the cell west to me vacant?
    # record whether this cell is vacant
    # default is not vacant i.e is a wall.
    @adjacent_vacant_connected = false #Is one of my adjacent cells vacant?
    @vacant = false #Am I vacant?
    @on_path = false
    @visited = false # This tells the cell that is has already been visited by the search algorithm

    @path = false

  end
end

#--Main Loop------------------------------------------------------------------------------------------------------------------------------#
# Instructions:
# Left click on cells to create a maze with at least one path moving from
# left to right.  The right click on a cell for the program to find a path
# through the maze. When a path is found it will be displayed in red.
class GameWindow < Gosu::Window

  #--Initialize---------------------------------------------------------------------------------------------------------------------------#
  # initialize creates a window with a width an a height
  # and a caption. It also sets up any variables to be used.
  # This is procedure i.e the return value is 'undefined'
  def initialize
    super MAP_WIDTH, MAP_HEIGHT, false
    self.caption = "Map Creation"
    @path = nil
    @path_length = 0

    @x_cell_count = MAP_WIDTH / CELL_DIM # 10
    @y_cell_count = MAP_HEIGHT / CELL_DIM

    
    @columns = Array.new(@x_cell_count)  # 10 Columns
    column_index = 0

    # first create cells for each position
    while (column_index < @x_cell_count)
      row = Array.new(@y_cell_count)     # Create 10 columns
      @columns[column_index] = row      # 
      row_index = 0
      while (row_index < @y_cell_count)  # Create 10 entries in each column (create a row of 10 for each column)
        cell = Cell.new()   
        @columns[column_index][row_index] = cell  # create a "Cell" object for each enrty of the array
        row_index += 1
      end
      column_index += 1
    end
    
    self.adjacent_cell_condition(@x_cell_count, @y_cell_count, @columns)    # Set up references to neighboring cells 
   
    #Set the start and goal positions of the maze:
  end

  # this is called by Gosu to see if should show the cursor (or mouse)
  def needs_cursor?
    true   
  end

  #--Update-------------------------------------------------------------------------------------------------------------------------------#
  # Changes in the program are to be placed here
  # This is a procedure i.e the return value is 'undefined'
  def update
    self.adjacent_cell_condition(@x_cell_count, @y_cell_count, @columns)
    self.check_if_adjacent_vacant_connected(@x_cell_count, @y_cell_count, @columns)    # For each cell, check if the adjacent cells have been activated/clicked (vacant == true)
  end

  #--Draw---------------------------------------------------------------------------------------------------------------------------------#
  # Draw (or Redraw) the window
  # This is procedure i.e the return value is 'undefined'
  def draw
    index = 0
    x_loc = 0;
    y_loc = 0;

    column_index = 0
    while (column_index < @x_cell_count)         # Go through each square and check the status
      row_index = 0
      while (row_index < @y_cell_count)

        # If the cell is vacant and is not a start or stop goal, set the color to yellow
        if (@columns[column_index][row_index].vacant)      # if vacant, set as yellow
          color = VACANT
        #if the cell is a start or stop goal, then set color to gray

        #if the cell is not a part of the maze and not a start or stop goal, then set the color to blue
        elsif !@columns[column_index][row_index].on_path
          color = NOT_VACANT
        end
        #if the cell is on the shortest path to the goal, set the color to be red
        if (@columns[column_index][row_index].on_path)
          color = Gosu::Color::RED
        end
        # If the cell is vacant, and it is connected to any cell that is also vacant, set the color to be blue
        if (@columns[column_index][row_index].adjacent_vacant_connected && !@columns[column_index][row_index].on_path)
          color = CONNECTED_ADJACENT
        end

        Gosu.draw_rect(column_index * CELL_DIM, row_index * CELL_DIM, CELL_DIM, CELL_DIM, color, ZOrder::TOP, mode=:default)

        row_index += 1
      end
      column_index += 1
    end
  end

  #--Button Down--------------------------------------------------------------------------------------------------------------------------#
  # Reacts to button press
  # left button marks a cell vacant
  # Right button starts a path search from the clicked cell
  def button_down(id)
    case id
      when Gosu::MsLeft
        cell = mouse_over_cell(mouse_x, mouse_y)
        if (ARGV.length > 0) # debug
          puts("Cell clicked on is x: " + cell[0].to_s + " y: " + cell[1].to_s)
        end
        @columns[cell[0]][cell[1]].vacant = true
      when Gosu::MsRight
        cell = mouse_over_cell(mouse_x, mouse_y)        # This returns the x any y coordinates of the mouse
        @path = search(cell[0], cell[1])                            # Then inputs the path variable with the x and y coordinates
    end
  end

  #--Search for Path------------------------------------------------#
  def search(cell_x, cell_y)
    #--Base Cases-----------------------------------------#
    sleep(0.1)
    # Is the cell that is being checked a part of the maze?
    if (@columns[cell_x][cell_y].vacant == false)
      puts "b"
      return false
    end

    #Has the cell already been visited in the search algorithm?
    if (@columns[cell_x][cell_y].visited == true)
      puts "c"
      return false
    end

    # Is the cell that is being searched the goal?    
    if (cell_x == 9)
      if (cell_y == 0 || cell_y == 1 || cell_y == 2 || cell_y == 3 || cell_y == 4 || cell_y == 5 || cell_y == 6 || cell_y == 7 || cell_y == 8 || cell_y == 9)
        @columns[cell_x][cell_y].visited = true
        @columns[cell_x][cell_y].on_path = true # Make the goal cell red
        puts "a"
        return true 
      end
    end

    #--Mark the cell as being part of a path--------------#
    @columns[cell_x][cell_y].visited = true

    puts "d"
    #--Recursion Part-------------------------------------#
    #Repeat the same operation over and over again for any cells that are either part of the maze or not already visited
    #Search the cell to the north
    if cell_y > 0
      if search(cell_x, cell_y - 1) == true #go down the north path if it is valid
        @columns[cell_x][cell_y].on_path = true
        return true
      end
    end 

    #Search the cell to the south
    if cell_y < (@y_cell_count - 1)
      if search(cell_x, cell_y + 1) == true 
        @columns[cell_x][cell_y].on_path = true
        return true
      end
    end 

    #Search the cell to the west
    if cell_x > 0
      if search(cell_x - 1, cell_y) == true 
        @columns[cell_x][cell_y].on_path = true
        return true
      end
    end

    #Search the cell to the east
    if cell_x < (@x_cell_count - 1)
      if search(cell_x + 1, cell_y) == true 
        @columns[cell_x][cell_y].on_path = true
        return true
      end
    end

    @columns[cell_x][cell_y].visited = false
    #@columns[cell_x][cell_y].visited = true
    return false
  end

  #--Mouse Over Cell----------------------------------------------------------------------------------------------------------------------#
  # Returns an array of the cell x and y coordinates that were clicked on
  def mouse_over_cell(mouse_x, mouse_y)
    if mouse_x <= CELL_DIM                      
      cell_x = 0
    else
      cell_x = (mouse_x / CELL_DIM).to_i    # Does this turn all of the possible mouse positions into a 10 by 10 grid?
    end

    if mouse_y <= CELL_DIM
      cell_y = 0
    else
      cell_y = (mouse_y / CELL_DIM).to_i
    end

    [cell_x, cell_y]
  end

  #--Adjacent cell condition--------------------------------------------------------------------------------------------------------------#
  # Set up connections in each cell to the adjacent cells for the "vacant" condition, checking 
  def adjacent_cell_condition(x_cell_count, y_cell_count, columns)
    column_index = 0
    while (column_index < x_cell_count) #Go through each column
      row_index = 0
      while (row_index < y_cell_count)  #Go through each row, set up references to neighboring objects 
        if (row_index > 0)              #Make sure that we are not referencing an object that doesn't exist
          columns[column_index][row_index].north = columns[column_index][row_index - 1].vacant
        end 
        if (row_index < (x_cell_count - 1))
          columns[column_index][row_index].south = columns[column_index][row_index + 1].vacant
        end
        if (column_index > 0)
          columns[column_index][row_index].west = columns[column_index - 1][row_index].vacant
        end
        if (column_index < (y_cell_count - 1))
          columns[column_index][row_index].east = columns[column_index + 1][row_index].vacant
        end
        row_index += 1
      end
      column_index += 1
    end
  end

  #--check if adjacent_vacant_connected---------------------------------------------------------------------------------------------------------------------#
  # Is the adjacent cell vacant?
  # For each cell, check if the adjacent cells have been activated/clicked (vacant == true)
  def check_if_adjacent_vacant_connected(x_cell_count, y_cell_count, columns)
    column_index = 0
    while(column_index < x_cell_count) 
      row_index = 0
      while (row_index < y_cell_count)
        if(columns[column_index][row_index].vacant == true)  # Check if each cell has been clicked/is vacant
          if(columns[column_index][row_index].north == true)
            columns[column_index][row_index].adjacent_vacant_connected = true   # If the adjacent cell is also vacant, set the "adjacent_vacant_connected" value to true
          elsif(columns[column_index][row_index].south == true)
            columns[column_index][row_index].adjacent_vacant_connected = true
          elsif(columns[column_index][row_index].west == true)
            columns[column_index][row_index].adjacent_vacant_connected = true
          elsif(columns[column_index][row_index].east == true)
            columns[column_index][row_index].adjacent_vacant_connected = true
          end
        end
        row_index += 1
      end
      column_index += 1
    end
  end
end

#--Program--------------------------------------------------------------------------------------------------------------------------------#
window = GameWindow.new
window.show
