local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function DoorIsEnterable(f)

    -- VERY ugly workaround for pass by reference/value problem (I think?)
    -- at this point i cant find a better solution...
    local params = f.fixture_parameters
    params["is_opening"] = 1
    f.fixture_parameters = params


    if f.fixture_parameters["open"] >= 1 then
        return 0
    end

    return 2
end

local function clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end



function DoorUpdateAction(f, delta)

    local params = f.fixture_parameters

    if f.fixture_parameters["is_opening"] >= 1 then
        params["open"] = params["open"] + (delta * 4)

        f.fixture_parameters = params
        f.on_changed.emit(f)
        if f.fixture_parameters["open"] >= 1 then
            params["is_opening"] = 0
        end
    else
        params["open"] = params["open"] - (delta * 4)
        f.fixture_parameters = params
        f.on_changed.emit(f)
    end

    params["open"] = clamp(f.fixture_parameters["open"], 0, 1)
    f.fixture_parameters = params

end


