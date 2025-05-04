ACT_RUNNING_START = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_IDLE) --DONE

ACT_DASHING = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING) --DONE

ACT_LAUNCH_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR) -- DONE

ACT_FALL_LAUNCH = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR) -- DONE

ACT_DIVE_DOWN = allocate_mario_action(ACT_GROUP_AIRBORNE) --DONE

ACT_BOARD = allocate_mario_action(ACT_GROUP_MOVING |ACT_FLAG_CUSTOM_ACTION) -- DONE

ACT_BOARD_AIR = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_CUSTOM_ACTION) --DONE (MOSTLY)

ACT_SWIM_DRILL = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_SWIMMING |ACT_FLAG_WATER_OR_TEXT)


--@param m MarioState
local function zoe_running_start_loop(m)
    set_mario_animation(m, CHAR_ANIM_SKID_ON_GROUND)
    chargedSpeed = chargedSpeed + 6
    if chargedSpeed > 90  then chargedSpeed = 90 end
    if m.controller.buttonDown & Z_TRIG == 0 then
        set_mario_action(m, ACT_DASHING, 0)
        curSpeed = chargedSpeed
    end
end

hook_mario_action(ACT_RUNNING_START, { every_frame = zoe_running_start_loop, gravity = nil})

--@param m MarioState
local function board_loop(m)
    if energy == 0 then
        return set_mario_action(m, ACT_DASHING, 0)
    end
    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_BEND_KNESS_RIDING_SHELL)
        curSpeed = curSpeed + 50
        mario_set_forward_vel(m, curSpeed)
    end
    energy = energy - 1

        m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    local step = perform_ground_step(m)
    if step == GROUND_STEP_LEFT_GROUND and (m.controller.buttonDown & Y_BUTTON ~= 0) then
        set_mario_action(m, ACT_BOARD_AIR, 0) --placeholder for ACT_BOARD_AIR
    end
    if m.controller.buttonDown & Y_BUTTON ==0 then
        set_mario_action(m, ACT_DASHING, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_BOARD, {every_frame = board_loop, gravity = nil})

--@param m MarioState
local function board_loop_air(m)
    if m.actionTimer > 0 then
        curSpeed = curSpeed + 30
        m.vel.y = m.vel.y + 50
        mario_set_forward_vel(m, curSpeed)
    end
    if energy == 0 then
        return set_mario_action(m, ACT_FALL_LAUNCH, 0)
    end
    energy = energy - 0.5

    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    local airStep = perform_air_step(m, 0)
    if airStep == AIR_STEP_LANDED then
        set_mario_action(m, ACT_BOARD, 0)
    end
    if m.controller.buttonDown & Y_BUTTON == 0 then
        set_mario_action(m, ACT_FALL_LAUNCH, 0)
    end
    m.actionTimer = 0
end

hook_mario_action(ACT_BOARD_AIR, board_loop_air)

--@param m MarioState
local function dash_loop(m)
    mario_set_forward_vel(m, curSpeed)
    if curSpeed >= 120 then curSpeed = 120 end
    set_mario_animation(m, CHAR_ANIM_RUNNING)

    local stepResult = perform_ground_step(m)

    if (stepResult == GROUND_STEP_LEFT_GROUND) then
        set_mario_action(m, ACT_FALL_LAUNCH, 0)
    end

    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    -- Stop dash if Z pressed again
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_BACKFLIP, 0)
        m.vel.y = 30
        chargedSpeed = 0
        curSpeed = 0
    end
    -- Jump if A button is pressed
    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        m.actionTimer = 0
        set_mario_action(m, ACT_LAUNCH_JUMP, 0)
    end

    if m.controller.buttonDown & Y_BUTTON ~= 0 then
        set_mario_action(m, ACT_BOARD, 0)
    end

    chargedSpeed =0
end

hook_mario_action(ACT_DASHING, { every_frame = dash_loop, gravity = nil })

