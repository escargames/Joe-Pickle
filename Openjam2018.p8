pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--
-- useful functions
--

function jump()
    if btn(2) or btn(5) then
        return true end
end

--
-- standard pico-8 workflow
--

function _init()
    player = {x = 64, y = 64, spd = 0.5, dir = false, jump = 0, grounded = false}
    gravity_speed = 1
end

function _update60()
    update_player()
end

function _draw()
    draw_world()
    draw_player()
    draw_debug()
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

    if player.jump > 0 then
        new_y -= (player.jump / 5) * player.spd
        player.jump -= 1
    else
        new_y += gravity_speed
    end

    if jump() and player.grounded == true then
        player.jump = 20
     --elseif btn(3) then
         --new_y += player.spd
    end

    -- test collisions
    if not wall_area(new_x, player.y, 4, 4) then
        player.x = new_x -- new_x is ok!
    end
    if not wall_area(player.x, new_y, 4, 4) then
        player.grounded = false
        player.y = new_y -- new_y is ok!
    elseif not jump() then player.grounded = true
    end
end

function wall(x,y)
    local m = mget(x/8,y/8)
    if ((x%8<4) and (y%8<4)) return fget(m,0)
    if ((x%8>=4) and (y%8<4)) return fget(m,1)
    if ((x%8<4) and (y%8>=4)) return fget(m,2)
    if ((x%8>=4) and (y%8>=4)) return fget(m,3)
    return true
end

function wall_area(x,y,w,h)
    return wall(x-w,y-h) or wall(x-1+w,y-h) or
           wall(x-w,y-1+h) or wall(x-1+w,y-1+h) or
           wall(x-w,y) or wall(x-1+w,y) or
           wall(x,y-1+h) or wall(x,y-h)
end

--
-- drawing
--

function draw_world()
    cls(0)
    map(0, 0, 0, 0, 16, 16)
end

function draw_player()
    spr(18, player.x - 8, player.y - 12, 2, 2, player.dir)
end

function draw_debug()
    print("player.x  "..player.x, 5, 5, 6)
    print("player.y  "..player.y, 5, 12, 6)
    print("player.jump  "..player.jump, 5, 19, 6)
    print("player.grounded  "..tostr(player.grounded), 5, 26, 6)
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
0000cccc00000000000000003300000000dddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c7760000000000000003bb300000dd666666666666dd00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c776000000000000003bbbb300001dddddddddddddd100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c666000000000000033bb7b73000111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc0000000000000000003bb1b1300011a11aa11a11a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000
c7760000000000000000003bbbbb30001a1a1a1a1a11aaa100000000000000000000000000000000000000000000000000000000000000000000000000000000
c776000000000000000003bbbbbb330011a11aa1a1a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000
c666000000000000000033bbbb113000111a1a11aaa1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000003bbbbbb30001a1a1a1a11a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000003bb3bbbb300011a11a1a11a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000003bb3bb3b30000111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003bbbbbbbb33000111199a9a999111100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003bbb3bbb300000199a9a9a9a9a999100000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003bb3bbbb30000011a9a8888889a91100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000003bbbbb3300000199444eefef4499100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000333330000000119a9444e989991100000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
000f0f01020408030c0a050d0e0b070906000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0e07070707070707070707070707070d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000006080808050900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000808000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000008080000000000000202000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b08080800000000000000000e000d0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000070000000006080500000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000000808080808080c000000060200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b080500000000000000000000060e0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000000000000608080800060e000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00060808050000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b08080808080808080808080808080c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
