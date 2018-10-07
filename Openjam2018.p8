pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--
-- config
--

config = {
    menu = {tl = "menu"},
    play = {tl = "play"},
    pause = {tl = "pause"},
}

--
-- useful functions
--

function jump()
    if btn(2) or btn(5) then
        return true end
end

-- cool print (outlined, scaled)

function cosprint(text, x, y, height, color)
    -- save first line of image
    local save={}
    for i=1,96 do save[i]=peek4(0x6000+(i-1)*4) end
    memset(0x6000,0,384)
    print(text, 0, 0, 7)
    -- restore image and save first line of sprites
    for i=1,96 do local p=save[i] save[i]=peek4((i-1)*4) poke4((i-1)*4,peek4(0x6000+(i-1)*4)) poke4(0x6000+(i-1)*4, p) end
    -- cool blit
    pal() pal(7,0)
    for i=-1,1 do for j=-1,1 do sspr(0, 0, 128, 6, x+i, y+j, 128 * height / 6, height) end end
    pal(7,color)
    sspr(0, 0, 128, 6, x, y, 128 * height / 6, height)
    -- restore first line of sprites
    for i=1,96 do poke4(0x0000+(i-1)*4, save[i]) end
    pal()
end

-- cool print (centered, outlined, scaled)

function csprint(text, y, height, color)
    local x = 64 - (2 * #text - 0.5) * height / 6
    cosprint(text, x, y, height, color)
end

--
-- standard pico-8 workflow
--

function _init()
    state = "menu"
    menu = {
        doordw = 128,
        doorx = 0,
        opening = false
    }

    player = {
        x = 64, y = 40,
        spd = 1.0,
        dir = false,
        grounded = false,
        jump = 0, fall = 0,
        spr = 18,
        climbspd = 0.2,
        ladder = false
    }
    jump_speed = 1
    fall_speed = 1
end

function _update60()
    if state == "menu" then
        update_menu()
    elseif state == "play" then
        update_player()
    end
end

function _draw()
    if state == "menu" then
        draw_world()
        draw_menu()
    elseif state == "play" then
        draw_world()
        draw_debug()
        draw_player()
    end
end 

--
-- menu
--

function update_menu()
    open_door()
end

function open_door()
    if btn(4) then
        opening = true
    end
    if opening == true then
        menu.doordw -= 1
        menu.doorx += 1
    end
    if menu.doordw == 0 then
        opening = false
        state = "play"
    end
end

--
-- play
--

function update_player()
    local new_x = player.x
    local new_y = player.y
    -- apply controls
    if btn(0) then
        player.dir = true
        new_x -= player.spd
    elseif btn(1) then
        player.dir = false
        new_x += player.spd
    end

    if ladder_area_down(player.x, new_y, 4, 4) or ladder_area_up(player.x, new_y, 4, 4) then
        player.ladder = true
    else player.ladder = false
    end

    if player.ladder == true then

    elseif player.jump > 0 then
            new_y -= mid(1, player.jump / 5, 2) * jump_speed
            player.jump -= 1
    else
            new_y += mid(1, player.fall / 5, 2) * fall_speed
            player.fall += 1
    end

    if jump() then
        if player.ladder then
            new_y -= player.climbspd
        else
            if player.grounded then
                player.jump = 20 -- start jumping
            end
        end
    else
        player.jump = 0 -- stop jumping
    end

    if btn(3) then
        player.spr = 26
        if ladder_area_down(player.x, new_y, 4) then
            new_y += player.climbspd
        end
    else player.spr = 18
    end

    -- test collisions
    if not wall_area(new_x, player.y, 4, 4) or ladder_area_side(new_x, new_y, 4, 4) then
        player.x = new_x -- new_x is ok!
    end
    if not wall_area(player.x, new_y, 4, 4) then
        player.grounded = false
        player.y = new_y -- new_y is ok!
    else
        if new_y > player.y then
            player.grounded = true 
            player.fall = 0
        end
        if jump() then
            player.y = new_y
        end
        if btn(3) and player.ladder == true then
            player.y = new_y
        end
    end
end

function wall(x,y)
    local m = mget(x/8, y/8)
    if not fget(m, 4) then
        return wallandladder(x, y)
    else return false
    end
end

function wall_area(x,y,w,h)
    return wall(x-w,y-h) or wall(x-1+w,y-h) or
           wall(x-w,y-1+h) or wall(x-1+w,y-1+h) or
           wall(x-w,y) or wall(x-1+w,y) or
           wall(x,y-1+h) or wall(x,y-h)
end

function wallandladder(x,y)
    local m = mget(x/8,y/8)
    if ((x%8<4) and (y%8<4)) return fget(m,0)
    if ((x%8>=4) and (y%8<4)) return fget(m,1)
    if ((x%8<4) and (y%8>=4)) return fget(m,2)
    if ((x%8>=4) and (y%8>=4)) return fget(m,3)
    return true
end

function wallandladder_area(x,y,w,h)
    return wallandladder(x-w,y-h) or wallandladder(x-1+w,y-h) or
           wallandladder(x-w,y-1+h) or wallandladder(x-1+w,y-1+h) or
           wallandladder(x-w,y) or wallandladder(x-1+w,y) or
           wallandladder(x,y-1+h) or wallandladder(x,y-h)
end

function ladder(x,y)
    local m = mget(x/8, y/8)
    if not fget(m, 4) then return false
    elseif wallandladder(x,y) then return true
    else return false
    end
end

function ladder_area_up(x,y,h)
    return ladder(x,y-h)
end

function ladder_area_down(x,y,h)
    return ladder(x,y+h)
end

function ladder_area_side(x,y,w,h)
    return ladder(x-w,y-h) or ladder(x-1+w,y-h) or
           ladder(x-w,y-1+h) or ladder(x-1+w,y-1+h)
end

--
-- drawing
--

function draw_menu()
    palt(0, false)
    sspr(96, 8, 16, 16, menu.doorx, 0, menu.doordw, 128)
    palt(0,true)
    if menu.doordw > 126 then
        csprint("play", 30, 9, 13)
    end
end

function draw_world()
    cls(0)
    map(0, 0, 0, 0, 16, 16)
end

function draw_player()
    spr(player.spr, player.x - 8, player.y - 12, 2, 2, player.dir)
end

function draw_debug()
    print("player.xy "..player.x.." "..player.y, 5, 5, 6)
    print("jump "..player.jump.."  fall "..player.fall, 5, 12, 6)
    print("grounded "..tostr(player.grounded), 5, 19, 6)
    print("player.ladder  "..tostr(player.ladder), 5, 26, 6)
    -- debug collisions
    fillp(0xa5a5.8)
    rect(player.x - 4, player.y - 4, player.x + 3, player.y + 3, 8)
    fillp()
end

__gfx__
000000000000330077777777777c00000000c7770000000000000000cccccccc000000000000c777777c0000777c00000000c7777777777777777777777c0000
000000000003b63077777777777c00000000c777000000000000000077777777000000000000c777777c0000777c00000000c7777777777777777777777c0000
000000000003bb3077777777777c00000000c777000000000000000077777777000000000000c777777c0000777c00000000c7777777777777777777777c0000
0000000000036b3077777777777c00000000c777000000000000000077777777000000000000c777777c0000777c00000000c7777777777777777777777c0000
00000000003bbb30777777770000000000000000cccc00000000cccc00000000cccccccc0000c777777c0000777cccccccccc7770000c777777c00000000cccc
0000000003bb6b30777777770000000000000000777c00000000c77700000000777777770000c777777c000077777777777777770000c777777c00000000c777
00000000036bb300777777770000000000000000777c00000000c77700000000777777770000c777777c000077777777777777770000c777777c00000000c777
0000000000333000777777770000000000000000777c00000000c77700000000777777770000c777777c000077777777777777770000c777777c00000000c777
0000cccc04ffff40000000003300000000dddddddddddd000000000000000000f880000000000000000000000000000055666666666666000000000000000000
0000c7760400004000000003bb300000dd666666666666dd0000000000000000f8888000a000bb00000000000000000056555550550500600000000000000000
0000c77604ffff400000003bbbb300001dddddddddddddd10000000000000000f8888800ba0b33b0000000000000000056677777777776600000000000000000
0000c666040000400000033bb7b73000111111111111111100087878787880000f888e800bb3373b000000000000000056777777777777600000000000000000
cccc000004ffff400000003bb1b1300011a11aa11a11a1a100878787878788000f88817803333333000000033000000056777777777777600000000000000000
c7760000040000400000003bbbbb30001a1a1a1a1a11aaa10077cccccccc77000f888888310133100000003bb300000056007777777777600000000000000000
c776000004ffff40000003bbbbbb330011a11aa1a1a1a1a107cccccccccccc6000f8888710001100000003bbbb30000056667777777777600000000000000000
c666000004000040000033bbbb113000111a1a11aaa1a1a107cccccccccc6d600007777000000000000003bb7b73000056777777777777600000000000000000
0000000000000000000003bbbbbb30001a1a1a1a11a1a1a107cccccccccc6c60000c000000444400000003bb1b13000056777777777777600000000000000000
000000000000000000003bb3bbbb300011a11a1a11a1a1a107cccccccccc6d60000c000004979740000003bbbbb3000056777777777777600000000000000000
00000000000000000003bb3bb3b30000111111111111111107cccccccccc6c6000cc100047aaaa7400003bbbbbb3300056777777777777600000000000000000
0000000000000000003bbbbbbbb33000111199a9a999111107cccccccccc6d600c7cd100494a4a9400033bbb1113000056777777777777600000000000000000
0000000004ffff40003bbb3bbb300000199a9a9a9a9a999107cccccccccc6c60c7cccd1049aaaa740003bb3bbbb3000056777777777777600000000000000000
0000000004000040003bb3bbbb30000011a9a8888889a91107c6666666666d60c7cccd1049a4aa94003bb3bb3b30000056777777777777600000000000000000
0000000004ffff400003bbbbb3300000199444eefef44991007cdcdcdcdcd6000c7cd10004999740003bbbbbbb30000055666666666666000000000000000000
00000000040000400000333330000000119a9444e9899911000766666666600000dd100000444400000333333300000065555550550500060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333300000000000000000000000000000000
__gff__
000f0f01020408030c0a050d0e0b0709061f00000f0f0c0c0000000000000000001c00000f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000006080808050900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000808000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000008210000000000000202000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a19000000110000000000000000180900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e07070700110000000000000e000d0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000110000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000070714150006080500000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000024251909000000060200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b080500070707070707070000060e0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000000000000608080800060e000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00060808050000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b08080808080808080808080808080c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
