#!/opt/homebrew/bin/bash

# Function to retrieve the count of open windows for a specified application
get_open_window_count() {
	local app_name="$1"
	local window_ids=()
	local open_windows_count=0

	# Use a while loop to read each line output by jq into the array
	while IFS= read -r line; do
		window_ids+=("$line")
	done < <(yabai -m query --windows | jq -r --arg app "$app_name" '.[] | select(.app == $app) | .id')

	# Get the count of open windows
	open_windows_count=${#window_ids[@]}
	echo "$open_windows_count"
}

# Function to open a new window for a specified application using menu item method
# Arguments:
#   $1: Application name
#   $2: (Optional) Menu item index (default: 1)
#   $3: (Optional) Menu name (default: "File")
oepen_new_window() {
	local app_name="$1"
	local menu_index="1"   # Default menu item index
	local menu_name="File" # Default menu name

	case "$app_name" in
	"Microsoft OneNote")
		# For Microsoft OneNote, use Control+M keystroke
		osascript -e 'tell application "Microsoft OneNote" to activate' -e 'tell application "System Events" to keystroke "m" using control down'
		;;
	*)
		# For other applications, click on the specified menu item
		osascript -e 'tell application "System Events" to tell process "'"$app_name"'" to click menu item '"$menu_index"' of menu "'"$menu_name"'" of menu bar 1'
		;;
	esac
}

open_new_window() {
	local app_name="$1"

	# Initialize associative arrays with configurations for iTerm2 and Orienter
	declare -A app_menu_names=(["iTerm2"]="Shell" ["Orienter"]="Window" ["Google Chrome"]="File")
	declare -A app_menu_indexes=(["iTerm2"]="1" ["Orienter"]="3" ["Google Chrome"]="2")

	# Default values
	local default_menu_name="File"
	local default_menu_index="1"

	# Determine menu name and index based on app_name, falling back to defaults if not found
	local menu_name="${app_menu_names[$app_name]:-$default_menu_name}"
	local menu_index="${app_menu_indexes[$app_name]:-$default_menu_index}"

	if [[ "$app_name" == "Microsoft OneNote" ]]; then
		# Special command for Microsoft OneNote
		osascript -e 'tell application "Microsoft OneNote" to activate' \
			-e 'tell application "System Events" to keystroke "m" using control down'
	else
		# Generic command for other applications, using determined menu name and index
		osascript -e "tell application \"System Events\" to tell process \"$app_name\"" \
			-e "click menu item $menu_index of menu \"$menu_name\" of menu bar 1" \
			-e "end tell"
	fi
}

# Function to open windows for a specified application until the threshold is reached
# Arguments:
#   $1: Application name
#   $2: Threshold for the number of open windows
#   $3: Maximum number of attempts to open new windows
open_windows_until_threshold() {
	local app_name="$1"
	local threshold="$2"
	local max_attempts="$3"
	local open_windows_count=$(get_open_window_count "$app_name")
	local attempts=0

	# Open a new window using menu item method if no windows are open
	if [ "$open_windows_count" -eq 0 ]; then
		echo "No windows open for $app_name. Opening a new window."
		open -a "$app_name"
		sleep 1 # Adjust based on application startup time
		open_windows_count=$(get_open_window_count "$app_name")
	fi

	# Continuously open windows until the threshold is reached or maximum attempts exceeded
	while [ "$open_windows_count" -lt "$threshold" ] && [ "$attempts" -lt "$max_attempts" ]; do
		echo "Opening window attempt $((attempts + 1)) for $app_name. Currnt Open Windows: $open_windows_count"
		# Open a new window for the application using open_new_window() function if only one window is open
		if [ "$open_windows_count" -gt 0 ]; then
			open_new_window "$app_name"
		else
			# Open a new window using the open command
			open -a "$app_name"
		fi
		 sleep 2 # Adjust based on application startup time

		# Update the count of open windows
		open_windows_count=$(get_open_window_count "$app_name")
		((attempts++))
	done

	# If the threshold is still not reached after maximum attempts, exit with an error message
	if [ "$open_windows_count" -lt "$threshold" ]; then
		echo "Failed to open the required number of windows for $app_name after $max_attempts attempts. Exiting."
		# exit 1
	else
		echo "Successfully opened $threshold windows for $app_name."
	fi
}

