' Normalizes keyboard names used by the browser/simulator to Roku-style
' remote commands while leaving unknown keys untouched so text inputs can
' continue receiving normal typing events.
function NormalizeRemoteKey(key as string) as string
    normalizedKey = LCase(key)

    if normalizedKey = "enter" or normalizedKey = "select" or normalizedKey = "numpad5" or normalizedKey = "kp5"
        return "ok"
    end if

    if normalizedKey = "escape" or normalizedKey = "backspace" or normalizedKey = "browserback" or normalizedKey = "numpad0" or normalizedKey = "kp0"
        return "back"
    end if

    if normalizedKey = "arrowup" or normalizedKey = "up" or normalizedKey = "numpad8" or normalizedKey = "kp8"
        return "up"
    end if

    if normalizedKey = "arrowdown" or normalizedKey = "down" or normalizedKey = "numpad2" or normalizedKey = "kp2"
        return "down"
    end if

    if normalizedKey = "arrowleft" or normalizedKey = "left" or normalizedKey = "numpad4" or normalizedKey = "kp4"
        return "left"
    end if

    if normalizedKey = "arrowright" or normalizedKey = "right" or normalizedKey = "numpad6" or normalizedKey = "kp6"
        return "right"
    end if

    if normalizedKey = "numpad7" or normalizedKey = "kp7"
        return "home"
    end if

    if normalizedKey = "numpad9" or normalizedKey = "kp9"
        return "options"
    end if

    if normalizedKey = "delete" or normalizedKey = "del" or normalizedKey = "numpaddecimal" or normalizedKey = "decimal" or normalizedKey = "kpdecimal" or normalizedKey = "numpad."
        return "delete"
    end if

    return normalizedKey
end function
