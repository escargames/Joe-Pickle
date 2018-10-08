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

function add_player(x, y)
    player = {
        x = x, y = y,
        spd = 1.0,
        climbspd = 0.5,
        dir = false,
        grounded = false,
        ladder = false,
        jumped = false,
        jump = 0, fall = 0,
        spr = 18,
        particles = {},
    }
end

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

-- cool rectfill (centered, outlined)

function corectfill(y0, y1, w, color1, color2)
    local x0 = 64 - ((w / 2))
    local x1 = 64 + ((w / 2) - 1)
    rectfill(x0, y0, x1, y1, color1)
    rect(x0, y0, x1, y1, color2)
end

-- cool rectfill (outlined)

function orectfill(x0, y0, x1, y1, color1, color2)
    rectfill(x0, y0, x1, y1, color1)
    rect(x0, y0, x1, y1, color2)
end

--
-- standard pico-8 workflow
--

function _init()
    state = "menu"
    score = 0
    fish = 0
    hidefish = {}
    add_player(64, 150)
    collectibles()
    menu = {
        doordw = 128,
        doorx = 0,
        doorspd = 1,
        opening = false,
        rectpos = 1,
        rect_y0 = 55,
        rect_y1 = 72,
        scores = false,
        high_y = 78
    }

    jump_speed = 1
    fall_speed = 1
end

function _update60()
    if state == "menu" then
        update_menu()
        update_player()
    elseif state == "play" then
        update_player()
        collect_fish()
    end
end

function _draw()
    if state == "menu" then
        draw_world()
        draw_menu()
    elseif state == "play" then
        draw_world()
        hidecollectible()
        draw_player()
        draw_debug()
        draw_ui()
    end
end 

--
-- menu
--

function update_menu()
    open_door()
    choose_menu()
    rect_menu()
end

function open_door()
    if btnp(4) and not menu.scores then
        if menu.rectpos == 1 then
            menu.opening = true
        elseif menu.rectpos == 2 then
            menu.scores = true
        end
    elseif btnp(4) and menu.scores then
        menu.scores = false
    end

    if menu.opening == true then
        menu.doordw -= mid(2, menu.doordw / 5, 3) * menu.doorspd
        menu.doorx += mid(2, menu.doordw / 5, 3) * menu.doorspd
    end

    if menu.scores == true then
        if menu.high_y > 30 then
            menu.high_y -= 2
        end
    end

    if menu.doordw < 2 then
        menu.opening = false
        state = "play"
        add_player(64, 40)
    end
end

function rect_menu()
    if menu.rectpos == 1 then
        menu.rect_y0 = 55
        menu.rect_y1 = 72
    elseif menu.rectpos == 2 then
        menu.rect_y0 = 73
        menu.rect_y1 = 90
    end
end

function choose_menu()
    if btnp(3) and menu.rectpos < 2 then
        menu.rectpos += 1
    elseif btn(2) and menu.rectpos > 1 then
        menu.rectpos -= 1
    end
end

--
-- play
--

function move_player_x(dx)
    if not wall_area(player.x + dx, player.y, 4, 4) then
        player.x += dx
    end
end

function move_player_y(dy)
    while wall_area(player.x, player.y + dy, 4, 4) do
        dy *= 7 / 8
        if abs(dy) < 0.00625 then return end
    end
    player.y += dy
end

function update_player()
    local old_x, old_y = player.x, player.y

    -- check x movement (easy)
    if btn(0) then
        player.dir = true
        move_player_x(-player.spd)
    elseif btn(1) then
        player.dir = false
        move_player_x(player.spd)
    end

    -- check for ladders and ground below
    local ladder = ladder_area(player.x, player.y, 0, 4)
    local ladder_below = ladder_area_down(player.x, player.y + 0.0125, 4)
    local ground_below = wall_area(player.x, player.y + 0.0125, 4, 4)
    local grounded = ladder or ladder_below or ground_below

    -- if inside a ladder, stop jumping
    if ladder then
        player.jump = 0
    end

    -- if grounded, stop falling
    if grounded then
        player.fall = 0
    end

    -- allow jumping again
    if player.jumped and not jump() then
        player.jumped = false
    end

    if jump() then
        -- up/jump button
        if ladder then
            move_player_y(-player.climbspd)
        elseif grounded and not player.jumped then
            player.jump = 20
            player.jumped = true
        end
    elseif btn(3) then
        -- down button
        if ladder_below then
            move_player_y(player.climbspd)
        end
    end

    if player.jump > 0 then
        move_player_y(-mid(1, player.jump / 5, 2) * jump_speed)
        player.jump -= 1
        if old_y == player.y then
            player.jump = 0 -- bumped into something!
        end
    elseif not grounded then
        move_player_y(mid(1, player.fall / 5, 2) * fall_speed)
        player.fall += 1
    end

    player.grounded = grounded
    player.ladder = ladder

    foreach (player.particles, function(p)
        p.x += rnd(2) - 1
        p.y += rnd(1) - 0.5
        p.age += 1
        if p.age > 10 then
            del(player.particles, p)
        end
    end)

    if old_x != player.x or old_y != player.y then
        add(player.particles, { x = player.x + (rnd(8) - 4) - rnd(2) * (player.x - old_x),
                                y = player.y + (rnd(8) - 6) - rnd(2) * (player.y - old_y),
                                age = -rnd(5) })
    end
