function love.load() 
    love.window.setMode(450, 640)
    love.window.setTitle("Drop")

    -- load physics library
    wf = require "lib/windfield"
    world = wf.newWorld(0, 500, false)
    world:setQueryDebugDrawing(true)
    world:addCollisionClass("Player")
    world:addCollisionClass("Platform")
    world:addCollisionClass("Coin")
    world:addCollisionClass("Over")

    -- load animation library
    anim8 = require "lib/anim8/anim8"

    -- load assets
    img = {}
    img.box = love.graphics.newImage("assets/box.png")
    img.bg = love.graphics.newImage("assets/bg.jpg")
    img.spike = love.graphics.newImage("assets/spike.png")
    img.platform = love.graphics.newImage("assets/platform.png")
    img.coin = love.graphics.newImage("assets/coin.png")

    -- ini untuk animasi spin coin
    local grid = anim8.newGrid(154, 154, img.coin:getWidth(), img.coin:getHeight())
    animations = {}
    animations.spin = anim8.newAnimation(grid("1-6", 1), 0.1)
    
    -- game variabel
    player = world:newRectangleCollider(148, 90, 50, 50, {collision_class = "Player"})
    platforms = {} -- menyimpan list of platform
    idx = 1 -- index pertama  untuk while loop menambahkan platform ke table platforms
    platform_count = 8 -- banyakanya platform yang muncul di screen
    koins = {}
    coin_idx = 1 -- index untuk tempat koin
    platform_speed = 80
    scene = {
        menu = 0,
        play = 1,
        over = 2,
    }
    current_scene = scene.menu
    score = 0

    -- game over collider
    game_over_colllider = world:newRectangleCollider(0, 50, love.graphics.getWidth(), 5, {collision_class = "Over"})
    game_over_colllider:setType("static")
    
    newKotak()
    newKoin()
    
    
    -- awal-awal kita initiate platform
    while idx < platform_count do
        local _ , py = platforms[idx]:getPosition() -- ambil posisi platform setiap index
        kotak = world:newRectangleCollider(math.random(0, love.graphics.getWidth()-100), py + 120, 100, 10, {collision_class = "Platform"}) -- update posisi y nya agar dia di bawah platform yang sebelumnya
        kotak:setType("static") -- bikin jadi static type
        table.insert(platforms, kotak) -- insert ke tables platoforms
        idx = idx + 1
    end

    coin_idx = #platforms - 1 -- pertama kali kita buat coin_idx selalu di platform terakhir

end

