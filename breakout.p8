pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 cls()
 
 mode="start"
 
 levels={}
 levels[1]="b9b/b9b"
 levels[2]="bxbxbxbxb"
 level_num=1
 
 shake_str=0 -- strength of screenshake
	
	blink_grn=7
	blink_grn_idx=1
	blink_gry=6
	blink_gry_idx=1
	blink_frame=0
	blink_speed=7
	
	start_countdown=-1
	game_over_countdown=-1
	
	fade_prct=0
	
	arrow_mult=1
	arrow_mult2=1
	arrow_frame=0
	arrow_frame2=0
	
	particles={}
 
 debug=""
end
-->8
function _update60()
	blink()
	screenshake()
	update_particles()
	if mode=="game" then update_game()
	elseif mode=="start" then update_start()
	elseif mode=="game_over_wait" then update_game_over_wait()
	elseif mode=="game_over" then update_game_over()
	elseif mode=="level_over" then update_level_over()
	end
end


function update_game()
	-- fade in
	if fade_prct>0 then
		fade_prct-=0.05
		if fade_prct<0 then
			fade_prct=0
		end
	end

	-- pad update
	
	-- update pad width from powerups
	if timer_expand>0 then
		-- expand powerup
		pad_w=flr(pad_w_orig*1.5)
	elseif timer_reduce>0 then
		-- reduce powerup
		pad_w=flr(pad_w_orig/2)
		point_mult=2
	else
		pad_w=pad_w_orig
		point_mult=1
	end
	
	local button_pressed=false
 if btn(⬅️) then
 	pad_dx=-2.5
 	button_pressed=true
 	point_stuck_balls(-1)
 end
 if btn(➡️) then
 	pad_dx=2.5
 	button_pressed=true
 	point_stuck_balls(1)
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
	if btnp(❎) then
		release_stuck_balls() 
	end

	-- update balls
	for i=#balls,1,-1 do
		update_ball(i)
	end
	 
	check_explosions()
	
	if level_finished() then
		_draw() -- clear any remaining bricks from screen
		level_over()
	end
	
	-- tick powerup timers
	if timer_slowdown>0 then
		timer_slowdown-=1
	elseif timer_expand>0 then
		timer_expand-=1
	elseif timer_reduce>0 then
		timer_reduce-=1
	elseif timer_megaball>0 then
		timer_megaball-=1
	end

	-- move pills and pick up powerups
	for i=#pills,1,-1 do
		pills[i].y+=0.7
		if pills[i].y>127 then
			del(pills,pills[i])
		elseif box_hit_box(pills[i].x,pills[i].y,8,6,pad_x,pad_y,pad_w,pad_h) then
			sfx(12)
			get_powerup(pills[i].type)
			del(pills,pills[i])
		end
	end
end

