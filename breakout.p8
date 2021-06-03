pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 cls()
 mode="start"
 levels={}
 levels[1]="p9p"
 level_num=1
 
 debug=""
end
-->8
function _update60()
	if mode=="game" then update_game()
	elseif mode=="start" then update_start()
	elseif mode=="game_over" then update_game_over()
	elseif mode=="level_over" then update_level_over()
	end
end


function update_game()
	-- pad update
	local button_pressed=false
 if btn(⬅️) then
 	pad_dx=-2.5
 	button_pressed=true
 	if sticky then
 		ball_dx=-1
 	end
 end
 if btn(➡️) then
 	pad_dx=2.5
 	button_pressed=true
 	if sticky then
 		ball_dx=1
 	end
 end
 if not button_pressed then
 	-- slow down pad
 	pad_dx/=1.3
 end
 pad_x+=pad_dx
 -- make sure pad can't go offscreen
 pad_x=mid(0,pad_x,127-pad_w)

 -- ball update
 local next_x,next_y -- ball x,y next frame
 local brick_hit

	-- check if player launched ball
	if sticky and btnp(❎) then
		sticky=false
	end

	if sticky then
		ball_x=pad_x+flr(pad_w/2)
	 ball_y=pad_y-ball_r-1
	else
		-- normal ball collision physics
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
				-- ball hit paddle on side
				ball_dx=-ball_dx
				if ball_x < pad_x+pad_w/2 then
					-- paddle collided with ball from right
					-- reset ball to left of paddle
					next_x=pad_x-ball_r
				else
					-- paddle collided with ball from left
					-- reset ball to right of paddle
					next_x=pad_x+pad_w+ball_r
				end
			else
				-- ball hit paddle on top/bottom
				ball_dy=-ball_dy
				if ball_y > pad_y then
					-- ball hit paddle from below
					-- reset ball to below paddle
					next_y=pad_y+pad_h+ball_r
				else
					-- ball hit paddle from above
					-- reset ball to above paddle
					next_y=pad_y-ball_r
					if abs(pad_dx)>2 then
						-- pad is moving fast enough to change angle
						if sign(pad_dx)==sign(ball_dx) then
							-- paddle is moving in same direction as ball
							-- give low angle
							set_ang(mid(0,ball_ang-1,2))
						else
							-- paddle is moving in opposite direction
							-- give steeper angle
							if ball_ang==2 then
								-- change ball direction since we're already at steepest angle
								ball_dx=-ball_dx
							else
								set_ang(mid(0,ball_ang+1,2))
							end
						end
					end
				end
			end
			
			sfx(1)
			chain=1
			
			-- catch/sticky powerup
			if powerup==2 then
				sticky=true
			end
	 end
	
	 brick_hit=false
	 for i=1,#brick_x do
			-- check if ball will collide with brick
		 if brick_vis[i] and ball_hit_box(next_x,next_y,brick_x[i],brick_y[i],brick_w,brick_h) then
		 	if not brick_hit then
			 	-- check if ball will collide with side of brick
					if deflect_ball_horz(ball_x,ball_y,ball_dx,ball_dy,brick_x[i],brick_y[i],brick_w,brick_h) then
						ball_dx=-ball_dx
					else
						ball_dy=-ball_dy
					end
				end
				brick_hit=true
				hit_brick(i,true)
		 end
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
	 
	check_explosions()
	
	if level_finished() then
		_draw() -- clear any remaining bricks from screen
		level_over()
	end
	
	-- tick powerup timer
	if powerup then
		powerup_time-=1
		if powerup_time<=0 then
			powerup=-1
		end
	end

	-- move pills and pick up powerups
	for i=1,#pill_x do
		if pill_vis[i] then
			pill_y[i]+=0.7
			if pill_y[i]>127 then
				pill_vis[i]=false
			elseif box_hit_box(pill_x[i],pill_y[i],8,6,pad_x,pad_y,pad_w,pad_h) then
				pill_vis[i]=false
				sfx(12)
				get_powerup(pill_type[i])
			end
		end
	end
end


