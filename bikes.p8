pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- lonely light bikes
-- by kitasuna
-- thanks to rabidgremlin for the rad tutorial
scrn = {}
btn_u = 2
btn_d = 3
btn_l = 0
btn_r = 1

dir_d = 1
dir_r = 2
dir_u = 3
dir_l = 4

p1 = {dir = dir_l, last_dir = dir_u}
p2 = {dir = dir_r, last_dir = dir_d, divine = true, dec_threshold = 1.5, dec_perfect = 0}

clr_blk = 0

anim_step = 0

// how often ai checks surroundings
max_cdown = 32

base_arena_x0 = 16
base_arena_y0 = 16
base_arena_x1 = 111
base_arena_y1 = 111
map_clr = 14
_debug = false
scales = { "small", "medium", "large" }
_config = { menu_sel = 1, arena_scale = 2 }
-->8
function _init()
  show_menu()
end

function _update()
  scrn.upd()
end

function _draw()
  scrn.drw()
end

function show_menu()
  scrn.upd = update_menu
  scrn.drw = draw_menu
end

function update_game()
  if (p2.dec_perfect > 0) then
    p2.dec_perfect -= 1
  end

  ai(p2)
  upd_plr_pos(p1)
  upd_plr_pos(p2)

  if (btnp(btn_l) and p1.dir != dir_r) then
    upd_plr_dir(p1, dir_l)
  elseif (btnp(btn_r) and p1.dir != dir_l) then
    upd_plr_dir(p1, dir_r)
  elseif (btnp(btn_d) and p1.dir != dir_u) then
    upd_plr_dir(p1, dir_d)
  elseif (btnp(btn_u) and p1.dir != dir_d) then
    upd_plr_dir(p1, dir_u)
  end

  if(pget(p1.x,p1.y) != clr_blk) then show_go() end
  if(pget(p2.x,p2.y) != clr_blk) then show_win() end
  -- Give the win to the player if the bikes share a pixel
  if(p2.x == p1.x and p2.y == p1.y) then show_win() end
end

function draw_game()

  // write player pixel
  pset(p1.x,p1.y,12)
  pset(p2.x,p2.y,9)

  // cpu last dir (debug)
  if(_debug == true) then
    // overwrite score / debug area
    rectfill(arena_x0,arena_y0,arena_x1,arena_y0 + 24,0)

    print("u", 0, 0, p2.last_dir == dir_u and 7 or 12)
    print("d", 4, 0, p2.last_dir == dir_d and 7 or 12)
    print("l", 8, 0, p2.last_dir == dir_l and 7 or 12)
    print("r", 12, 0, p2.last_dir == dir_r and 7 or 12)

    // dec perfect countdown (debug)
    print(p2.dec_perfect, 0, 8, 12)

    // divine mode
    print("divine", 0, 16, p2.divine == true and 11 or 14)
  end
end


function start_game()
  arena_x0 = base_arena_x0 + ( (2 - _config.arena_scale) * 16 )
  arena_x1 = base_arena_x1 + ( (_config.arena_scale - 2) * 16 )
  arena_y0 = base_arena_y0 + ( (2 - _config.arena_scale) * 16 )
  arena_y1 = base_arena_y1 + ( (_config.arena_scale - 2) * 16 )
  scrn.upd = update_game
  scrn.drw = draw_game

  p1.x = arena_x1 - flr((arena_x1 - arena_x0) / 4)
  p1.y = arena_y1 - flr((arena_y1 - arena_y0) / 4)
  p1.dir = dir_l
  p2.last_dir = dir_u

  p2.x = arena_x0 + flr((arena_x1 - arena_x0) / 4)
  p2.y = arena_y0 + flr((arena_y1 - arena_y0) / 4)
  p2.cdown = flr(rnd(max_cdown))
  p2.safedirs = {true, true, true, true}
  p2.safedirs[p2.dir] = false
  p2.divine = true
  p2.dec_perfect = 300
  p2.dec_threshold = 1.5

  cls()
  rect(arena_x0,arena_y0,arena_x1,arena_y1,map_clr)
  sfx(0,0,0)
end

function update_menu()
  if(btnp(2) and _config.menu_sel > 1) then
    _config.menu_sel -= 1
  end
  if(btnp(3) and _config.menu_sel < 2) then
    _config.menu_sel += 1
  end

  menu_hndlr[_config.menu_sel]()
end

menu_hndlr = {
  function() if(btnp(4)) then start_game() end end,
  function()
    if(btnp(0) and _config.arena_scale > 1) then
      _config.arena_scale -= 1
    end
    if(btnp(1) and _config.arena_scale < 3) then
      _config.arena_scale += 1
    end
  end,
  function() return false end
}

function draw_menu()
  cls()
  print("l     o     n     e     l     y", 0, 10, 14)
  spr(0,10,24,16,2)
  print("⬆️⬇️⬅️➡️ to steer", 28, 50, 7)
  print(">>", 18, (62 + (_config.menu_sel * 8)), 14)
  print("start", 30, 70, (_config.menu_sel == 1 and 14 or 5))
  print("arena: "..scales[_config.arena_scale], 30, 78, (_config.menu_sel == 2 and 14 or 5))

  print("based on tut by rabidgremlin", 16, 112, 5)
  print("v0.1.1 by kitasuna", 56, 120, 5)
end

function show_go()
  scrn.upd = update_postgame
  scrn.drw = draw_go
  sfx(2,0)
end

function splode(p, step)
  circfill(p.x,p.y,step/5,step)
end

function draw_go()
  rectfill(0,0,127,16,0)
  print("you lose", 42, 0, 8)
  postgame_controls()
  splode(p1, anim_step)
  anim_step += 1
  if(anim_step > 16) then anim_step = 0 end
end