function update_ball(ball_idx)
	b=balls[ball_idx]
	if b.stuck then
		-- ball stuck to pad
		b.x=pad_x+sticky_x
	 b.y=pad_y-ball_r-1
	else
		-- normal ball collision physics
	 
	 if timer_slowdown>0 then
	 	-- slowdown
	 	next_x=b.x+(b.dx/2)
	 	next_y=b.y+(b.dy/2)
	 else
	  next_x=b.x+b.dx
		 next_y=b.y+b.dy
	 end
	
	 -- check if ball collides with walls
	 if next_x > 125 or next_x < 3 then
	  next_x=mid(3,next_x,125) -- make sure ball never leaves screen
	  b.dx=-b.dx
	  sfx(0)
	 end
	 if next_y < 9 then
		 next_y=mid(9,next_y,127) -- make sure ball never leaves screen
	  b.dy=-b.dy
	  sfx(0)
	 end
	
	 -- check if ball will collide with pad
	 if ball_hit_box(next_x,next_y,pad_x,pad_y,pad_w,pad_h) then
	 	-- check if ball will collide with side of pad
			if deflect_ball_horz(b.x,b.y,b.dx,b.dy,pad_x,pad_y,pad_w,pad_h) then
				-- ball hit paddle on side
				b.dx=-b.dx
				if b.x < pad_x+pad_w/2 then
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
				b.dy=-b.dy
				if b.y > pad_y then
					-- ball hit paddle from below
					-- reset ball to below paddle
					next_y=pad_y+pad_h+ball_r
				else
					-- ball hit paddle from above
					-- reset ball to above paddle
					next_y=pad_y-ball_r
					if abs(pad_dx)>2 then
						-- pad is moving fast enough to change angle
						if sign(pad_dx)==sign(b.dx) then
							-- paddle is moving in same direction as ball
							-- give low angle
							set_ang(b,mid(0,b.ang-1,2))
						else
							-- paddle is moving in opposite direction
							-- give steeper angle
							if b.ang==2 then
								-- change ball direction since we're already at steepest angle
								b.dx=-b.dx
							else
								set_ang(b,mid(0,b.ang+1,2))
							end
						end
					end
				end
			end
			
			sfx(1)
			chain=1
			
			-- catch/sticky powerup
			if sticky and b.dy<0 then
				release_stuck_balls()
				sticky=false
				b.stuck=true
				sticky_x=b.x-pad_x
			end
	 end
	
	 brick_hit=false
	 for i=1,#bricks do
			-- check if ball will collide with brick
		 if bricks[i].vis and ball_hit_box(next_x,next_y,bricks[i].x,bricks[i].y,brick_w,brick_h) then
		 	if not brick_hit then
			 	if (timer_megaball>0 and bricks[i].type=="i") -- megaball and indestructible brick
			 	or timer_megaball<=0
			 	then
			 		-- check if ball will collide with side of brick
						if deflect_ball_horz(b.x,b.y,b.dx,b.dy,bricks[i].x,bricks[i].y,brick_w,brick_h) then
							b.dx=-b.dx
						else
							b.dy=-b.dy
						end
			 	end
				end
				brick_hit=true
				hit_brick(i,true)
		 end
		end
	
	 b.x=next_x
	 b.y=next_y
	 
	 spawn_ball_trail(next_x,next_y)
	
	 -- check if ball is out of bounds after its moved
	 if next_y > 127 then
	 	sfx(2)
	 	if #balls>1 then
		 	shake_str+=0.15
	 		del(balls,b)
	 	else
		 	shake_str+=0.4
	 		lives-=1
		 	if lives<0 then
		 		game_over()
		 	else
			 	serve_ball()
			 end
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


function set_ang(ball,angle)
	-- angles:
	-- 0 = 0 < angle < 45
	-- 1 = 45 degree
	-- 2 = 45 < angle < 90
	ball.ang=angle
	-- preserve direction using sign()
	if angle==2 then
		ball.dx=0.5*sign(ball.dx)
		ball.dy=1.3*sign(ball.dy)
	elseif angle==0 then
		ball.dx=1.3*sign(ball.dx)
		ball.dy=0.5*sign(ball.dy)
	else -- angle 1
		ball.dx=1*sign(ball.dx)
		ball.dy=1*sign(ball.dy)
	end
end


function release_stuck_balls()
	for i=1,#balls do
		if balls[i].stuck then
			balls[i].x=mid(3,balls[i].x,125) -- make sure ball doesn't launch offscreen
			balls[i].stuck=false
		end
	end
end


-- point balls stuck to pad in correct direction
-- based on pad movement (input sign)
function point_stuck_balls(sign)
	for i=1,#balls do
		if balls[i].stuck then
			-- strip dx sign and use pad's sign instead
			balls[i].dx=abs(balls[i].dx)*sign
		end
	end
end