function ball_hit_box(next_ball_x,next_ball_y,box_x,box_y,box_w,box_h)
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


function box_hit_box(box1_x,box1_y,box1_w,box1_h,box2_x,box2_y,box2_w,box2_h)
 -- top of box1 lower than bottom of box2
	if box1_y > box2_y+box2_h then return false
	-- bottom of box1 higher than top of box2
	elseif box1_y+box1_h < box2_y then return false
	-- left of box1 further right than right of box2
	elseif box1_x > box2_x+box2_w then	return false
	-- right of box1 further left than left of box2
 elseif box1_x+box1_h < box2_x then	return false
 end
	return true
end


-- calculate wether to deflect the ball horizontally or not
function deflect_ball_horz(ball_x,ball_y,ball_dx,ball_dy,target_x,target_y,target_w,target_h)
 local slope = ball_dy/ball_dx  -- positive = up left, down right; negative = up right, down left
 local dist_x, dist_y -- distance between ball and target corner
 if ball_dx == 0 then
 	-- moving vertically
  return false
 elseif ball_dy == 0 then
 	-- moving horizontally
  return true
 elseif slope > 0 and ball_dx > 0 then
	 -- moving down right
  dist_x = target_x - ball_x
  dist_y = target_y - ball_y
  return dist_x > 0 and dist_y/dist_x < slope
 elseif slope < 0 and ball_dx > 0 then
  -- moving up right
  dist_x = target_x - ball_x
  dist_y = target_y + target_h - ball_y
  return dist_x > 0 and dist_y/dist_x >= slope
 elseif slope > 0 and ball_dx < 0 then
  -- moving up left
  dist_x = target_x + target_w - ball_x
  dist_y = target_y + target_h - ball_y
  return dist_x < 0 and dist_y/dist_x <= slope
 else
	 -- moving down left
  dist_x = target_x + target_w - ball_x
  dist_y = target_y - ball_y
  return dist_x < 0 and dist_y/dist_x >= slope
 end
end


-- determine the sign (pos/neg) of a given value
function sign(n)
	if n<0 then
		return -1
	elseif n>0 then
		return 1
	else
		return 0
	end
end


function set_ang(angle)
	-- angles:
	-- 0 = 0 < angle < 45
	-- 1 = 45 degree
	-- 2 = 45 < angle < 90
	ball_ang=angle
	-- preserve direction using sign()
	if angle==2 then
		ball_dx=0.5*sign(ball_dx)
		ball_dy=1.3*sign(ball_dy)
	elseif angle==0 then
		ball_dx=1.3*sign(ball_dx)
		ball_dy=0.5*sign(ball_dy)
	else -- angle 1
		ball_dx=1*sign(ball_dx)
		ball_dy=1*sign(ball_dy)
	end
end


function hit_brick(loc,combo)
	if brick_type[loc]=="b" then
		sfx(2+chain) -- combo sound effects go from 3-9
		brick_vis[loc]=false
		points+=10*chain
		if combo then
			chain+=1
			chain=mid(1,chain,7) -- 7 is max combo multiplier
		end
	elseif brick_type[loc]=="i" then
		sfx(10)
	elseif brick_type[loc]=="h" then
		sfx(11)
		-- needs to be hit twice
		-- switch to normal brick
		brick_type[loc]="b"		
	elseif brick_type[loc]=="e" then
		sfx(2+chain)
		brick_type[loc]="zz" -- brick about to explode
		points+=10*chain
		if combo then
			chain+=1
			chain=mid(1,chain,7)
		end
	elseif brick_type[loc]=="p" then
		sfx(2+chain)
		brick_vis[loc]=false
		points+=10*chain
		if combo then
			chain+=1
			chain=mid(1,chain,7)
		end
		spawn_pill(brick_x[loc],brick_y[loc])
	end
end


function spawn_pill(x,y)
	add(pill_x,x)
	add(pill_y,y)
	add(pill_vis,true)
	local typ=flr(rnd(7)) -- choose random powerup
	add(pill_type,typ)
end


