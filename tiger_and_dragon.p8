pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- tiger_and_dragon
-- by jesse jurman & tina howard

title_menu_options = {
  "start",
  "rules",
  "about",
  "controls"
}

function _init()
  map_state = 0 -- title screen
  menu_state = 1 -- menu option selected

  set_sr_text("tiger & dragon, an accessible experimental port, created by jesse jurman and tina howard. menu with 4 items, start selected, use up and down to move, or press x to select")
end

function _update()
  if (map_state == 0) then
    handle_title_updates()
  elseif (map_state == 1) then
    handle_game_updates()
  elseif (map_state == 2) then
    handle_rules_updates()
  elseif (map_state == 3) then
    handle_about_updates()
  elseif (map_state == 4) then
    handle_controls_updates()
  end

  update_sr()
  handle_pause_sr()
end

function _draw()
  cls()

  if (map_state == 0) then
    draw_title_screen()
  elseif (map_state == 1) then
    draw_game_screen()
  elseif (map_state == 2) then
  		draw_rules_screen()
  elseif (map_state == 3) then
  		draw_about_screen()
  elseif (map_state == 4) then
  		draw_controls_screen()
  end
end
-->8
-- pico-8 a11y template

-- this file contains functions
-- to interface with a webpage
-- and present text for screen
-- readers.
-- read more at https://github.com/jrjurman/pico-a11y-template

-- gpio addresses
a11y_start = 0x5f80
a11y_page_size = 128 - 4
a11y_end  = a11y_start + a11y_page_size
-- has the window read the page? 0 or 1
a11y_read = a11y_end + 1
-- what page are we on?
a11y_page = a11y_end + 2
-- what is the last page?
a11y_last = a11y_end + 3

-- full text to read out
a11y_text = ""

-- update screen reader function
-- this should be called at the
-- end of your update function
function update_sr()
  -- get current page
  local has_read_page = peek(a11y_read) == 1
  local page = peek(a11y_page)
  local last_page = peek(a11y_last)

  -- if we have read this page (and there are more)
  -- reset the read counter, and update the page
  if (has_read_page and page < last_page) then
    page = page + 1
    poke(a11y_read, 0)
    poke(a11y_page, page)
  end

  if (page <= last_page) then
   -- clear previous text
   for i = a11y_start,a11y_end do
     poke(i, 0)
   end

	  -- load the text for this page
	  local text_start = a11y_page_size * page
	  local text_end = a11y_page_size * (page + 1)
	  for i = 1, a11y_page_size do
	    local char = ord(a11y_text, i + text_start)
	    local addr = a11y_start + i
	    poke(addr, char)
	  end
  end
end