function hit_brick(loc,combo)
	if bricks[loc].type=="b" then
		-- normal
		sfx(2+chain) -- combo sound effects go from 3-9
		shatter_brick(bricks[loc])
		bricks[loc].vis=false
		points+=10*chain*point_mult
		if combo then
			chain+=1
			chain=mid(1,chain,7) -- 7 is max combo multiplier
		end
	elseif bricks[loc].type=="i" then
		-- indestructible
		sfx(10)
	elseif bricks[loc].type=="h" then
		-- hardened
		if timer_megaball>0 then
			sfx(2+chain) -- combo sound effects go from 3-9
			bricks[loc].vis=false
			points+=10*chain*point_mult
			if combo then
				chain+=1
				chain=mid(1,chain,7) -- 7 is max combo multiplier
			end
		else
			sfx(11)
			-- needs to be hit twice
			-- switch to normal brick
			bricks[loc].type="b"
		end		
	elseif bricks[loc].type=="e" then
		-- exploding
		sfx(2+chain)
		bricks[loc].type="zz" -- brick about to explode
		points+=10*chain*point_mult
		if combo then
			chain+=1
			chain=mid(1,chain,7)
		end
	elseif bricks[loc].type=="p" then
		-- powerup
		sfx(2+chain)
		shatter_brick(bricks[loc])
		bricks[loc].vis=false
		points+=10*chain*point_mult
		if combo then
			chain+=1
			chain=mid(1,chain,7)
		end
		spawn_pill(bricks[loc].x,bricks[loc].y)
	end
end


function spawn_pill(x,y)
	local pill={}
	pill.x=x
	pill.y=y
	local typ=flr(rnd(7)) -- choose random powerup
	pill.type=typ
	add(pills,pill)
end


function get_powerup(p)
	if p==0 then -- slowdown
	 timer_slowdown=900 -- 15 sec
	elseif p==1 then -- life
	 lives+=1
	elseif p==2 then -- catch/sticky
	 -- check to see if there's already a ball stuck
	 -- if not, catch the next ball
	 local has_stuck=false
	 for i=1,#balls do
	 	if balls[i].stuck then
	 		has_stuck=true
	 	end
	 end
	 if not has_stuck then
	 	sticky=true
	 end
	elseif p==3 then -- expand
	 timer_expand=900 -- 15 sec
	 timer_reduce=0 -- mutually exclusive
	elseif p==4 then -- reduce
	 timer_reduce=900 -- 15 sec
	 timer_expand=0 -- mutually exclusive
	elseif p==5 then -- megaball
	 timer_megaball=900 -- 15 sec
	elseif p==6 then -- multiball
	 multiball()
	end
end


