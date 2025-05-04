-- name: [CS] Zoe Haste
-- description: Zoe from Haste by Landfall games brought to coopdx!!!

local CT_ZOE = _G.charSelect.character_add("Zoe", {"Has lots of jank!1!1!!!1!1", "Silly gal ZOOMIN", "Z: Charge dash/Stop dash", "A while dashing: SpeedJump"}, "Honibee", {r = 255, g = 85, b = 255}, E_MODEL_MARIO, CT_MARIO)

local charge_acts = {
    ACT_IDLE,
    ACT_CROUCHING,
    ACT_CROUCH_SLIDE
}
local chargeActs = 3

--@param m MarioState
function is_chargeable(m)
    for i = 0, chargeActs do
        if (charge_acts[i] == m.action) then
            return true
        end
    end
    if (m.action & ACT_FLAG_CUSTOM_ACTION == 0) then
        return false
    end
    if (m.action & ACT_FLAG_THROWING ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_DIVING ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_AIR ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_FLYING ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_HANGING ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_INTANGIBLE ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_METAL_WATER ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_ON_POLE ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_RIDING_SHELL ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_SWIMMING ~= 0) then
        return false
    end
    if (m.action & ACT_FLAG_SWIMMING_OR_FLYING ~= 0) then
        return false
    end
    return true
end

function is_water_act(action)
    return action == ACT_WATER_IDLE or action == ACT_SWIMMING_END or action == ACT_WATER_ACTION_END
end

chargedSpeed = 0
curSpeed = 0
energy = 0

--@param m MarioState
local function zoe_does_things (m)
    if energy > 100 then energy = 100 end
    if energy < 0 then energy = 0 end

    m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 900)
    m.hurtCounter = 0

    --running start
    if is_chargeable(m) and (m.controller.buttonDown & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_RUNNING_START, 0)
    end

    --water drill
    if is_water_act(m.action) and (m.controller.buttonDown & Z_TRIG) ~= 0 then
        set_mario_action(m, ACT_SWIM_DRILL, 0)
    end
end

_G.charSelect.character_hook_moveset(CT_ZOE, HOOK_MARIO_UPDATE, zoe_does_things)