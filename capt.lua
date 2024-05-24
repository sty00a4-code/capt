local capt = setmetatable({}, {
    __name = "capt",
    __newindex = function ()
        error("module is immutable", 2)
    end
})
capt.RAW_REPO_LINK = "https://raw.githubusercontent.com/sty00a4-code/capt/main"
function capt.packagePath(path)
    return capt.RAW_REPO_LINK.."/"..path
end
---@param type "info"|"warn"|"cmd"|"error"
---@param msg string
function capt.log(type, msg)
    print(("[%s] %s"):format(type:upper(), msg))
end

function capt.readURL(url)
    local response, err = http.get(url)
    if not response then
        return nil, err
    end
    local code = response.readAll()
    response.close()
    return code
end
function capt.callCode(code)
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

function capt.install(name, target, upgrade)
    target = target or ""
    local url = capt.packagePath("packages/"..name..".lua")
    capt.log("info", "reading from "..url)
    local code, err = capt.readURL(url)
    if not code then
        return false, err
    end
    capt.log("info", "calling code")
    local res, err = capt.callCode(code)
    if not res then
        return false, err
    end
    if type(res) == "string" then
        capt.log("info", "installing "..res)
        local code, err = capt.readURL(res)
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
        capt.log("info", "writing to "..fullPath)
        file:write(code)
        file:close()
        capt.log("info", "done!")
    elseif type(res) == "function" then
        capt.log("info", "running installer ")
        local prevDir = shell.dir()
        shell.setDir(target)
        local success, err = pcall(res, capt)
        shell.setDir(prevDir)
        if not success then
            return false, "error in installer: "..tostring(err)
        end
        capt.log("info", "done!")
    else
        return false, "package did not return a url or installer"
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
        capt.log("error", "no name provided")
        return
    end
    local success, err = capt.install(name, target)
    if not success then
        capt.log("error", tostring(err))
        return
    end
elseif cmd == "update" then
    target = target or ""
    local path = capt.packagePath("capt")
    capt.log("info", "reading from "..path)
    local code = capt.readURL(path)
    local fullPath = target.."/capt.lua"
    local file = fs.open(fullPath, "w")
    if not file then
        return false, "couldn't open file at '"..fullPath.."'"
    end
    capt.log("info", "writing to "..fullPath)
    file:write(code)
    file:close()
    capt.log("info", "done!")
elseif cmd == "upgrade" then
    if not name then
        capt.log("error", "no name provided")
        return
    end
    local success, err = capt.install(name, target, true)
    if not success then
        capt.log("error", tostring(err))
        return
    end
else
    capt.log("error", "invalid command: "..cmd)
    return
end