function multiball()
	local idx=flr(rnd(#balls))+1 -- choose random ball as source for multiball
	local orig_ball=balls[idx] -- ball being copied, source of multiball
	local ball2=copy_ball(orig_ball)
	local ball3=copy_ball(orig_ball)
	
	-- adjust angles of new balls
	if orig_ball.ang==0 then
		set_ang(ball2,1)
		set_ang(ball3,2)
	elseif orig_ball.ang==1 then
		set_ang(ball2,0)
		set_ang(ball3,2)
	else -- orig_ball.ang==2
		set_ang(ball2,0)
		set_ang(ball3,1)
	end
	
	-- make sure new balls aren't stuck to pad
	ball2.stuck=false
	ball3.stuck=false
	
	add(balls,ball2)
	add(balls,ball3)
end


function copy_ball(orig_ball)
	local ball={}
	ball.x=orig_ball.x
	ball.y=orig_ball.y
	ball.dx=orig_ball.dx
	ball.dy=orig_ball.dy
	ball.ang=orig_ball.ang
	ball.stuck=orig_ball.stuck
	return ball
end


function check_explosions()
	for i=1,#bricks do
		if bricks[i].vis and bricks[i].type=="zz" then
			bricks[i].type="z"
		end
	end
	
	for i=1,#bricks do
		if bricks[i].vis and bricks[i].type=="z" then
			explode_brick(i)
			shake_str+=0.25
			-- cap explosion screenshake
			if shake_str>1 then
				shake_str=1
			end
		end
	end
	
	for i=1,#bricks do
		if bricks[i].vis and bricks[i].type=="zz" then
			bricks[i].type="z"
		end
	end
end


function explode_brick(loc)
	bricks[loc].vis=false
	for i=1,#bricks do
		if i!=loc -- not the exploding brick
		and bricks[i].vis
		and abs(bricks[i].x-bricks[loc].x)<=(brick_w+2)
		and abs(bricks[i].y-bricks[loc].y)<=(brick_h+2)
		then
			hit_brick(i,false)
		end
	end
end


function level_finished()
	-- no bricks in level
	if #bricks==0 then return true end

	for i=1,#bricks do
		if bricks[i].vis and bricks[i].type!="i" then
			return false
		end
	end
	return true
end


function level_over()
	mode="level_over"
end


function update_start()
	if start_countdown<0 then -- haven't started game yet
		if btnp(❎) then
			start_countdown=80
			blink_speed=1
			sfx(13)
		end
	else -- game starting
		start_countdown-=1
		fade_prct=(80-start_countdown)/80 -- link fade and countdown lengths
		if start_countdown<=0 then
			start_countdown=-1
			blink_speed=8
			start_game()
		end
	end
end


function start_game()
	mode="game"

 ball_r=2
 ball_clr=10

 pad_x=52
 pad_y=120
 pad_w=24 -- current pad width (including powerups)
 pad_w_orig=24 -- base pad width
 pad_h=3
	pad_dx=0
 pad_clr=7
 
	level_num=1
	level=levels[level_num]
 bricks={}
 brick_w=9
 brick_h=4
 build_bricks(level)

 lives=3
 points=0

	chain=1 -- combo chain multiplier
	point_mult=1 -- powerup multiplier
	
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
	local brick={}
	-- 4 px padding from left of screen
	-- loc-1 to start at 0 (since lua is 1-based index)
	-- mod 11 (11 bricks per row) to figure out if new row (then start back at left)
	-- add 1 px padding between bricks (but 2 since width + 1 for starting x location)
	brick.x=4+((loc-1)%11)*(brick_w+2)
	-- 20 px padding from top of screen
	-- flr(loc/11) to figure out which row brick should be on
	-- add 1 px padding between rows (but 2 since height + 1 for starting y location)
	brick.y=20+flr((loc-1)/11)*(brick_h+2)
	brick.vis=true
	brick.type=typ
	add(bricks,brick)
end


function serve_ball()
	balls={}
	balls[1]=new_ball()
	balls[1].x=pad_x+flr(pad_w/2)
 balls[1].y=pad_y-ball_r
 balls[1].dx=1
 balls[1].dy=-1
 balls[1].ang=1
 balls[1].stuck=true
 
 reset_pills()
 
 sticky=false
 sticky_x=flr(pad_w/2)

	timer_slowdown=0
	timer_expand=0
	timer_reduce=0
	timer_megaball=0
 
 chain=1
end


function new_ball()
	local ball={}
	ball.x=0
 ball.y=0
 ball.dx=0
 ball.dy=0
 ball.ang=1
 ball.stuck=false
 return ball
end


function reset_pills()
	pills={}
end

function update_game_over_wait()
	game_over_countdown-=1
	if game_over_countdown<=0 then
		game_over_countdown=-1
		mode="game_over"
	end
end


function game_over()
	mode="game_over_wait"
	game_over_countdown=60
	blink_speed=12
end


function update_game_over()
	if game_over_countdown<0 then
		if btnp(❎) then
			game_over_countdown=80
			blink_speed=1
			sfx(13)
		end
	else
		game_over_countdown-=1
		fade_prct=(80-game_over_countdown)/80 -- link fade and countdown lengths
		if game_over_countdown<=0 then
			game_over_countdown=-1
			blink_speed=8
			start_game()
		end
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
 
 sticky=false

	chain=1
	
 serve_ball()
end
-->8
function _draw()
	if mode=="game" then draw_game()
	elseif mode=="start" then draw_start()
	elseif mode=="game_over_wait" then draw_game() -- wait for screenshake to finish
	elseif mode=="game_over" then draw_game_over()
	elseif mode=="level_over" then draw_level_over()
	end
	
	pal() -- reset palette
	-- fade screen
	if fade_prct>0 then
		fade_palette(fade_prct)
	end
end


function draw_game()
 cls()
 rectfill(0,0,127,127,1) -- set background color

	-- bricks
	local brick_clr
	for i=1,#bricks do
		if bricks[i].vis then
			if bricks[i].type=="b" then
				brick_clr=14
			elseif bricks[i].type=="i" then
				brick_clr=6
			elseif bricks[i].type=="h" then
				brick_clr=15
			elseif bricks[i].type=="e" then
				brick_clr=9
			elseif bricks[i].type=="z" or bricks[i].type=="zz" then -- exploding brick about to explode
				brick_clr=8
			elseif bricks[i].type=="p" then
				brick_clr=11
			end
			rectfill(bricks[i].x,bricks[i].y,bricks[i].x+brick_w,bricks[i].y+brick_h,brick_clr)
		end
	end

	draw_particles()
	
	-- pills (powerups)
	for i=1,#pills do
		if pills[i].type==4 then
			palt(0,false) -- mark black as valid color
			palt(15,true) -- mark tan as "transparent" color
		end
			spr(pills[i].type,pills[i].x,pills[i].y)
			palt() -- reset all colors to default transparency
	end

	-- balls
	for i=1,#balls do
 	circfill(balls[i].x,balls[i].y,ball_r,ball_clr)
		if balls[i].stuck then
			-- draw trajectory preview
			pset(
				balls[i].x+balls[i].dx*4*arrow_mult,
				balls[i].y+balls[i].dy*4*arrow_mult,
				10
			)
			pset(
				balls[i].x+balls[i].dx*4*arrow_mult2,
				balls[i].y+balls[i].dy*4*arrow_mult2,
				10
			)
		end
	end

	-- pad
 rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,pad_clr)

	-- top bar
 rectfill(0,0,128,6,0)
 if debug!="" then
 	print(debug,1,1,7)
 else
	 print("lives:"..lives,1,1,7)
 	print("points:"..points,40,1,7)
 	print("chain:"..chain.."x",96,1,7)
 end
end


function draw_start()
	cls()
	local text="breakout"
	print(text,hcenter(text),40,7)
	text="press ❎ to start"
	print(text,hcenter(text),80,blink_grn)
end


function draw_game_over()
	rectfill(0,60,128,75,0)
	local text="game over"
	print(text,hcenter(text),62,7)
	text="press ❎ to restart"
	print(text,hcenter(text),69,blink_gry)
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
-->8
function screenshake()
	-- random number between -16 and 16
	local shake_x=16-rnd(32)
	local shake_y=16-rnd(32)
	
	shake_x=shake_x*shake_str
	shake_y=shake_y*shake_str
	
	camera(shake_x,shake_y)
	
	-- reduce screenshake every frame
	shake_str=shake_str*0.95
	
	-- make sure we actually stop screenshaking eventually
	if shake_str<0.05 then
		shake_str=0
	end
end

function blink()
	-- text blinking
	local grn_color_map={3,11,7,11}
	local gry_color_map={5,6,7,6}
	blink_frame+=1
	if blink_frame>blink_speed then
		blink_frame=0

		blink_grn_idx+=1
		if blink_grn_idx>#grn_color_map then
			blink_grn_idx=1
		end
		blink_grn=grn_color_map[blink_grn_idx]

		blink_gry_idx+=1
		if blink_gry_idx>#gry_color_map then
			blink_gry_idx=1
		end
		blink_gry=gry_color_map[blink_gry_idx]		
	end
	
	-- trajectory preview animation
	-- first dot
	arrow_frame+=1
	if arrow_frame>30 then
		arrow_frame=0
	end
	arrow_mult=1+(1.5*(arrow_frame/30))
	-- second dot
	arrow_frame2=arrow_frame+15 -- where current arrow_frame would be in 15 frames
	if arrow_frame2>30 then
		-- reset back to lowest point
		arrow_frame2=arrow_frame2-30
	end
	arrow_mult2=1+(1.5*(arrow_frame2/30))
end

function fade_palette(prct)
	-- 0 = normal
	-- 1 = completely black
	
	local j_max,clr
	
	-- turn prct into valid percentage number.
	-- how dark a color should get.
	local percent=flr(mid(0,prct,1)*100)
	
	-- palette shifting array.
	-- faded color version for every color.
	-- color 1 becomes 0
	-- color 2 becomes 1
	-- color 3 becomes 1
	-- etc
	local faded_palette={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}
	
	-- loop through all colors
	for i=1,15 do
		clr=i
		-- calculate how many times we
		-- want to fade the color.
		-- when j_max reaches 5, every
		-- color is turned to black.
	 j_max=(percent+(i*1.46))/22
	 
	 -- send color through faded_palette
	 -- j_max times to derive final color.
	 for j=1,j_max do
	 	clr=faded_palette[clr]
	 end
	 -- change palette color
	 pal(i,clr,1)
	end
end


function add_particle(x,y,dx,dy,typ,max_age,clr_array)
	local p={}
	p.x=x
	p.y=y
	p.dx=dx
	p.dy=dy
	p.type=typ
	p.max_age=max_age
	p.age=0
	p.clr_array=clr_array
	p.clr=0
	add(particles,p)
end


function update_particles()
	local p
	for i=#particles,1,-1 do
		p=particles[i]
		p.age+=1
		if p.age>p.max_age then
			del(particles,p)
		else
			-- change colors
			if #p.clr_array==1 then
				p.clr=p.clr_array[1]
			else
				-- 0 = just "born"
				-- 1 = going to die
				local clr_idx=p.age/p.max_age -- percent through life
				clr_idx=1+flr(clr_idx*#p.clr_array) -- color corresponding to that percentage, +1 since 1-indexed arrays
				p.clr=p.clr_array[clr_idx]
			end
			-- apply gravity
			if p.type==1 then
				p.dy+=0.1
			end
			
			-- move particle
			p.x+=p.dx
			p.y+=p.dy
		end
	end
end


-- particle types
-- 0 = ball
-- 1 = brick
function draw_particles()
	local p
	for i=1,#particles do
		p=particles[i]
		if p.type==0 then
			-- ball particle
			pset(p.x,p.y,p.clr)
		elseif  p.type==1 then
			-- brick particle
			pset(p.x,p.y,p.clr)
		end
	end
end


function spawn_ball_trail(x,y)
	if rnd()<0.5 then -- spawn half as many particles
		local ang=rnd() -- random angle
		-- add offset to x/y so particles
		-- appear randomly behind ball
		local offset_x=sin(ang)*ball_r*0.3
		local offset_y=cos(ang)*ball_r*0.3
		add_particle(
			x+offset_x,
			y+offset_y,
			0, -- dx
			0, -- dy
			0, -- type
			8+rnd(15), -- add rnd so trail "trails off" at end
			{10,9} -- color_map
		)
	end
end


function shatter_brick(brick)
	for i=1,10 do
		local ang=rnd() -- random angle
		-- random dx/dy
		local dx=sin(ang)
		local dy=cos(ang)
		add_particle(
			brick.x,
			brick.y,
			dx,
			dy,
			1, -- type
			60, -- max_age
			{7} -- color_map
		)
	end
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
000400001b3701d3701f36021360233502535027340293402b3302d3302f320313203331035310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