function postgame_controls()
  print("🅾️ restart", 0, 8, 7)
  print("❎ return to menu", 0, 16, 7)
end

function update_postgame()
  if(btn(5)) then
    show_menu()
  elseif(btn(4)) then 
    start_game() 
  end
end

function show_win()
  scrn.upd = update_postgame
  scrn.drw = draw_win
  sfx(2,0)
end

function draw_win()
  rectfill(arena_x0,arena_y0,arena_x1,arena_y0 + 16,0)
  print("you win", 42, 0, 3)
  postgame_controls()
  splode(p2, anim_step)
  anim_step += 1
  if(anim_step > 16) then anim_step = 0 end
end
-->8
function upd_plr_pos(plr)
  if(plr.dir == dir_u) then plr.y=plr.y-1 end
  if(plr.dir == dir_d) then plr.y=plr.y+1 end
  if(plr.dir == dir_r) then plr.x=plr.x+1 end
  if(plr.dir == dir_l) then plr.x=plr.x-1 end
end

function upd_plr_dir(plr, dir)
  plr.last_dir = plr.dir
  plr.dir = dir
  sfx(1, 1)
end

-->8

function ai(p2)
  p2.cdown = p2.cdown - 1
  update_safedirs(p2)

  if(p2.cdown <= 0) then    
    pick_dir(p2)
    update_cdown(p2)  
  end

end

function update_safedirs(p2)
  p2.safedirs = {true, true, true, true}

  p2.safedirs[dir_u] = pget(p2.x, p2.y - 1) == clr_blk
  p2.safedirs[dir_d] = pget(p2.x, p2.y + 1) == clr_blk
  p2.safedirs[dir_l] = pget(p2.x - 1, p2.y) == clr_blk
  p2.safedirs[dir_r] = pget(p2.x + 1, p2.y) == clr_blk

  if(p2.dir == dir_u) then
    p2.safedirs[dir_d] = false
  end

  if(p2.dir == dir_d) then
    p2.safedirs[dir_u] = false
  end

  if(p2.dir == dir_l) then
    p2.safedirs[dir_r] = false
  end

  if(p2.dir == dir_r) then
    p2.safedirs[dir_l] = false
  end

  if(p2.x <= (arena_x0 + 3)) then
    p2.safedirs[dir_l] = false
  end

  if(p2.x >= (arena_x1 - 3)) then
    p2.safedirs[dir_r] = false
  end

  if(p2.y <= (arena_y0 + 3)) then
    p2.safedirs[dir_u] = false
  end

  if(p2.y >= (arena_y1 - 3)) then
    p2.safedirs[dir_d] = false
  end

  if(p2.safedirs[p2.dir] == false) then
    local dec = rnd(2)
    if(p2.dec_perfect > 0 or dec < p2.dec_threshold) then
      p2.divine = true
      p2.cdown = 0
    else
      p2.divine = false
    end
  end
end

function update_cdown(p2)
  p2.cdown = flr(rnd(max_cdown)) + 8
end

function pick_dir(p2)
  local dec = rnd(2)
  // favor returning to last direction (avoids loops)
  if(p2.dec_perfect > 0 or dec < p2.dec_threshold) then
    newdir = p2.last_dir
    p2.divine = true
  else 
    newdir = flr(rnd(4)) + 1
    p2.divine = false
  end

  if(p2.safedirs[newdir] == true) then
    upd_plr_dir(p2, newdir)
  else
    for d,value in pairs(p2.safedirs) do
      if value == true and d != p2.dir then
        upd_plr_dir(p2, d)
        break
      end
    end
  end
end

__gfx__
00ccc0000000ccc0000000000ccc00000000ccc00000000000099999999999000099900999000000000999999999000999990000000000000000000000000000
00ccc0000000ccc0000000000ccc00000cccccccccccc00000099999999999900099900999000999009999999999099999990000000000000000000000000000
00ccc0000000ccc0000000000ccc00000cccccccccccc00000099900000099900099900999000999009999900999099999990000000000000000000000000000
00ccc0000000000000cccccc0ccc00000cccccccccccc00000099900000099900000000999999999009999009999099999000000000000000000000000000000
00ccc0000000ccc00ccccccc0ccccccccc00ccc00000000000099900000099900099900999999900009999999999099990000000000000000000000000000000
00ccc0000000ccc00ccccccc0ccccccccc00ccc00000000000099999999999900099900999999900009999999999099999999900000000000000000000000000
00ccc0000000ccc00ccc0ccc0ccccccccc00ccc00000000000099999999999000099900999999999009999999990099999999900000000000000000000000000
00cccccccc00ccc00ccccccc0ccc000ccc00ccc00000000000099999999999000099900999099999909999000000000999999900000000000000000000000000
00cccccccc00ccc00ccccccc0ccc000ccc00ccc00000000000099900000009990099900999099999909999900000000000099900000000000000000000000000
00cccccccc00ccc00ccccccc0ccc000ccc00ccc00000000000099900000009990099900999000999900999900000000999999900000000000000000000000000
000000000000000000000ccc0000000ccc0000000000000000099999999999990099900999000099900999999999000999999900000000000000000000000000
000000000000000000cccccc00000000000000000000000000009999999999000099900999000000000099999999000999999900000000000000000000000000
000000000000000000cccccc00000000000000000000000000009999999999000000000000000000000099999999000999990000000000000000000000000000
000000000000000000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100080d520095200b5200c5200d52009550095500a550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000e1500c140081400c1400f14001100011000f1000a1000810005100041000410003100031000310003100000000000000000000000000000000000000000000000000000000000000000000000000000
000400001534013340103400e3400c3500a3500735005340033400134009600103000f3000e300093000c3000b3000a3000930009300083000730005300033000000000000000000000000000000000000000000
