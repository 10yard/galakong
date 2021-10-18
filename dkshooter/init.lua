-- DK SHOOTER by Jon Wilson (10yard)
--
-- Tested with latest MAME version 0.235
-- Compatible with MAME versions from 0.196
--
-- Jumpman is assisted by an accompanying ship which can take out barrels, fireballs, firefoxes, pies and springs.  
-- Bonus points are awarded for destroying multiple targets.
--
-- The default mode is single player,  with your ship following Jumpman's position.
-- The jump button also shoots.
-- Jumpman can control the ship independently when he is on a ladder (and breifly when he is smashing an item with the hammer).

-- There is also a 2 player co-op mode where a 2nd player controls the ship using separate controls.
-- 		P1 Start = Left
--      P2 Start = Right
--      Coin     = Fire
--
-- Minimum start up arguments:
--   mame dkong -plugin dkshooter
-----------------------------------------------------------------------------------------

local exports = {}
exports.name = "dkshooter"
exports.version = "0.2"
exports.description = "Donkey Kong Shooter"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local dkshooter = exports

function dkshooter.startplugin()
	-- Set mode of play.  
	-- 1 = Single player mode,  mirrors Jumpman's movements
	-- 2 - Co-op mode,  Ship is controlled with P1 Start, P2 Start and Coin.
	local PLAY_MODE = 1
	
	local ship_y = -10
	local ship_x = 49
	local missile_y
	local missile_x	
	local bonus = 0
	local hit_count = 0
	local last_bonus = 0
	local last_hit_cleanup = 0
	local last_starfield = 0
	
	local enemy_data = 
		{0x6700, 0x6720, 0x6740, 0x6760, 0x6780, 0x67a0, 0x67c0, 0x67e0, 
		 0x6400, 0x6420, 0x6440, 0x6460, 0x6480, 
		 0x6500, 0x6510, 0x6520, 0x6530, 0x6540, 0x6550, 0x6550,
		 0x65a0, 0x65b0, 0x65c0, 0x65d0, 0x65e0, 0x65f0}

	WHITE = 0xffdedede
	RED = 0xffff0000
	BLUE = 0xff0068de	
	
	local char_table = {}
	char_table["0"] = 0x00
	char_table["1"] = 0x01
	char_table["2"] = 0x02
	char_table["3"] = 0x03
	char_table["4"] = 0x04
	char_table["5"] = 0x05
	char_table["6"] = 0x06
	char_table["7"] = 0x07
	char_table["8"] = 0x08
	char_table["9"] = 0x09
	char_table[" "] = 0x10

	
	function initialize()
		mame_version = tonumber(emu.app_version())
		if mame_version >= 0.227 then
			cpu = manager.machine.devices[":maincpu"]
			scr = manager.machine.screens[":screen"]
		elseif mame_version >= 0.196 then
			cpu = manager:machine().devices[":maincpu"]
			scr = manager:machine().screens[":screen"]
		else
			print("------------------------------------------------------------")
			print("The dkshooter plugin requires MAME version 0.196 or greater.")
			print("------------------------------------------------------------")
		end
		if cpu ~= nil then
			mem = cpu.spaces["program"]
			change_text()

			--Generate a starfield
			number_of_stars = 300
			starfield={}
			math.randomseed(os.time())
			for _=1, number_of_stars do
				table.insert(starfield, math.random(255))
				table.insert(starfield, math.random(223))
				table.insert(starfield, 0xff * (math.random(64) + 192) * (math.random(64) + 192) * (math.random(64) + 192))
			end
		end
	end

	function main()
		if cpu ~= nil then
			local mode1 = mem:read_u8(0x6005)  -- 1-attract mode, 2-credits entered waiting to start, 3-when playing game
			local mode2 = mem:read_u8(0x600a)  -- Status of note: 7-climb scene, 10-how high, 15-dead, 16-game over
			local stage = mem:read_u8(0x6227)  -- 1-girders, 2-pie, 3-elevator, 4-rivets
			
			draw_stars()			
						
			-- During gameplay
			---------------------------------------------------------------------------------
			if mode2 == 0xc or mode2 == 0xb or mode2 == 0xd then
				local jumpman_x = mem:read_u8(0x6203) - 15
				local jumpman_y = mem:read_u8(0x6205)
				local left, right, fire = get_inputs()		
				if mode2 == 0xb then
					-- reset ship, missiles and bonus
					ship_x = 49
					missile_y = nil
					bonus = 0
				elseif mode2 == 0xc then
					-- adjust ship y with jumpman when at screen bottom
					ship_y = 230 - jumpman_y
					if ship_y > 0 then
						ship_y = 0
					end
				elseif mode2 == 0xd then
					-- animate ship downwards
					if ship_y >= -8 then
						ship_y = ship_y - 0.5
					end
				end
												
				-- move ship
				if PLAY_MODE == 1 and mem:read_u8(0x6215) ~= 1 and mem:read_u8(0x6350) ~= 1 then
					-- The ship follows Jumpman X position unless on a ladder
					if ship_x < jumpman_x then
						ship_x = ship_x + 1
					elseif ship_x > jumpman_x then
						ship_x = ship_x - 1
					end
				else
					if left and ship_x >= 7 then 
						ship_x = ship_x - 1
					end
					if right and ship_x <= 216 then
						ship_x = ship_x + 1
					end	
				end

				if mode2 == 0xc then
					-- fire a missile
					if fire and not missile_y then
						missile_y = ship_y
						missile_x = ship_x
						hit_count = 0
						--play boom sound in co-op mode.
						if PLAY_MODE == 2 then
							mem:write_u8(0x6082, 3)
						end
					end
										
					-- animate the missile
					if missile_y ~= nil then
						-- check for enemy hit
						for _, address in pairs(enemy_data) do
							local b_status, enemy_x, enemy_y = mem:read_u8(address), mem:read_u8(address + 3) - 15, 256 - mem:read_u8(address + 5)
							if b_status ~= 0 and enemy_y < 256 then
								if missile_y > enemy_y - 7 and missile_y < enemy_y + 7 and missile_x > enemy_x - 7 and missile_x < enemy_x + 7 then
									hit_count = hit_count + 1	
									
									if (address >= 0x6400 and address < 0x6500) or (address >= 0x65a0 and address < 0x6600) then
										-- destroy a fireball, firefox or pie
										mem:write_u8(address + 6, 1)   -- flag an unused address for later cleanup								
										mem:write_u8(address+7, 0x53)  -- switch to blank sprites										
										last_hit_cleanup = os.clock()
										missile_y = missile_y + 10     -- move missile further to prevent double-hit
									elseif address >= 0x6500 and address < 0x65a0 then
										-- destory a spring, err, move the spring off screen
										mem:write_u8(address + 3, 2)
										mem:write_u8(address + 5, 80)										
									else
										-- destroy a barrel
										mem:write_u8(address + 3, 0)
										mem:write_u8(address + 5, 0)
									end
									
									-- play bonus sound
									mem:write_u8(0x6085, 0)
									mem:write_u8(0x6085, 1)
									
									-- calculate bonus for destroying multiple enemies.
									if hit_count == 1 then
										bonus = 300
										sprite = 0x7d
									elseif hit_count == 2 then 
										bonus = 200  -- +200 = 500 total
										sprite = 0x7e
									elseif hit_count == 3 then  -- stop awarding when 800 points is reached 
										bonus = 300  -- +300 = 800 total
										sprite = 0x7f
									else 
										bonus = 0
									end
																	
									if bonus > 0 then
										--display bonus points
										mem:write_u8(0x6a30, missile_x + 15)
										mem:write_u8(0x6a31, sprite)
										mem:write_u8(0x6a32, 0x07)
										mem:write_u8(0x6a33, 256 - missile_y)
										last_bonus = os.clock()
									
										--update score in ram
										score = string.format("%06d", tonumber(get_score_segment(0x60b4)..get_score_segment(0x60b3)..get_score_segment(0x60b2)) + bonus)
										set_score_segment(0x60b4, string.sub(score, 1,2))
										set_score_segment(0x60b3, string.sub(score, 3,4))
										set_score_segment(0x60b2, string.sub(score, 5,6))
										-- update score on screen
										write_message(0xc7781, score) 
									end
								end
							end
						end		
										
						draw_missile(missile_y, missile_x)
						missile_y = missile_y + 5
						if missile_y >= 240 then
							missile_y = nil
							bonus = 0
						end
					end
				end
				
				-- Clean up any destroyed fireballs
				if os.clock() - last_hit_cleanup > 0.25 then
					for _, address in pairs(enemy_data) do
						if mem:read_u8(address + 6) == 1 then
							mem:write_u8(address, 0)
							mem:write_u8(address + 6, 0)
							mem:write_u8(address + 7, 0x4d)							
						end
					end
				end
								
				-- clear awarded point sprites
				if last_bonus ~= 0 and os.clock() - last_bonus > 1 then
					mem:write_u8(0x6a30, 0x0)
					last_bonus = 0
				end
				
				draw_ship(ship_y, ship_x)
			end
		end
	end

	function get_inputs()
		left, right, fire = false, false, false
		if PLAY_MODE == 2 then
			input = mem:read_u8(0xc7d00)
			if input >= 128 then
				fire = true
				input = input - 128
			end		
			if input == 4 then
				left = true
			end
			if input == 8 then
				right = true
			end
		else
			input = mem:read_u8(0xc7c00)
			if input >= 16 and input <= 31 then
				fire = true
				input = input - 16
			end
			if input == 2 then
				left = true
			end
			if input == 1 then
				right = true
			end
		end
		return left, right, fire
	end

	function version_draw_box(y1, x1, y2, x2, c1, c2)
		-- Handle the version specific syntax of draw_box
		if mame_version >= 0.227 then
			scr:draw_box(y1, x1, y2, x2, c2, c1)
		else
			scr:draw_box(y1, x1, y2, x2, c1, c2)
		end
	end

	function draw_missile(y, x)
		version_draw_box(y+4, x-1, y+6, x+2, 0xff0000ff, 0xff0000ff)
		version_draw_box(y, x, y+4, x+1, 0xffff0000, 0xffff0000)
		version_draw_box(y+4, x, y+5, x+1, 0xffffffff, 0xffffffff)
		version_draw_box(y+5, x, y+8, x+1, 0xff0000ff, 0xff0000ff)
	end

	function draw_ship(y, x)
		-- y, x relates to gun of ship.
		-- _y, _x relates to bottom left corner
		local _y = y
		local _x = x - 7
		version_draw_box(_y+2, _x+6, _y+13, _x+9, WHITE, WHITE)
		version_draw_box(_y, _x+7, _y+16, _x+8, WHITE, WHITE)
		version_draw_box(_y+3, _x+3, _y+8, _x+12, WHITE, WHITE)
		version_draw_box(_y+8, _x+5, _y+9, _x+10, WHITE, WHITE)
		version_draw_box(_y+2, _x+7, _y+3, _x+9, WHITE, WHITE)		
		version_draw_box(_y, _x, _y+8, _x+1, WHITE, WHITE)
		version_draw_box(_y, _x+14, _y+8, _x+15, WHITE, WHITE)
		version_draw_box(_y+1, _x+1, _y+4, _x+2, WHITE, WHITE)
		version_draw_box(_y+2, _x+2, _y+5, _x+3, WHITE, WHITE)
		version_draw_box(_y+1, _x+13, _y+4, _x+14, WHITE, WHITE)
		version_draw_box(_y+2, _x+12, _y+5, _x+13, WHITE, WHITE)
		version_draw_box(_y+6, _x, _y+8, _x+1, RED, RED)
		version_draw_box(_y+6, _x+14, _y+8, _x+15, RED, RED)
		version_draw_box(_y+6, _x+14, _y+8, _x+15, RED, RED)
		version_draw_box(_y+8, _x+3, _y+10, _x+4, RED, RED)
		version_draw_box(_y+8, _x+11, _y+10, _x+12, RED, RED)
		version_draw_box(_y+1, _x+4, _y+3, _x+6, RED, RED)
		version_draw_box(_y+1, _x+9, _y+3, _x+11, RED, RED)
		version_draw_box(_y+3, _x+5, _y+4, _x+6, RED, RED)
		version_draw_box(_y+3, _x+9, _y+4, _x+10, RED, RED)
		version_draw_box(_y+5, _x+6, _y+7, _x+7, RED, RED)
		version_draw_box(_y+6, _x+7, _y+8, _x+8, RED, RED)
		version_draw_box(_y+5, _x+8, _y+7, _x+9, RED, RED)
		version_draw_box(_y+6, _x+3, _y+7, _x+4, BLUE, BLUE)
		version_draw_box(_y+7, _x+4, _y+8, _x+5, BLUE, BLUE)
		version_draw_box(_y+6, _x+11, _y+7, _x+12, BLUE, BLUE)
		version_draw_box(_y+7, _x+10, _y+8, _x+11, BLUE, BLUE)
	end

	function draw_stars()
		-- draw the starfield background
		local _starfield = starfield
	  	local _ypos, _xpos = 0, 0
		
		for key=1, number_of_stars, 3 do
			_ypos, _xpos, _col = _starfield[key], _starfield[key+1], _starfield[key+2]
			version_draw_box(_ypos, _xpos, _ypos+1, _xpos+1, _col, _col)

			--do we regenerate the starfield colours
			if os.clock() - last_starfield > 0.25 then
				_starfield[key+2] = 0xff * (math.random(64) + 192) * (math.random(64) + 192) * (math.random(64) + 192)
			end

						
			--slowly scroll the starfield
			_starfield[key] = _starfield[key] - 0.5
			if _starfield[key] < 0 then
				_starfield[key] = 256
			end
		end

		if os.clock() - last_starfield > 0.25 then
			last_starfield = os.clock()
		end

	end
	
	function int_to_bin(x)
		-- convert integer to binary
		local ret = ""
		while x~=1 and x~=0 do
			ret = tostring(x%2) .. ret
			x=math.modf(x/2)
		end
		ret = tostring(x)..ret
		return string.format("%08d", ret)
    end	
	
	function write_message(start_address, text)
		-- write characters of message to DK's video ram
		local _char_table = char_table
		for key=1, string.len(text) do
			mem:write_u8(start_address - ((key - 1) * 32), _char_table[string.sub(text, key, key)])
		end
	end	
	
	function get_score_segment(address)
		return string.format("%02d", string.format("%x", mem:read_u8(address)))
	end

	function set_score_segment(address, segment)
		mem:write_u8(address, tonumber(segment, 16))
	end
	
	function change_text()
		if emu.romname() == "dkong" then
			-- Change high score text in rom to DK SHOOTER
			for k, i in pairs({0x14,0x1b,0x10,0x23,0x18,0x1f,0x1f,0x24,0x15,0x22}) do
				mem:write_direct_u8(0x36b4 + k - 1, i)
			end
			-- Change "HOW HIGH CAN YOU GET" text in rom to "HOW UP CAN YOU SCHMUP ?"
			for k, i in pairs({0x18,0x1f,0x27,0x10,0x25,0x20,0x10,0x13,0x11,0x1e,0x10,0x29,0x1f,0x25,0x10,0x23,0x13,0x18,0x1d,0x25,0x20,0x10,0xfb}) do
				mem:write_direct_u8(0x36ce + k - 1, i)
			end
		end
	end
	
	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")

end
return exports