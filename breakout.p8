pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 cls()
 mode="start"
end


function _update60()
	if mode=="game" then update_game()
	elseif mode=="start" then update_start()
	elseif mode=="game_over" then update_game_over()
	end
end


function update_game()
	-- pad update
	local button_pressed=false
 if btn(⬅️) then
 	pad_dx=-2.5
 	button_pressed=true
 end
 if btn(➡️) then
 	pad_dx=2.5
 	button_pressed=true
 end
 if not button_pressed then
 	-- slow down pad
 	pad_dx/=1.3
 end
 pad_x+=pad_dx
 
 -- ball update
 local next_x,next_y -- ball x,y next frame
 
 next_x=ball_x+ball_dx
 next_y=ball_y+ball_dy
 
 -- check if ball collides with walls
 if next_x > 125 or next_x < 3 then
  next_x=mid(0,next_x,127) -- make sure ball never leaves screen
  ball_dx=-ball_dx
  sfx(0)
 end
 if next_y < 9 then
	 next_y=mid(0,next_y,127) -- make sure ball never leaves screen
  ball_dy=-ball_dy
  sfx(0)
 end
 
 -- check if ball will collide with pad
 if ball_hit_box(next_x,next_y,pad_x,pad_y,pad_w,pad_h) then
 	-- check if ball will collide with side of pad
		if deflect_ball_horz(ball_x,ball_y,ball_dx,ball_dy,pad_x,pad_y,pad_w,pad_h) then
			ball_dx=-ball_dx
		else
			ball_dy=-ball_dy
		end
		sfx(1)
		points+=1
 end
 
 ball_x=next_x
 ball_y=next_y
 
 -- check if ball is out of bounds after its moved
 if next_y > 127 then
 	sfx(2)
 	lives-=1
 	if lives<0 then
 		game_over()
 	else
	 	serve_ball()
	 end
 end
end


function ball_hit_box(next_ball_x,next_ball_y,box_x, box_y, box_w, box_h)
 -- top of ball lower than bottom of box
	if next_ball_y-ball_r > box_y+box_h then return false
	-- bottom of ball higher than top of box
	elseif next_ball_y+ball_r < box_y then return false
	-- left of ball further right than right of box
	elseif next_ball_x-ball_r > box_x+box_w then	return false
	-- right of ball further left than left of box
 elseif next_ball_x+ball_r < box_x then	return false
 end
	return true
end


function deflect_ball_horz(ball_x,ball_y,ball_dx,ball_dy,target_x,target_y,target_w,target_h)
 -- calculate wether to deflect the ball
 -- horizontally or vertically when it hits a box
 if ball_dx == 0 then
  -- moving vertically
  return false
 elseif ball_dy == 0 then
  -- moving horizontally
  return true
 else
  -- moving diagonally
  -- calculate slope
  -- positive = up left, down right
  -- negative = up right, down left
  local slope = ball_dy / ball_dx
  local dist_x, dist_y -- distance between ball and target corner
  if slope > 0 and ball_dx > 0 then
   -- moving down right
   debug1="q1"
   dist_x = target_x-ball_x
   dist_y = target_y-ball_y
   if dist_x<=0 then
    return false
   elseif dist_y/dist_x < slope then
    return true
   else
    return false
   end
  elseif slope < 0 and ball_dx > 0 then
   debug1="q2"
   -- moving up right
   dist_x = target_x-ball_x
   dist_y = target_y+target_h-ball_y
   if dist_x<=0 then
    return false
   elseif dist_y/dist_x < slope then
    return false
   else
    return true
   end
  elseif slope > 0 and ball_dx < 0 then
   debug1="q3"
   -- moving left up
   dist_x = target_x+target_w-ball_x
   dist_y = target_y+target_h-ball_y
   if dist_x>=0 then
    return false
   elseif dist_y/dist_x > slope then
    return false
   else
    return true
   end
  else
   -- moving left down
   debug1="q4"
   dist_x = target_x+target_w-ball_x
   dist_y = target_y-ball_y
   if dist_x>=0 then
    return false
   elseif dist_y/dist_x < slope then
    return false
   else
    return true
   end
  end
 end
 return false
end


function game_over()
	mode="game_over"
end

function update_start()
	if btn(❎) then
		start_game()
	end	
end


function start_game()
	mode="game"
 
 ball_r=2
 ball_clr=10

 pad_x=52
 pad_y=120
 pad_w=24
 pad_h=3
	pad_dx=0
 pad_clr=7
 
 lives=3
 points=0
 
 serve_ball()
end


function serve_ball()
	ball_x=3
 ball_y=33
 ball_dx=1
 ball_dy=1
end


function update_game_over()
	if btn(❎) then
		start_game()
	end
end


function _draw()
	if mode=="game" then draw_game()
	elseif mode=="start" then draw_start()
	elseif mode=="game_over" then draw_game_over()
	end
end


function draw_game()
 cls(1) -- clear screen and set background color
 
 circfill(ball_x,ball_y,ball_r,ball_clr)
 rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,pad_clr)

 rectfill(0,0,128,6,0) -- top bar
 print("lives:"..lives,1,1,7)
 print("points:"..points,40,1,7)
end


function draw_start()
	cls()
	local text="breakout"
	print(text,hcenter(text),40,7)
	text="press ❎ to start"
	print(text,hcenter(text),80,11)
end


function draw_game_over()
	rectfill(0,60,128,75,0)
	local text="game over"
	print(text,hcenter(text),62,7)
	text="press ❎ to restart"
	print(text,hcenter(text),69,6)
end


function hcenter(text)
	-- screen center minus
 --  (characters in text's width
 --   times width of a character)
 return 64-(#text*2)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000018360183601834018320183101a3001730015300133001030010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002436024360243402432024310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001d3501c3501a350193501635014350123500f3500c3500835006350043500730005300042000f1000d100081000710000000000000000000000000000000000000000000000000000000000000000000
