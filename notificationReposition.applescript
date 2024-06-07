#!/usr/bin/osascript
tell application "System Events"
    tell application process "NotificationCenter"
        repeat while true
            if exists window "Notification Center" then -- Check if the window exists
                try
                    repeat with theWindow in window "Notification Center"
                        set displaySize to size of theWindow
                        set notifSize to size of UI element 1 of scroll area 1 of group 1 of theWindow
                        -- Check if position adjustment is needed
                        set currentPos to position of theWindow
                        set newPos to {-((first item of displaySize) - (first item of notifSize) ) * 3/ 4, ( 0 )}
                        if currentPos ≠ newPos then
                            set position of theWindow to newPos
                        end if
                    end repeat
                end try
            end if
            delay 0.5 -- Consider adjusting this based on how responsive it needs to be
        end repeat
    end tell
end tell
