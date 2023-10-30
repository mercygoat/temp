function love.load()
    font = love.graphics.newFont("creepyfont.ttf", 48)
    love.window.setFullscreen(true, "desktop")

    anim8 = require "libraries/anim8"

    wf = require "libraries/windfield"
    world = wf.newWorld(0, 0)

    camera = require "libraries/camera"
    cam = camera()

    sti = require "libraries/sti"
    gameMap = sti("maps/horrormap.lua")

    darkness = love.graphics.newImage("maps/darkness.png")
    menu = love.graphics.newImage("maps/startmenu.png")
    gameEndL = love.graphics.newImage("maps/gameendl.png")
    gameEndW = love.graphics.newImage("maps/gameendw.png")
    
    player = {}
    player.collider = world:newBSGRectangleCollider(600, 0, 18, 58, 2)
    player.collider:setFixedRotation(true)
    player.x = 0
    player.y = 0
    player.speed = 100
    player.spriteSheet = love.graphics.newImage("sprites/spritesheet.png")
    player.grid = anim8.newGrid(46, 64, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid("1-4", 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid("1-4", 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid("1-4", 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid("1-4", 4), 0.2)
    player.anim = player.animations.down
    player.anim:gotoFrame(2)

    enemy = {}
    enemy.x = 400
    enemy.y = 300
    enemy.speed = 90
    enemy.spriteSheet = love.graphics.newImage("sprites/enemyspritesheet.png")
    enemy.grid = anim8.newGrid(90, 170, enemy.spriteSheet:getWidth(), enemy.spriteSheet:getHeight())
    enemy.animation = anim8.newAnimation(enemy.grid("1-6", 1), 0.2)
    
    sounds = {}
    sounds.steps = love.audio.newSource("sounds/steps.wav", "static")
    sounds.pagegrab = love.audio.newSource("sounds/pagegrab.wav", "static")
    sounds.wind = love.audio.newSource("sounds/wind.wav", "stream")
    sounds.wind:setLooping(true)
    sounds.music = love.audio.newSource("sounds/musicbox.mp3", "stream")
    
    walls = {}
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType("static")
            table.insert(walls, wall)
        end
    end

    startMenu = true
    gameEndedW = false
    gameEndedL = false

    pagesCollected =  0
    page1 = false
    page2 = false
    page3 = false
    page4 = false
    page5 = false
    caught = false
    enemyTimer = 10
    pageTimer = 0
    caughtTimer = 2
    runScreenTimer = 4
    originalPlayerSpeed = player.speed
    originalEnemySpeed = enemy.speed
end

function love.update(dt)
    if startMenu == true then
        if love.keyboard.isDown("return") then 
            startMenu = false
        end
        if love.keyboard.isDown("escape") then
            love.event.quit() 
        end
    end

    if gameEndedL == true then
        if love.keyboard.isDown("escape") then
            love.event.quit() 
        end
    end

    if gameEndedW == true then
        if love.keyboard.isDown("escape") then
            love.event.quit() 
        end
    end

    if caught == true then
        sounds.music:stop()
        caughtTimer = caughtTimer - dt
        if caughtTimer <= 0 then
            gameEndedL = true
        end
    end
    if startMenu == false and gameEndedW == false and gameEndedL == false and caught == false then
        enemy.speed = originalEnemySpeed + 20 * pagesCollected

        vx = 0
        vy = 0

        sounds.wind:play()

        if pagesCollected > 0 then
            sounds.music:play()
        end

        grabbingPages(player)
        if pageTimer > 0 then
            pageTimer = pageTimer - dt
        end
        if runScreenTimer > 0 then
            runScreenTimer = runScreenTimer - dt
        end

        if love.keyboard.isDown("lshift") then
            player.speed = originalPlayerSpeed * 2
        else
            player.speed = originalPlayerSpeed
        end
    
        if characterIsMoving(player, dt) then
            sounds.steps:play()
        else
            sounds.steps:stop()
        end
        player.collider:setLinearVelocity(vx, vy)

        if pagesCollected > 0 then
            goToCharacter(enemy, player, dt)
        end

        world:update(dt)
        player.x = player.collider:getX() - 23
        player.y = player.collider:getY() - 30

        cam:lookAt(player.x + 23, player.y + 32)
        cam:zoomTo(2)

        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()

        if cam.x < w/4 then
            cam.x = w/4
        end

        if cam.y < h/4 then
            cam.y = h/4
        end

        local mapW = gameMap.width * gameMap.tilewidth
        local mapH = gameMap.height * gameMap.tileheight

        if cam.x > (mapW - w/4) then
            cam.x = (mapW - w/4)
        end

        if cam.y > (mapH - h/4) then
            cam.y = (mapH - h/4)
        end

        player.anim:update(dt)
        enemy.animation:update(dt)
    end
end


function love.draw()
    if startMenu == true then
        love.graphics.draw(menu, 0, 0)
    end

    if gameEndedL == true then
        love.graphics.draw(gameEndL, 0, 0)
    end

    if gameEndedW == true then
        love.graphics.draw(gameEndW, 0, 0)
    end

    if startMenu == false and gameEndedW == false and gameEndedL == false then
        cam:attach()
            gameMap:drawLayer(gameMap.layers["background"])
            player.anim:draw(player.spriteSheet, player.x, player. y)
            gameMap:drawLayer(gameMap.layers["car"])
            gameMap:drawLayer(gameMap.layers["building"])
            gameMap:drawLayer(gameMap.layers["rocks"])
            gameMap:drawLayer(gameMap.layers["trees"])
            gameMap:drawLayer(gameMap.layers["paper"])
            gameMap:drawLayer(gameMap.layers["dead end sign"])
            gameMap:drawLayer(gameMap.layers["beware sign"])
            love.graphics.draw(darkness, player.x+21-960, player.y+25-540)
            if pagesCollected > 0 then
                enemy.animation:draw(enemy.spriteSheet, enemy.x, enemy.y)
            end
            if pageTimer > 0 and pagesCollected < 5 then
                love.graphics.setFont(font)
                love.graphics.print(tostring(pagesCollected) .. " PAGES COLLECTED", cam.x-135, cam.y-150)
            end
            if runScreenTimer > 0 then
                love.graphics.setFont(font)
                love.graphics.print("PRESS LEFT SHIFT TO RUN", 210, 150)
                love.graphics.print("COLLECT 5 PAGES", 710, 150)
            end
            -- world:draw()
        cam:detach()
    end
end

function characterIsMoving(character, dt)
    IsMoving = false
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        vx = character.speed
        player.anim = player.animations.right
        IsMoving = true
    end

    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        vx = character.speed * -1
        player.anim = player.animations.left
        IsMoving = true
    end

    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        vy = character.speed
        player.anim = player.animations.down
        IsMoving = true
    end

    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        vy = character.speed * -1
        player.anim = player.animations.up
        IsMoving = true
    end
    if IsMoving == false then
        player.anim:gotoFrame(2)
    end
    return IsMoving
end

function goToCharacter(hunter, prey, dt)
    if hunter.x < prey.x then
        hunter.x = hunter.x + hunter.speed * dt
    end
    if hunter.x > prey.x then
        hunter.x = hunter.x - hunter.speed * dt
    end
    if hunter.y < prey.y - 64 then
        hunter.y = hunter.y + hunter.speed * dt
    end
    if hunter.y > prey.y - 64 then
        hunter.y = hunter.y - hunter.speed * dt
    end
    if (hunter.x == prey.x and hunter.y == prey.y - 64) or (math.abs(hunter.x - prey.x) < hunter.speed * dt and math.abs(hunter.y - (prey.y - 64)) < hunter.speed * dt) then
        caught = true
    end
end

function grabbingPages(player)
    if page1 == false and 1280 < player.y + 32 and player.y + 32 < 1344 and 448 < player.x + 23 and player.x + 23 < 512 then
        page1 = true
        pageTimer = 3
        pagesCollected = pagesCollected + 1
        sounds.pagegrab:play()
    end
    if page2 == false and 2304 < player.y + 32 and player.y + 32 < 2368 and 128 < player.x + 23 and player.x + 23 < 192 then
        page2 = true
        pageTimer = 3
        pagesCollected = pagesCollected + 1
        sounds.pagegrab:play()
    end
    if page3 == false and 1152 < player.y + 32 and player.y + 32 < 1216 and 1600 < player.x + 23 and player.x + 23 < 1664 then
        page3 = true
        pageTimer = 3
        pagesCollected = pagesCollected + 1
        sounds.pagegrab:play()
    end
    if page4 == false and 2304 < player.y + 32 and player.y + 32 < 2368 and 2112 < player.x + 23 and player.x + 23 < 2176 then
        page4 = true
        pageTimer = 3
        pagesCollected = pagesCollected + 1
        sounds.pagegrab:play()
    end
    if page5 == false and 348 < player.y + 32 and player.y + 32 < 448 and 1280 < player.x + 23 and player.x + 23 < 1344 then
        page5 = true
        pageTimer = 3
        pagesCollected = pagesCollected + 1
        sounds.pagegrab:play()
    end
    if pagesCollected == 5 then
        gameEndedW = true
    end
end

function inArea(player, enemy)
    isNear = false
    dx = math.abs(enemy.x - player.x)
    dy = math.abs(enemy.y - player.y)
    if dx <= 256 and dy <= 256 then
        isNear = true
    end
    return isNear
end