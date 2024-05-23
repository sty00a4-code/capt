RAW_REPO_LINK = "https://raw.githubusercontent.com/sty00a4-code/capt/main"
local function packagePath(path)
    return RAW_REPO_LINK.."/"..path
end
---@param type "info"|"warn"|"cmd"|"error"
---@param msg string
local function log(type, msg)
    print(("[%s] %s"):format(type:upper(), msg))
end

local function readURL(url)
    local response, err = http.get(url)
    if not response then
        return nil, err
    end
    local code = response.readAll()
    response.close()
    return code
end
local function callCode(code)
    local chunk, err = load(code, "code")
    if not chunk then
        return nil, err
    end
    local success, res = pcall(chunk)
    if not success then
        return nil, res
    end
    return res
end

local function install(name, target, upgrade)
    target = target or ""
    local url = packagePath("packages/"..name)
    log("info", "reading from "..url)
    local code, err = readURL(url)
    if not code then
        return false, err
    end
    log("info", "calling code")
    local res, err = callCode(code)
    if not res then
        return false, err
    end
    if type(res) == "string" then
        log("info", "installing "..res)
        local code, err = readURL(res)
        if not code then
            return false, err
        end
        local fullPath = target.."/"..name..".lua"
        if upgrade then
            if fs.exists(fullPath) then
                return false, "file at '"..fullPath.."' already exists"
            end
        end
        local file = fs.open(fullPath, "w")
        if not file then
            return false, "couldn't open file at '"..fullPath.."'"
        end
        log("info", "writing to "..fullPath)
        file:write(code)
        file:close()
        log("info", "done!")
    else
        return false, "package did not return a url"
    end
end

local cmd, name, target = ...
if not cmd then
    print([[USAGE
    capt install <name> [<target>] - installs the package in the capt register (target directory is optional)
    capt update - updates the capt program
    capt upgrade <name> - updates the package
    ]])
    return
end
if cmd == "install" then
    if not name then
        log("error", "no name provided")
        return
    end
    local success, err = install(name, target)
    if not success then
        log("error", tostring(err))
        return
    end
elseif cmd == "update" then
    local path = packagePath("capt")
    log("info", "reading from "..path)
    local code = readURL(path)
    local fullPath = target.."/"..name..".lua"
    local file = fs.open(fullPath, "w")
    if not file then
        return false, "couldn't open file at '"..fullPath.."'"
    end
    log("info", "writing to "..fullPath)
    file:write(code)
    file:close()
    log("info", "done!")
elseif cmd == "upgrade" then
    if not name then
        log("error", "no name provided")
        return
    end
    local success, err = install(name, target, true)
    if not success then
        log("error", tostring(err))
        return
    end
else
    log("error", "invalid command: "..cmd)
    return
end