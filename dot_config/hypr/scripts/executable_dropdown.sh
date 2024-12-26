#!/bin/bash
DROPDOWN_CLASS="kitty-dropdown"

handle_dropdown() {
    if [[ ! $(hyprctl clients | grep "class: $DROPDOWN_CLASS") ]]; then
        # If not running, start it
        kitty --class $DROPDOWN_CLASS --config ~/.config/kitty/dropdown.conf &

        # Wait for window to spawn
        sleep 0.1

        # Focus the dropdown and center the cursor
        hyprctl dispatch focuswindow "class:^($DROPDOWN_CLASS)$"
        window_info=$(hyprctl clients -j | jq ".[] | select(.class == \"$DROPDOWN_CLASS\")")

        if [[ ! -z "$window_info" ]]; then
            # Get window dimensions and position
            x=$(echo "$window_info" | jq '.at[0]')
            y=$(echo "$window_info" | jq '.at[1]')
            width=$(echo "$window_info" | jq '.size[0]')
            height=$(echo "$window_info" | jq '.size[1]')

            # Calculate center position
            center_x=$((x + width/2))
            center_y=$((y + height/2))

            # Move cursor to center of window
            hyprctl dispatch movecursor "$center_x" "$center_y"
        fi
    else
        # If running, toggle visibility
        hyprctl dispatch togglespecialworkspace kitty
    fi
}

# Kill any existing socat processes for this script
pkill -f "socat.*hypr.*dropdown-monitor"

# Start monitoring focus changes
(
    socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
        if [[ $line == *"activewindow>>"* ]]; then
            current_window=$(echo "$line" | cut -d'>' -f3)
            if [[ ! "$current_window" =~ "kitty-dropdown" ]] && [[ $(hyprctl clients | grep "class: $DROPDOWN_CLASS") ]]; then
                hyprctl dispatch togglespecialworkspace kitty
            fi
        fi
    done
) &

# Main execution
handle_dropdown