# Function to get window IDs of a specific application
# Arguments:
#   $1: Application name
get_window_ids() {
	local app_name="$1"
	local window_ids=()

	# Use a while loop to read each line output by jq into the array
	while IFS= read -r line; do
		window_ids+=("$line")
	done < <(yabai -m query --windows | jq -r --arg app "$app_name" '.[] | select(.app == $app) | .id')

	# Return the array of window IDs
	echo "${window_ids[@]}"
}

# Function to move windows of a specific application to specific spaces
# Arguments:
#   $1: Application name
#   $2: Array of space numbers
move_app_windows_to_spaces() {
	local app_name="$1"
	local -a spaces_arg=("${!2}")
	local -a window_ids=($(get_window_ids "$app_name"))
	local -a space_usage=()
	local -a spaces=()

	# Prepare space_usage based on spaces_arg
	for space in "${spaces_arg[@]}"; do
		space_usage+=("$space")
	done

	# Iterate over each window ID
	for id in "${window_ids[@]}"; do
		if [[ "${#space_usage[@]}" -gt 0 ]]; then
			local next_space=${space_usage[0]}
			yabai -m window "$id" --space "$next_space"
			echo "Moved window ID $id to space $next_space."
			# Remove the used space from the beginning of space_usage
			space_usage=("${space_usage[@]:1}")
			# sleep 2
		else
			echo "No available space for window ID $id. Closing Window"
			yabai -m window "$id" --close
			echo "Current window count for $app_name : $(get_open_window_count "$app_name")"
		fi
	done
}

# Function to open windows for a specified application until the threshold is reached
# and then move those windows to specific spaces
# Arguments:
#   $1: Application name
#   $2: Threshold for the number of open windows
#   $3: Maximum number of attempts to open new windows
#   $4: Array of space numbers
open_and_move_windows() {
	local app_name="$1"
	local threshold="$2"
	local max_attempts="$3"
	local spaces=("${!4}")

	# Call the function to open windows until the threshold is reached
	open_windows_until_threshold "$app_name" "$threshold" "$max_attempts"
	# sleep 5
	# Move windows to specific spaces
	move_app_windows_to_spaces "$app_name" spaces[@]
}


####################################### Space 1 ####################################


# # Usage example:
# app_name="YT Music"
# threshold=1
# max_attempts=5
# spaces=(1)

# # Call the function to open windows until the threshold is reached and move them to specific spaces
# open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

# Usage example:
app_name="Reminders"
threshold=1
max_attempts=5
spaces=(1)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

# Usage example:
app_name="Structured"
threshold=1
max_attempts=5
spaces=(1)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

# # Usage example:
# app_name="Insta360 Link Controller"
# threshold=1
# max_attempts=5
# spaces=(1)

# # Call the function to open windows until the threshold is reached and move them to specific spaces
# open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]


####################################### Space 1 ####################################

####################################### Space 2 ####################################

# Usage example:
app_name="Microsoft Outlook"
threshold=1
max_attempts=5
spaces=(2)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]


## ChatGPT

####################################### Space 2 ####################################

####################################### Space 3 ####################################

## Safari 
## ChatGPT
####################################### Space 3 ####################################

####################################### Space 4 ####################################
# Usage example:
app_name="Slack"
threshold=1
max_attempts=5
spaces=(4)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]


####################################### Space 4 ####################################



# Usage example:
app_name="Calendar"
threshold=1
max_attempts=5
spaces=(2)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]






# Usage example:
app_name="Sublime Text"
threshold=1
max_attempts=5
spaces=(9)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]






####################################### Multiple Spaces ####################################

# Usage example:
app_name="ChatGPT"
threshold=3
max_attempts=5
spaces=(2 3 7)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]





# Usage example:
app_name="iTerm2"
threshold=2
max_attempts=5
spaces=(9 9)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]


# Usage example:
app_name="Microsoft OneNote"
threshold=3
max_attempts=5
spaces=(5 5 10)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

####################################### Multiple Spaces ####################################

# Usage example:
app_name="Google Chrome"
threshold=2
max_attempts=5
spaces=(3 7)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

# Usage example:
app_name="Safari"
threshold=3
max_attempts=5
spaces=(1 1 1)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]

# Usage example:
app_name="Finder"
threshold=1
max_attempts=5
spaces=(6)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]


# Usage example:
app_name="IntelliJ IDEA"
threshold=1
max_attempts=5
spaces=(8)

# Call the function to open windows until the threshold is reached and move them to specific spaces
open_and_move_windows "$app_name" "$threshold" "$max_attempts" spaces[@]