--@param m MarioState
local function launch_loop(m)
    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_TRIPLE_JUMP)
        m.vel.y = curSpeed / 1.5
        if m.vel.y < 60 then m.vel.y = 60 end
        if m.vel.y > 60 then m.vel.y = 60 end
    end
	
	if m.vel.y < 0 then
		m.vel.y = m.vel.y + 2.5
	end
    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    local stepResult = perform_air_step(m, 0)
    if (stepResult == AIR_STEP_LANDED) then
        set_mario_action(m, ACT_DASHING, 0)
        curSpeed = curSpeed  + (- m.vel.y / 4)
        energy = energy + 20
    end

    -- Stop dash if Z pressed again
    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_BACKFLIP, 0)
        m.vel.y = 5
        m.forwardVel = 10
        chargedSpeed = 0
        curSpeed = 0
    end

    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        set_mario_action(m,ACT_DIVE_DOWN, 0)
    end
    if m.controller.buttonDown & Y_BUTTON ~=0 then
        m.actionTimer = 0
        set_mario_action(m, ACT_BOARD_AIR, 0)
    end
    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_LAUNCH_JUMP, {every_frame = launch_loop, gravity = nil})

--@param m MarioState
local function falling_down(m)
    if m.actionTimer == 0 then
        m.vel.y = -5
        set_mario_animation(m, CHAR_ANIM_FLY_FROM_CANNON)
    end
if m.vel.y < 0 then
    m.vel.y = m.vel.y + 1.5
end
    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    local airStep = perform_air_step(m, 0)

    if airStep == AIR_STEP_LANDED then
        curSpeed = curSpeed + (-m.vel.y / 4)
        set_mario_action(m, ACT_DASHING, 0)
        energy = energy + 10
    end

    if (m.controller.buttonPressed & A_BUTTON) ~= 0 then
        set_mario_action(m,ACT_DIVE_DOWN, 0)
    end

    if (m.controller.buttonPressed & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_BACKFLIP, 0)
        m.vel.y = 30
        chargedSpeed = 0
        curSpeed = 0
    end

    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_FALL_LAUNCH, {every_frame = falling_down, gravity = nil})

--@param m MarioState
local function dive_down(m)
    if m.actionTimer > 0 then
        set_mario_animation(m, CHAR_ANIM_SWIM_PART2)
        m.vel.y = m.vel.y - 10
    end

    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 700)
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    local airStep = perform_air_step(m, 0)
    if airStep == AIR_STEP_LANDED then
        curSpeed = curSpeed + (-m.vel.y)
        set_mario_action(m, ACT_DASHING, 0)
        energy = energy + 30
    end

    if (m.controller.buttonDown & A_BUTTON) == 0 then
        m.actionTimer = 0
        set_mario_action(m, ACT_FALL_LAUNCH, 0)
    end
end

hook_mario_action(ACT_DIVE_DOWN, {every_frame = dive_down, gravity = nil})

--@param m MarioState
local function swim_drill(m)
    mario_set_forward_vel(m, 120)
    set_mario_animation(m, CHAR_ANIM_DIVE)

    perform_water_step(m)
    m.faceAngle.z = m.faceAngle.z + 10000
    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.controller.stickX, m.controller.stickX) 
    m.vel.x = sins(m.faceAngle.y) * m.forwardVel
    m.vel.z = coss(m.faceAngle.y) * m.forwardVel

    if m.controller.stickY > 0 then
       m.faceAngle.x = approach_s16_symmetric(m.faceAngle.x, -10000, 1000)
       m.vel.y = m.vel.y - 6
    elseif m.controller.stickY < 0 then
        m.faceAngle.x = approach_s16_symmetric(m.faceAngle.x, 10000, 1000)
        m.vel.y = m.vel.y + 6
    
    end
    if m.controller.stickY == 0 then
        m.vel.y = 0
        m.faceAngle.x = approach_s16_symmetric(m.faceAngle.x, 0, 1000)
    else return
    end
    if m.controller.buttonDown & Z_TRIG == 0 then
        set_mario_action(m, ACT_WATER_IDLE, 0)
    end
end
hook_mario_action(ACT_SWIM_DRILL, swim_drill)