end

-- collectibles

function collectibles()
    fishes = {}
    for j=0, 15 do
        for i=0, 15 do
            local tile = mget(i,j)
            if tile == 25 then -- this is a fish
                add(fishes, { cx = i, cy = j })
            end
        end
    end
end

function collect_fish()
    foreach(fishes, function(f)
        if flr(player.x / 8) == f.cx and flr(player.y / 8) == f.cy then
            add(hidefish, {cx = f.cx, cy = f.cy})
            fish += 1
            del(fishes, f)
        end
    end)
end

-- walls and ladders

function wall(x,y)
    local m = mget(x/8, y/8)
    return not fget(m, 4) and wall_or_ladder(x, y)
end

function wall_area(x,y,w,h)
    return wall(x-w,y-h) or wall(x-1+w,y-h) or
           wall(x-w,y-1+h) or wall(x-1+w,y-1+h) or
           wall(x-w,y) or wall(x-1+w,y) or
           wall(x,y-1+h) or wall(x,y-h)
end

function wall_or_ladder(x,y)
    local m = mget(x/8,y/8)
    if ((x%8<4) and (y%8<4)) return fget(m,0)
    if ((x%8>=4) and (y%8<4)) return fget(m,1)
    if ((x%8<4) and (y%8>=4)) return fget(m,2)
    if ((x%8>=4) and (y%8>=4)) return fget(m,3)
    return true
end

function wall_or_ladder_area(x,y,w,h)
    return wall_or_ladder(x-w,y-h) or wall_or_ladder(x-1+w,y-h) or
           wall_or_ladder(x-w,y-1+h) or wall_or_ladder(x-1+w,y-1+h) or
           wall_or_ladder(x-w,y) or wall_or_ladder(x-1+w,y) or
           wall_or_ladder(x,y-1+h) or wall_or_ladder(x,y-h)
end

function ladder(x,y)
    local m = mget(x/8, y/8)
    return fget(m, 4) and wall_or_ladder(x,y)
end

function ladder_area_up(x,y,h)
    return ladder(x,y-h)
end

function ladder_area_down(x,y,h)
    return ladder(x,y-1+h)
end

function ladder_area(x,y,w,h)
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
        if not menu.scores then
            corectfill(menu.rect_y0, menu.rect_y1, 35, 6, 0)
            csprint("joe       ", 32, 12, 11)
            csprint("    pickle", 32, 12, 9)
            csprint("play", 60, 9, 13)
            csprint("high", 78, 9, 13)
        else
            csprint("high", menu.high_y, 9, 13)
        end

        camera(0, 14*8)
        draw_player()
        camera()
    end
end

function draw_world()
    cls(0)
    map(0, 0, 0, 0, 16, 16)
end

function draw_ui()
    csprint(tostr(score), 3, 9, 13)
    cosprint(tostr(fish), 19, 4, 6, 9)
    spr(25, 7, 3)
end

function draw_player()
    foreach (player.particles, function(p)
        circfill(p.x, p.y, p.age < 5 and 0.5 or 1, p.age < 5 and 11 or 3)
    end)
    spr(player.spr, player.x - 8, player.y - 12, 2, 2, player.dir)
end

function hidecollectible()
    if #hidefish != 0 then
    foreach(hidefish, function(f)
        palt(0, false)
        rectfill(f.cx*8, f.cy*8, f.cx*8 + 7, f.cy*8 + 7, 0)
        palt(0, true)
        score += 1
    end)
    end
end

function draw_debug()
    print("player.xy "..player.x.." "..player.y, 5, 118, 6)
    print("jump "..player.jump.."  fall "..player.fall, 5, 111, 6)
    print("grounded "..(player.grounded and 1 or 0).."  ladder "..(player.ladder and 1 or 0), 5, 104, 6)
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
c7760000040000400000003bbbbb30001a1a1a1a1a11aaa10077cccccccc77000f888888310133100000003bb300000056777777777777600000000000000000
c776000004ffff40000003bbbbbb330011a11aa1a1a1a1a107cccccccccccc6000f8888710001100000003bbbb30000056777777777777600000000000000000
c666000004000040000033bbbb113000111a1a11aaa1a1a107cccccccccc6d600007777000000000000003bb7b73000056007777777777600000000000000000
0000000000000000000003bbbbbb30001a1a1a1a11a1a1a107cccccccccc6c60000c000000444400000003bb1b13000056667777777777600000000000000000
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
0a00080800000000000006080808000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000210808000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000110000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a19000000110000000008050000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e07070707110000000000000000180900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000110000000000000007070d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000110000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000070714150006080500000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000024251909000000060200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b080500000000070707070000060e0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000000000000000000000060e000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b08080808080808080808080808080c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0000000000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b080808080808080808080c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