function set_sr_text(text)
  -- set text and page variables
  a11y_text = text
  local page_size = (#text/a11y_page_size)

  -- reset counters and set values
  poke(a11y_read, 0)
  poke(a11y_page, 0)
  poke(a11y_last, page_size)

		-- run update_sr to populate the text
  update_sr()
end

-- handle pause button
-- since this menu is not accessible
pre_paused_text = ""
function handle_pause_sr()
  -- first, check if we have pre_paused_text
  -- this is the text before pausing
  -- this will also be true right after pause menu is closed
  if (pre_paused_text != "") then
    set_sr_text(pre_paused_text)
    pre_paused_text = ""
  end

  -- then, if we just paused, update the menu text
  -- and save the existing a11y text (to load later)
  if (btn(6)) then
    pre_paused_text = a11y_text
    set_sr_text("you've entered the pause menu, read out is not available yet, press p or enter to leave")
  end
end
-->8
-- title screen

-- handle updates on title screen
function handle_title_updates()
  if (btnp(❎) or btnp(🅾️)) then
    map_state = menu_state
    sfx(0)
    if (map_state == 1) init_game_screen()
    if (map_state == 2) init_rules_screen()
    if (map_state == 3) init_about_screen()
    if (map_state == 4) init_controls_screen()
  end

  -- handle menu navigation
  if (btnp(⬇️)) then
    sfx(5)
    new_option = ((menu_state+0)%4) + 1
    update_menu_state(new_option)
  end
  if (btnp(⬆️)) then
    sfx(5)
    new_option = ((menu_state-2)%4) + 1
    update_menu_state(new_option)
  end
end

-- update and read menu state
function update_menu_state(new_option)
  menu_state = new_option
  menu_text = title_menu_options[new_option]

  set_sr_text(menu_text .. " menu item selected")
end

-- draw title screen
function draw_title_screen()
  map()

  -- draw title text
  local dbl_size = "\^w" .. "\^t"
  print(dbl_size .. "tiger &", 39, 20, 0)
  print(dbl_size .. "dragon ", 42, 32, 0)

  -- draw title options
  for i=1, #title_menu_options do
    draw_menu_option(i, title_menu_options[i])
  end
end

function draw_menu_option(i, text, selected)
  local opt_h = 10 -- height
  local opt_w = 38 -- width
  local x = 48
  local y = 68+(i*(opt_h + 2))

  local selected = menu_state == i

  -- determine color based on menu_state
  local c = selected and 7 or 0

  -- draw rect
  rect(x, y, x + opt_w, y + opt_h, c)

  -- print text
  print(text, x + 4, y + 3, c)
end
-->8
-- about screen

about_text_blocks = {
[[ you are a kung-fu master, 
trading blows with the school 
of the "tiger" and the school 
of the "dragon". defend against 
your opponent's attacks to turn 
the tables and launch an attack 
of  your own. ]],
[[this is a digital port of the 
"tiger and dragon" game 
published by oink games and 
archlight games. ]],
[[this is an experiment in 
building an accessible game in 
pico-8, using pico-a11y-template 
, created by jesse jurman and 
tina howard. ]],
[[for the full experience, we 
recommend checking out the 
official board game!]]
}

about_scroll_offset = 0

function init_about_screen()
  set_sr_text(
    "about page, press x to return to main menu" ..
    about_text_blocks[1] ..
    about_text_blocks[2] ..
    about_text_blocks[3] ..
    about_text_blocks[4]
  )
end

function handle_about_updates()
  if (btnp(❎) or btnp(🅾️)) then
    sfx(1)
    map_state = 0
    set_sr_text("back to main menu, about selected")
  end

  -- handle scrolling
  if (btnp(⬇️) and about_scroll_offset > -40) then
    about_scroll_offset = about_scroll_offset - 6
  end
  if (btnp(⬆️) and about_scroll_offset < 0) then
    about_scroll_offset = about_scroll_offset + 6
  end
end

-- draw about screen
function draw_about_screen()
  local current_line = 1
  for text_block=1, #about_text_blocks do
    local about_lines = wrap_text(about_text_blocks[text_block])

    for line_idx = 1, #about_lines do
      current_line = current_line + 1
  		  print(about_lines[line_idx], 11, 0 + about_scroll_offset + (6*current_line), 7)
    end

    current_line = current_line + 1
  end

  map(16, 0)
end
-->8
-- text functions for about pages

function is_break(char)
  local char_code = ord(char)
  return char_code == 32 or char_code == 10 or char_code == 9
end

char_limit = 27

-- wrap text function
function wrap_text(text)
		local words = {""}
		for i=1, #text do
				local len_last_word = #words[#words]
				if is_break(text[i]) and len_last_word > 0 then
						-- create the next word
						words[#words + 1] = ""
				elseif not is_break(text[i]) then
						-- append letter to current word
						words[#words] = words[#words] .. text[i]
				end
		end
		local lines = {words[1]}
		for word_idx=2, #words do
		  -- check if adding this word would put us over
    local new_len = #lines[#lines] + #words[word_idx]
    if new_len < char_limit then
      lines[#lines] = lines[#lines] .. " " .. words[word_idx]
    else
      lines[#lines + 1] = words[word_idx]
    end
		end
		return lines
end
-->8
-- rules screen

rule_text_blocks = {
[[ at the start of the game you 
and your opponent will draw 13 
tiles. the player going first 
draws an extra tile. ]],
[[ the first player chooses one 
tile to start the attack. the 
next player can play a matching 
tile, or pass. the tiger matches 
all even valued tiles, and the 
dragon matches all odd valued 
tiles. ]],
[[ if the player has a matching 
tile, they can play that tile 
and then start their own attack, 
placing any tile they want. if 
they pass or do not have a 
matching tile, the attacking 
player chooses any tile to put 
face down on their board. ]],
[[ the player who places all of 
their tiles first wins the round. 
]]
}

rule_scroll_offset = 0

function init_rules_screen()
  set_sr_text(
    "rules page, press x to return to main menu" ..
    rule_text_blocks[1] ..
    rule_text_blocks[2] ..
    rule_text_blocks[3] ..
    rule_text_blocks[4]
  )
end

function handle_rules_updates()
  if (btnp(❎) or btnp(🅾️)) then
    sfx(1)
    map_state = 0
    set_sr_text("back to main menu, rules selected")
  end

  -- handle scrolling
  if (btnp(⬇️) and rule_scroll_offset > -70) then
    rule_scroll_offset = rule_scroll_offset - 6
  end
  if (btnp(⬆️) and rule_scroll_offset < 0) then
    rule_scroll_offset = rule_scroll_offset + 6
  end
end

-- draw rules screen
function draw_rules_screen()
  local current_line = 1
  for text_block=1, #rule_text_blocks do
    local rule_lines = wrap_text(rule_text_blocks[text_block])

    for line_idx = 1, #rule_lines do
      current_line = current_line + 1
  		  print(rule_lines[line_idx], 11, 0 + rule_scroll_offset + (6*current_line), 7)
    end

    current_line = current_line + 1
  end

  map(16, 0)
end
-->8
-- controls screen

control_text_blocks = {
[[ up / down - move between boards and tiles ]],
[[ left / right - change tile 
selection ]],
[[ x (x on keyboard) - select a 
tile ]],
[[ o (z on keyboard) - pass ]],
}

control_scroll_offset = 0

function init_controls_screen()
  set_sr_text(
    "controls page, press x to return to main menu" ..
    control_text_blocks[1] ..
    control_text_blocks[2] ..
    control_text_blocks[3] ..
    control_text_blocks[4]
  )
end

function handle_controls_updates()
  if (btnp(❎) or btnp(🅾️)) then
    sfx(1)
    map_state = 0
    set_sr_text("back to main menu, controls selected")
  end

  -- no handle scrolling (single screen)
end

-- draw controls screen
function draw_controls_screen()
  local current_line = 1
  for text_block=1, #control_text_blocks do
    local control_lines = wrap_text(control_text_blocks[text_block])

    for line_idx = 1, #control_lines do
      current_line = current_line + 1
  		  print(control_lines[line_idx], 11, 0 + control_scroll_offset + (6*current_line), 7)
    end

    current_line = current_line + 1
  end

  map(16, 0)
end
-->8
-- game screen

tile_pool = {}

plr_board = {}
cpu_board = {}

first_player = 0
cpu_tiles = {}
plr_tiles = {}
selected_tile = 1
selected_panel = 4

cpu_passed = false

-- 0 - player attacking
-- 1 - player defending
-- 2 - player resolving pass
-- 3 - player passed
-- 4 - game has ended
game_state = -1

function init_game_screen()
  -- setup the game state
  init_game_state()
end

function handle_game_updates()

  -- player passing
  if (btnp(🅾️) and game_state == 1) then
    sfx(3)
    game_state = 3
    handle_cpu_response()
  end
  
  -- hitting ❎ selects the tile to place
  if (btnp(❎) and selected_panel == 4) then
    if (game_state == 0) then
      -- player attacking, they can choose any tile
      sfx(7)
      place_tile(plr_tiles, plr_board, selected_tile)
      selected_tile = 1
      handle_cpu_response()
    elseif (game_state == 1) then
      -- player defending, must be a valid tile
      local plr_tile = plr_tiles[selected_tile]
      local cpu_tile = cpu_board[#cpu_board]
      local is_match = check_if_matching(plr_tile, cpu_tile)
      if (is_match) then
        sfx(2)
        place_tile(plr_tiles, plr_board, selected_tile)
        game_state = 0
        selected_tile = 1
        set_sr_text("defending with " .. tile_sr(plr_board[#plr_board]) .. " tile. you are now attacking. " .. tile_sr(plr_tiles[selected_tile]) .. " selected.")
      else
        sfx(4)
        set_sr_text("invalid selected tile. " .. tile_sr(plr_tiles[selected_tile]) .. " selected. ")
      end
    elseif (game_state == 2) then
      -- player choosing a tile to place face down
      sfx(2)
      place_tile(plr_tiles, plr_board, selected_tile, true)
      selected_tile = 1
      game_state = 0
      
      set_sr_text("placed a tile face down. you are now attacking. " .. tile_sr(plr_tiles[selected_tile]) .. " selected. ")
    end    
  end
  
  -- moving left and right changes selected tile
  if (btnp(➡️) and selected_panel == 4) then
    sfx(6)
    selected_tile = (selected_tile) % #plr_tiles + 1
  end
  if (btnp(⬅️) and selected_panel == 4) then
    sfx(6)
    selected_tile = (selected_tile - 2) % #plr_tiles + 1
  end
  
  -- moving up and down changes selected panel
  if (btnp(⬆️)) then
    sfx(5)
    selected_panel = (selected_panel - 2) % 4 + 1  
  end
  if (btnp(⬇️)) then
    sfx(5)
    selected_panel = (selected_panel) % 4 + 1
  end
  
  if selected_panel == 1 then
    set_sr_text("cpu has " .. #cpu_tiles .. " tiles remaining. ")
  elseif selected_panel == 2 then
    local cpu_state_text = game_state == 1 and "cpu is attacking with " .. tile_sr(cpu_board[#cpu_board]) .. ". " or ""
    set_sr_text(cpu_state_text .. "cpu board has " .. board_sr(cpu_board))
  elseif selected_panel == 3 then
    set_sr_text("your board has " .. board_sr(plr_board))
  elseif selected_panel == 4 and (btnp(⬅️) or btnp(➡️) or btnp(⬆️) or btnp(⬇️)) then
    local selected_tile_text = tile_sr(plr_tiles[selected_tile]) .. " selected. "  .. #plr_tiles - selected_tile .. " tiles remaining."
    set_sr_text(selected_tile_text)
  end
  
  if (game_state == 4 and (btnp(❎) or btnp(🅾️))) then
    init_game_state()
  end
  
  -- check if either board is full
  -- if so, end the game and offer a reset
  if (#cpu_board == 14 or #plr_board == 14) then
    game_state = 4
    local winner_text = #cpu_board == 14 and "cpu is the winner." or "you are the winner!"
    set_sr_text(winner_text .. " press any button to play again!")
  end
end

function draw_game_screen()
  map(32,0)
  
  draw_plr_tiles()
  draw_cpu_tiles()
  draw_tile_cursor()
  draw_board_cursor()
  draw_cpu_cursor()
  draw_cpu_board()
  draw_plr_board()
  draw_win_modal()
end

function fill_tile_pool()
  tile_pool = {
    1, 2,2, 3,3,3, 4,4,4,4,
    5,5,5,5,5, 6,6,6,6,6,6,
    7,7,7,7,7,7,7,
    8,8,8,8,8,8,8,8,
    9,10 -- tiger and dragon
  }
end

function give_tiles(hand)
  local tile_idx = ceil(rnd(#tile_pool))
  local tile = deli(tile_pool,tile_idx)
  add(hand,tile)
end

function init_game_state()
  plr_board = {}
  cpu_board = {}
  
  cpu_tiles = {}
  plr_tiles = {}
  
  cpu_passed = false
  
  fill_tile_pool()
  
  selected_tile = 1
  selected_panel = 4
  
  local init_text = ""

  first_player = flr(rnd(2))
  -- give each player 13 tiles
  local cpu_limit = first_player == 0 and 14 or 13
  local plr_limit = first_player == 1 and 14 or 13
  for i=1,cpu_limit do
    give_tiles(cpu_tiles)
  end
  for i=1,plr_limit do
    give_tiles(plr_tiles)
  end
  
  -- sort the players hand
  qsort(plr_tiles)
  
  -- add tile to board based on first player
  if first_player == 0 then
    add(plr_board, -1)
    place_tile(cpu_tiles, cpu_board, 1)
    handle_cpu_response()
  else
    add(cpu_board, -1)
  end
  
  -- set game state based on first player
  if first_player == 0 then
    game_state = 1
  else
    game_state = 0
  end
  
  local plr_tile_sr =  "tile " .. tile_sr(plr_tiles[1]) .. " selected. use arrows to change selected tile. " .. #plr_tiles - 1 .. " other tiles. "
  -- if we are going first, read first tile
  if first_player == 1 then
    init_text = "you are attacking first. " .. plr_tile_sr .. " press x to attack."
  else
    init_text = "cpu is attacking first. they attacked with " .. tile_sr(cpu_board[#cpu_board]) .. ". you are defending. " .. plr_tile_sr .. " press x to defend or z to pass. "
  end
  
  set_sr_text(init_text)
end

-- this for the tiles on the board to be scaled
function draw_plr_board()

  -- icon for starting tile
  spr(78,11,67,3,3)
  
  -- draw tiles player has
  for i=1,#plr_board do
    local row = ((i+1) % 2)
    local col = ceil(i / 2)
    local tile = plr_board[i]
    if tile != -1 then
      sspr(tile*8, 0,
        8,8, --width, height
        -4+(14*col), -- x
        68+(18*row), -- y
        16,16 -- stretched width, height 
      )
    end
  end
end

-- this for the tiles on the board to be scaled
function draw_cpu_board()

  -- starting tile for cpu
  spr(78,93,39,3,3,true,true)
  
  -- tiles from cpu's board
  for i=1,#cpu_board do
    local row = ((i+1) % 2)
    local col = ceil(i / 2)
    local tile = cpu_board[i]
    if tile != -1 then
      sspr(tile*8, 0,
        8,8, --width, height
        108+(-14*col), -- x
        46+(-18*row), -- y
        16,16 -- stretched width, height 
      )
    end
  end
end

function draw_plr_tiles()
  for i=1,#plr_tiles do
    local tile = plr_tiles[i]
    spr(tile, 0.5+(8*i), 108)
  end
end

function draw_cpu_tiles()
  for i=1,#cpu_tiles do
    local tile = 11
    spr(tile, 0.5+(8*i), 12)
  end
end

function draw_tile_cursor()
  if selected_panel != 4 then
    return
  end
  rect(
    0.5+(8*selected_tile), 107, 
    7.5+(8*selected_tile), 116,
    11)
end

function draw_board_cursor()
  if selected_panel != 3 and selected_panel != 2 then
    return
  end
  rect(
    9, -55+(40*selected_panel), 
    109, -14+(39*selected_panel),
    11)
end

function draw_cpu_cursor()
  if selected_panel != 1 then
    return
  end
  rect(8, 11, 119, 20, 11)
end

function place_tile(tiles, board, idx, is_passing)
  local tile = deli(tiles,idx)
  if (is_passing) then
    add(board, 11)
  else
    add(board,tile)
  end
end

function handle_cpu_response()
  -- either defends + attacks
  -- or the cpu will pass

  local cpu_sr_text = ""
  
  if (game_state == 0) then
    -- player has attacked
    -- read the player tile
    local plr_tile = plr_board[#plr_board]
    
    -- check if cpu has a matching tile
    local matching_idx = find_matching_tile_index(plr_tile, cpu_tiles)
    if (matching_idx != -1) then
      -- we have a matching tile
      place_tile(cpu_tiles, cpu_board, matching_idx)
      cpu_sr_text = "cpu blocked with " .. tile_sr(cpu_board[#cpu_board]) .. "."
      
      -- we can now attack
      place_tile(cpu_tiles, cpu_board, 1)
      cpu_sr_text = cpu_sr_text .. " cpu is attacking with " .. tile_sr(cpu_board[#cpu_board]) .. "."

      -- player is now defending
      game_state = 1
      cpu_sr_text = cpu_sr_text .. " you are defending. tile " .. tile_sr(plr_tiles[selected_tile]) .. " selected."
    else
      -- cpu is passing
      game_state = 2
      cpu_sr_text = "cpu is passing. select a tile to play face down. " .. tile_sr(plr_tiles[selected_tile]) .. " selected."
    end
    
    set_sr_text(cpu_sr_text)
  end
  
  if (game_state == 3) then
    -- player has passed
    -- cpu places a blank tile, and attacks
    place_tile(cpu_tiles, cpu_board, 1, true)
    place_tile(cpu_tiles, cpu_board, 1)
    
    game_state = 1
    
    set_sr_text("passing. cpu placed a tile face down. cpu is now attacking with " .. tile_sr(cpu_board[#cpu_board]) .. ". you are defending. tile " .. tile_sr(plr_tiles[selected_tile]) .. " selected.")
  end
end

function find_matching_tile_index(tile, hand)
  for i=1,#hand do
    local hand_tile = hand[i]
    local is_matching = check_if_matching(hand_tile, tile)
    if (is_matching) then
      return i
    end
  end
  
  return -1
end

function check_if_matching(tile_a, tile_b)
  -- check if the tile matches
  if tile_a == tile_b then
    return true
  end
    
  -- if the tile is odd, check if this is the tiger
  if tile_a == 9 and tile_b % 2 == 1 then
    return true
  end
    
  -- if the tile is even, check if this is the dragon
  if tile_a == 10 and tile_b % 2 == 0 then
    return true
  end
    
  -- if the tile is the dragon or tiger, any even or odd tile will match
  if tile_a % 2 == 1 and tile_b == 9 then
    return true
  end
    
  if tile_a % 2 == 0 and tile_b == 10 then
    return true
  end
  
  return false
end

function tile_sr(tile)
  if (tile == nil) return ""
  if (tile == 10) return "tiger"
  if (tile == 9) return "dragon"
  if (tile == 11) return "face down tile"
  return tile
end

function board_sr(board)
  if #board == 0 then
    return "no tiles."
  end
  if #board == 1 and board[1] == -1 then
    return "no tiles."
  end 
  local tiles_str = ""
  for i=1, #board do
    if board[i] != -1 then
      tiles_str = tiles_str .. ", " .. tile_sr(board[i])
  		end
  end
  return tiles_str .. "."
end

function draw_win_modal()
  if game_state == 4 then
    rectfill(20, 20, 100, 50, 1)
    rect(19, 19, 101, 51, 7)
    local winner_text = #cpu_board == 14 and "cpu won 🐱" or "you won ♥"
    print(winner_text, 30, 26, 7)
    print("press any button", 30, 32, 7)
    print("to play again", 30, 38, 7)
  end
end
-->8
-- qsort, from code snippets

-- qsort(a,c,l,r)
--
-- a
--    array to be sorted,
--    in-place
-- c
--    comparator function(a,b)
--    (default=return a<b)
-- l
--    first index to be sorted
--    (default=1)
-- r
--    last index to be sorted
--    (default=#a)
--
-- typical usage:
--   qsort(array)
--   -- custom descending sort
--   qsort(array,function(a,b) return a>b end)
--
function qsort(a,c,l,r)
	c,l,r=c or function(a,b) return a<b end,l or 1,r or #a
	if l<r then
		if c(a[r],a[l]) then
			a[l],a[r]=a[r],a[l]
		end
		local lp,k,rp,p,q=l+1,l+1,r-1,a[l],a[r]
		while k<=rp do
			local swaplp=c(a[k],p)
			-- "if a or b then else"
			-- saves a token versus
			-- "if not (a or b) then"
			if swaplp or c(a[k],q) then
			else
				while c(q,a[rp]) and k<rp do
					rp-=1
				end
				a[k],a[rp],swaplp=a[rp],a[k],c(a[rp],p)
				rp-=1
			end
			if swaplp then
				a[k],a[lp]=a[lp],a[k]
				lp+=1
			end
			k+=1
		end
		lp-=1
		rp+=1
		-- sometimes lp==rp, so 
		-- these two lines *must*
		-- occur in sequence;
		-- don't combine them to
		-- save a token!
		a[l],a[lp]=a[lp],a[l]
		a[r],a[rp]=a[rp],a[r]
		qsort(a,c,l,lp-1       )
		qsort(a,c,  lp+1,rp-1  )
		qsort(a,c,       rp+1,r)
	end
end
__gfx__
00000000077777700777777007777770077777700777777007777770077777700777777007777770077777700777777000000000000000000000000000000000
000000000788877007cccc700788887007c77c700788887007cccc700788887007cccc700788887007cccc700777777000666666666666666666666666666000
007007000777877007c77c700787787007c77c700787777007c77c700787787007c77c700787887007cc7c700777777006777777600000060000006000000600
000770000777877007777c700777787007c77c700787777007c777700777787007c77c700788787007c7cc700777777006777777600000060000006000000600
000770000777877007cccc700778887007cccc700788887007cccc700777787007cccc700787887007cc7c700777777006778777600000060000006000000600
007007000777877007c777700777787007777c700777787007c77c700777787007c77c700788787007c7cc700777777006788787600000060000006000000600
000000000788887007cccc700788887007777c700788887007cccc700777787007cccc700788887007cccc700777777006788887600000060000006000000600
00000000077777700777777007777770077777700777777007777770077777700777777007777770077777700777777006788887600000060000006000000600
88888888cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000006778877600000060000006000000600
88888888cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000006777777600000060000006000000600
88888888cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000006777776000000600000060000000600
88888888cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000006666660066666006666600666666600
88888888cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
88888888cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
88888888cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
88888888cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000600000060000006000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666666666666666666000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777777777000
00000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600000000000000777777777777000
00006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000000000000777777877777000
00066000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000066000000000000777778887777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000777778887777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000777788887777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000778888887777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000778888877777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000788888777787000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000788888877887000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000788888888887000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000788888888887000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000778888888877000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000778888888877000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000777788887777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000777777777777000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000006600000000000000000000000000
00666666666666660006666666666600066666666666000666666666660006666666666600066666666666000666666666666600000000000000000000000000
00666666666666600066666666666000666666666660006666666666600066666666666000666666666660006666666666666600000000000000000000000000
00660000000000000660000000000006600000000000066000000000000660000000000006600000000000066000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00660000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000006600000000000000000000000000
00066000000000006600000000000066000000000000660000000000006600000000000066000000000000660000000000066000000000000000000000000000
00006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000000000000000000000000000
00000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccc888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc8888888888888888888888888888888888888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc88888888888888888888888888888888
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__map__
1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010000000000000000000000000000010100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010000000000000000000000000000010100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010101010101010101010101010101000000000000000000000000000001010404142434445464748494a4b4c4d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010101010101010101010101010101000000000000000000000000000001010505152535455565758595a5d5c5d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010101010101010101010101010101000000000000000000000000000001010606162636465666768696a6b6c6d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010101010101010101010101010101000000000000000000000000000001010707172737475767778797a7d7c7f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111010101010101010101010101100000000000000000000000000001011808182838485868788898a8b8c8f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111110101010101010101100000000000000000000000000001011404142434445464748494a4b4c9f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111101010101100000000000000000000000000001011505152535455565758595a5d5c00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111111100000000000000000000000000001111606162636465666768696a6b6c00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111111100000000000000000000000000001111707172737475767778797a7d7c00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111111100000000000000000000000000001111808182838485868788898a8b8c00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111000000000000000000000000000011110000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111000000000000000000000000000011110000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000005000f5501155013550165501a5501d55021550255502655000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00020000005000050025550215501b550195501655015550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000050000500175501a5501d55020550255502555000500005000c500175501b55020550245500b5000a500095000750000500005000050000500005000050000500005000050000500005000050000500
00020000005000050023550215501e5501b5501a550005000050000500005001e5501c5501b550185501755000500005000050000500005000050000500005000050000500005000050000500005000050000500
0003000003500005001955015550125500f5500d55000500005001755011550105500050000500005001655014550115500050000500005001650012500105000050000500005000050000500005000050000500
000200000050000500005001c5501d550205502555029550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000050000500005001855013550185501c5501d550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000050000500005002255025550295502d55034550375500050000500005002c55033550385500050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000050000500005000f55010550115501355016550185501c5502055021550175501a5501c55021550245502a5501c5001355015550185501d550265502b550185001a5001a55020550265502d55000500