function get_powerup(p)
	if p==0 then -- slowdown
	 powerup=0
	 powerup_time=0
	elseif p==1 then -- life
	 powerup=-1 -- powerup is 1 time thing
	 powerup_time=0
	 lives+=1
	elseif p==2 then -- catch/sticky
	 powerup=2
	 powerup_time=900 -- 15 sec
	elseif p==3 then -- expand
	 powerup=3
	 powerup_time=0
	elseif p==4 then -- reduce
	 powerup=4
	 powerup_time=0
	elseif p==5 then -- megaball
	 powerup=5
	 powerup_time=0
	elseif p==6 then -- multiball
		powerup=6
	 powerup_time=0
	end
end


function check_explosions()
	for i=1,#brick_x do
		if brick_vis[i] and brick_type[i]=="zz" then
			brick_type[i]="z"
		end
	end
	
	for i=1,#brick_x do
		if brick_vis[i] and brick_type[i]=="z" then
			explode_brick(i)
		end
	end
	
	for i=1,#brick_x do
		if brick_vis[i] and brick_type[i]=="zz" then
			brick_type[i]="z"
		end
	end
end


function explode_brick(loc)
	brick_vis[loc]=false
	for i=1,#brick_x do
		if i!=loc -- not the exploding brick
		and brick_vis[i]
		and abs(brick_x[i]-brick_x[loc])<=(brick_w+2)
		and abs(brick_y[i]-brick_y[loc])<=(brick_h+2)
		then
			hit_brick(i,false)
		end
	end
end


function level_finished()
	-- no bricks in level
	if #brick_vis==0 then return true end

	for i=1,#brick_vis do
		if brick_vis[i] and brick_type[i]!="i" then
			return false
		end
	end
	return true
end


function level_over()
	mode="level_over"
end


function update_start()
	if btnp(❎) then
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

 brick_x={}
 brick_y={}
 brick_vis={}
 brick_type={}
 brick_w=9
 brick_h=4

	level_num=1
	level=levels[level_num]

 build_bricks(level)

 lives=3
 points=0
	
	sticky=true

	chain=1 -- combo chain multiplier
	
 serve_ball()
end


-- brick types:
--  b = normal
--  x = empty space
--  i = indestructible
--  h = hardened
--  e = exploding
--  p = powerup
function build_bricks(lvl)
	local j=0 -- used for tracking which row to add brick on
	local last
	for i=1,#lvl do
		j+=1
		char=sub(lvl,i,i)
		if char=="b"
		or char=="i"
		or char=="h"
		or char=="e"
		or char=="p" then
			last=char
			add_brick(j,char)
		elseif char=="x" then
			last="x"
		elseif char=="/" then
			-- adjust j to next row
			j=(flr((j-1)/11)+1)*11
		elseif char>="1" and char<="9" then
			for o=1,char+0 do -- add 0 to cast to int
				if last=="b"
				or last=="i"
				or last=="h"
				or last=="e"
				or last=="p" then
					add_brick(j,last)
				elseif last=="x" then
					-- don't add anything (space)
				end
				j+=1
			end
			j-=1 -- negate final j+=1
		end
	end
end


function add_brick(loc,typ)
	-- 4 px padding from left of screen
	-- loc-1 to start at 0 (since lua is 1-based index)
	-- mod 11 (11 bricks per row) to figure out if new row (then start back at left)
	-- add 1 px padding between bricks (but 2 since width + 1 for starting x location)
	add(brick_x,4+((loc-1)%11)*(brick_w+2))
	-- 20 px padding from top of screen
	-- flr(loc/11) to figure out which row brick should be on
	-- add 1 px padding between rows (but 2 since height + 1 for starting y location)
	add(brick_y,20+flr((loc-1)/11)*(brick_h+2))
	add(brick_vis,true)
	add(brick_type,typ)
end


function serve_ball()
	ball_x=pad_x+flr(pad_w/2)
 ball_y=pad_y-ball_r
 ball_dx=1
 ball_dy=-1
 ball_ang=1
 
 reset_pills()
 
 sticky=true
 
 chain=1
 
	powerup=-1
	powerup_time=0
end