function love.update(dt)
    
    if current_scene == scene.play then
        local px, py = player:getPosition()

        if py > love.graphics:getHeight() then
            current_scene = scene.over
        end

        if love.keyboard.isDown("right") then
            player:setX(px + 200 * dt)
        end
        if love.keyboard.isDown("left") then
            player:setX(px - 200 * dt)
        end

        -- check jika jumlah dari tables platforms, kurang dari platform_count, maka kita add platform baru
        while #platforms < platform_count do
            local _ , py = platforms[#platforms]:getPosition()
            kotak = world:newRectangleCollider(math.random(0, love.graphics.getWidth()-100), py + 120, 100, 10, {collision_class = "Platform"})
            kotak:setType("static")
            table.insert(platforms, kotak)
            coin_idx = coin_idx - 1 -- decrement coin_idx, ini agar dia tidak pindah ke platform terakhir lagi ketika kita insert platform baru
        end

        -- TODO: bikin MENU GAME

        -- check jika length dari table koins lebih dari 1
        if #koins > 0 then
            -- loop secara reverse, karena nantinya kita akan remove koinnya jika collide dengan player
            for i = #koins, 1, -1 do
                local koin = koins[i]
                local _, ky = koins[i]:getPosition()
                -- check jika player collide dengan coin
                if player:enter("Coin") or (ky < -30 and coin_idx == 1) then
                    -- destory body koin
                    koins[i]:destroy()
                    -- remove dari tables
                    table.remove(koins, i)
                    -- add new koin
                    newKoin()
                    coin_idx = #platforms
                else
                    -- update posisi koin
                    local px, py = platforms[coin_idx]:getPosition()
                    koin:setX(px)
                    koin:setY(py - 35)
                end
            end
        end

        -- loop ini mengupdate posisi platform koordinat y ke atas
        for _, k in ipairs(platforms) do
            local _, py = k:getPosition()
            k:setY(py - platform_speed * dt)
        end

        -- loop ini menghapus platform yang koordinat y nya lebih kurang dari -10, dimana artinya dia sudah melebihi tinggi window layar
        for i = #platforms, 1, - 1 do
            local _, py = platforms[i]:getPosition()
            if py < -10 then
                platforms[i]:destroy()
                table.remove(platforms, i)
            end
        end

        -- jika kena spike maka game over
        if player:enter("Over") then
            current_scene = scene.over
        end

        -- jika kena coin maka update score
        if player:enter("Coin") then
            score = score + 1
        end
    end

    animations.spin:update(dt)
    world:update(dt)
end

function love.draw()
    -- draw background
    love.graphics.draw(img.bg, 0,0, nil, 0.32)

    if current_scene == scene.menu then
        love.graphics.setColor(255/1, 255/1, 0)
        love.graphics.setFont(love.graphics.newFont(60))
        love.graphics.printf("Drop", 0, love.graphics.getHeight()/4 - 50, love.graphics.getWidth() - 150, "center")
        love.graphics.setColor(0/255, 150/255, 1)
        love.graphics.printf("Box", 0, love.graphics.getHeight()/4 - 10, love.graphics.getWidth() + 100, "center")
        love.graphics.setFont(love.graphics.newFont(25))
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Tekan \"SPACE\" untuk start!", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")        
        love.graphics.setColor(255/1, 255/1, 0)
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("created by aji mustofa @pepega90", 50, love.graphics.getHeight() - 30, love.graphics.getWidth(), "left")
        love.graphics.setColor(1,1,1)
    elseif current_scene == scene.play then
        -- draw player dan juga mengupdate rotasi player, agar sesuai dengan physic dari windfield
        love.graphics.push() -- Save the current transformation state
        love.graphics.translate(player:getX(), player:getY()) -- Translate to the body position
        love.graphics.rotate(player.body:getAngle()) -- Rotate by the body's angle
        love.graphics.draw(img.box, -img.box:getWidth()/2 * 0.1, -img.box:getHeight()/2 * 0.1, 0, 0.1) -- Draw the image at the transformed position
        love.graphics.pop() -- Restore the previous transformation state

        -- draw platform
        for _, p in ipairs(platforms) do
            local scalePlatform = 0.2
            love.graphics.draw(img.platform, p:getX() - img.platform:getWidth()/2 * scalePlatform, p:getY() - img.platform:getHeight()/2 * scalePlatform + 10, nil, scalePlatform)
        end

        -- draw coin
        if #koins > 0 then
            animations.spin:draw(img.coin,koins[#koins]:getX() - 80 * 0.3,koins[#koins]:getY() - 80 * 0.3,nil, 0.3)
        end
        
        -- draw spike
        for i = 1, 10, 1 do
            love.graphics.draw(img.spike, i * 45 - 45, 0, nil, 0.3)
        end
    elseif current_scene == scene.over then
        love.graphics.setColor(255/1, 255/1, 0)
        love.graphics.setFont(love.graphics.newFont(40))
        love.graphics.printf("Game Over", 0, love.graphics.getHeight()/4, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(30))
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Score Kamu = " ..score, 0, love.graphics.getHeight()/2 - 30, love.graphics.getWidth(), "center")
        love.graphics.printf("Tekan \"R\" untuk restart!", 0, love.graphics.getHeight()/2 + 100, love.graphics.getWidth(), "center")
        love.graphics.setColor(1,1,1)
    end
    

    -- local px, py = platforms[coin_idx]:getPosition()
    -- love.graphics.print("koin position y = " ..py   , 50, 50)
    -- love.graphics.print("koin position x = " ..px   , 50, 100)

    -- -- draw mouse position untuk utility
    -- love.graphics.print("mouse x = " .. love.mouse.getX(), 10, 10)  
    -- love.graphics.print("mouse y = " .. love.mouse.getY(), 10, 40)
    -- world:draw()
end

-- function untuk menambahkan kotak di awal-awal
function newKotak()
    k = world:newRectangleCollider(120, 300, 100, 10, {collision_class = "Platform"})
    k:setType("static")
    table.insert(platforms, k)
end

function newKoin()
    koin = world:newCircleCollider(-10,-10,20, {collision_class = "Coin"})
    koin.hit = false
    koin:setType("static")
    table.insert(koins, koin)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
       love.event.quit()
    end

    if key == "space" then
        current_scene = scene.play
    end

    if current_scene == scene.over and key == "r" then
        current_scene = scene.play
        score = 0
        player:setX(148)
        player:setY(100)
        player:setLinearVelocity(0,0)
        idx = 1
        for i = #platforms, 1, - 1 do
            platforms[i]:destroy()
            table.remove(platforms, i)
        end
        newKotak()
        newKoin()
        while idx < platform_count do
            local _ , py = platforms[idx]:getPosition() -- ambil posisi platform setiap index
            kotak = world:newRectangleCollider(math.random(0, love.graphics.getWidth()-100), py + 120, 100, 10, {collision_class = "Platform"}) -- update posisi y nya agar dia di bawah platform yang sebelumnya
            kotak:setType("static") -- bikin jadi static type
            table.insert(platforms, kotak) -- insert ke tables platoforms
            idx = idx + 1
        end
    end
 end