function reset_pills()
	pill_x={}
	pill_y={}
	pill_vis={}
	pill_type={}
end


function game_over()
	mode="game_over"
end


function update_game_over()
	if btnp(❎) then
		start_game()
	end
end


function update_level_over()
	if btnp(❎) then
		next_level()
	end
end


function next_level()
	mode="game"

	pad_x=52
 pad_y=120
	pad_dx=0

	level_num+=1
	if level_num>#levels then
		-- beat the game
		mode="start"
		return
	end
	level=levels[level_num]

 build_bricks(level)
	
	sticky=true

	chain=1
	
 serve_ball()
end
-->8
function _draw()
	if mode=="game" then draw_game()
	elseif mode=="start" then draw_start()
	elseif mode=="game_over" then draw_game_over()
	elseif mode=="level_over" then draw_level_over()
	end
end


function draw_game()
 cls(1) -- clear screen and set background color

 circfill(ball_x,ball_y,ball_r,ball_clr)
 rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,pad_clr)

	-- draw ball launch direction arrow
	if sticky then
		line(ball_x+ball_dx*3,ball_y+ball_dy*3,ball_x+ball_dx*5,ball_y+ball_dy*5,10)
	end

	-- draw bricks
	local brick_clr
	for i=1,#brick_x do
		if brick_vis[i] then
			if brick_type[i]=="b" then brick_clr=14
			elseif brick_type[i]=="i" then brick_clr=6
			elseif brick_type[i]=="h" then brick_clr=15
			elseif brick_type[i]=="e" then brick_clr=9
			elseif brick_type[i]=="z" then brick_clr=8 -- exploding brick about to explode
			elseif brick_type[i]=="p" then brick_clr=11
			end
			rectfill(brick_x[i],brick_y[i],brick_x[i]+brick_w,brick_y[i]+brick_h,brick_clr)
		end
	end
	
	-- draw pills (powerups)
	for i=1,#pill_x do
		if pill_vis[i] then
			if pill_type[i]==4 then
				palt(0,false) -- mark black as valid color
				palt(15,true) -- mark tan as "transparent" color
			end
			spr(pill_type[i],pill_x[i],pill_y[i])
			palt() -- reset all colors to default transparency
		end
	end

	-- top bar
 rectfill(0,0,128,6,0)
 if debug!="" then
 	print(debug,1,1,7)
 else
	 print("lives:"..lives,1,1,7)
 	print("points:"..points,50,1,7)
 	print("chain:"..chain.."x",96,1,7)
 end
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


function draw_level_over()
	rectfill(0,60,128,75,0)
	local text="stage clear"
	print(text,hcenter(text),62,7)
	text="press ❎ to continue"
	print(text,hcenter(text),69,6)
end


function hcenter(text)
	-- screen center -
 -- (characters in text's width
 --  * width of a character)
 return 64-(#text*2)
end
__gfx__
06777760067777600677776006777760f677777f0677776006777760000000000000000000000000000000000000000000000000000000000000000000000000
559949955576777555b33bb555c1c1c55508800555e222e555828885000000000000000000000000000000000000000000000000000000000000000000000000
559499955576777555b3bbb555cc1cc55508080555e222e555822885000000000000000000000000000000000000000000000000000000000000000000000000
559949955576777555b3bbb555cc1cc55508800555e2e2e555828285000000000000000000000000000000000000000000000000000000000000000000000000
559499955576677555b33bb555c1c1c55508080555e2e2e555822885000000000000000000000000000000000000000000000000000000000000000000000000
059999500577775005bbbb5005cccc50f500005f05eeee5005888850000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000018360183601834018320183101a3001730015300133001030010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002436024360243402432024310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001d3501c3501a350193501635014350123500f3500c3500835006350043500730005300042000f1000d100081000710000000000000000000000000000000000000000000000000000000000000000000
000200002c36030360303503033033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002d36031360313503133034300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e36032360323503233035300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002f36033360333503333036300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003036034360343503433037300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003136035360353503533038300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003236036360363503633039300000000000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000021360213601c3001c30033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002036024360243502433033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000203102332026330293402c350253001f30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
