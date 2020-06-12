#! /bin/bash

declare -A FIELD_SIZE=( ["X"]=0 ["Y"]=0 ["CELL_COUNT"]=0)
declare -A BALL=( ["X"]=0 ["Y"]=0 ["dX"]=0 ["dY"]=0 )
declare -a FRAMEBUFFER # get sized and initialized in 'init_vars'
declare -A PLAYER_1=( ["X"]=0 ["Y"]=0 ["RADIUS"]=0 ["IS_AI"]=true ["POINTS"]=0)
declare -A PLAYER_2=( ["X"]=0 ["Y"]=0 ["RADIUS"]=0 ["IS_AI"]=true ["POINTS"]=0)


function init_vars
{
	tty_size=$(stty size)
	tty_size=( $tty_size )

	FIELD_SIZE["Y"]=${tty_size[0]}
	FIELD_SIZE["X"]=${tty_size[1]}
	FIELD_SIZE["CELL_COUNT"]=$(( ${FIELD_SIZE["X"]}*${FIELD_SIZE["Y"]} ))

	# set the initial random vector of the ball
	BALL["X"]=$(( ${FIELD_SIZE["X"]} / 2 ))
	BALL["Y"]=$(( ${FIELD_SIZE["Y"]} / 2 ))

	direction_x=$(( 1 - 2 * ($RANDOM % 2) ))
	direction_y=$(( 1 - 2 * ($RANDOM % 2) ))

	BALL["dX"]=$(( ($RANDOM % 4 + 1) * direction_x ))
	BALL["dY"]=$(( ($RANDOM % 2 + 1) * direction_y ))

	# set the initial player vars
	player_height=$(( ${FIELD_SIZE["Y"]}/10 ))
	PLAYER_1["RADIUS"]=$player_height
	PLAYER_2["RADIUS"]=$player_height

	PLAYER_1["X"]=1
	PLAYER_1["Y"]=${BALL["Y"]}
	PLAYER_2["X"]=$(( ${FIELD_SIZE["X"]} - 2 ))
	PLAYER_2["Y"]=${BALL["Y"]}

	declare -a FRAMEBUFFER[${FIELD_SIZE["CELL_COUNT"]}]
}


function update_ai
{
	declare -n ai="$1"

	# move the player one field in Y towards the ball
	ai_ball_dist=$(( ${ai["Y"]} - ${BALL["Y"]} ))

	#TODO check weather if player can move in this direction
	if [ $ai_ball_dist -ne 0 ]; then
		# normalize to length 1 but retain sign
		let ai["Y"]-=$(( ${ai_ball_dist#-} / $ai_ball_dist ))
	fi
}


function update_ball
{
	# if collision on horizontal edges
	if [[
		${BALL["X"]} -le 1 ||
		${BALL["X"]} -ge $(( ${FIELD_SIZE["X"]} - 2 ))
	]]; then
		let BALL["dX"]*=-1
	fi

	# if collision on vertical edges
	if [[
		${BALL["Y"]} -le 1 ||
		${BALL["Y"]} -ge $(( ${FIELD_SIZE["Y"]} - 2 ))
	]]; then
		let BALL["dY"]*=-1
	fi

	let BALL["X"]+=${BALL["dX"]}
	let BALL["Y"]+=${BALL["dY"]}
}


function ball_is_colliding
{
	false
}


function ball_collides_with_player
{
	#TODO
	false
}


function update_game_logic
{
	if ball_is_colliding; then
		echo "TODO: handle collisions"
	else
		update_ball
	fi

	# handle players
	for p in {PLAYER_1,PLAYER_2}; do
		declare -n player="$p"

		if [ $player["IS_AI"] ]; then
			update_ai $p
		# else
			#TODO: handle player input here
		fi
	done
}


function render_framebuffer
{
	# draw the "pixels" in the tty into a framebuffer
	# for performance, all if conditions are inlined

	for cell_idx in $(seq 0 $(( ${FIELD_SIZE["CELL_COUNT"]} - 1 )) ) ; do

		local cell_x=$(( $cell_idx % ${FIELD_SIZE["X"]} ))
		local cell_y=$(( $cell_idx / ${FIELD_SIZE["X"]} ))
		#echo -n cell: $cell_idx, $cell_x/$cell_y; read

		# if is empty cell
		#if [[
		#	#TODO get active field maring correctly
		#	$(( ($cell_x + 2) % ${FIELD_SIZE["X"]} )) -gt 2 &&
		#	$(( ($cell_y + 1) % ${FIELD_SIZE["Y"]} )) -gt 1 &&
		#	$cell_x -ne ${BALL["X"]} &&
		#	$cell_y -ne ${BALL["Y"]}
		#]]; then
		#	FRAMEBUFFER[$cell_idx]='.'

		# if is border cell
		if [[
			$cell_x -eq 0 || $cell_y -eq 0 ||
			$cell_x -eq $(( ${FIELD_SIZE["X"]} - 1 )) ||
			$cell_y -eq $(( ${FIELD_SIZE["Y"]} - 1 ))
		]]; then
			FRAMEBUFFER[$cell_idx]='#'

		# if is player cell
		elif [[
			( $cell_x -eq ${PLAYER_1["X"]} || $cell_x -eq ${PLAYER_2["X"]} ) &&
			((
				$cell_y -ge $(( ${PLAYER_1["Y"]} - ${PLAYER_1["RADIUS"]} - 1 )) &&
				$cell_y -le $(( ${PLAYER_1["Y"]} + ${PLAYER_1["RADIUS"]} - 1 ))
			) || (
				$cell_y -ge $(( ${PLAYER_2["Y"]} - ${PLAYER_2["RADIUS"]} - 1 )) &&
				$cell_y -le $(( ${PLAYER_2["Y"]} + ${PLAYER_2["RADIUS"]} - 1 ))
			))
		]]; then
			FRAMEBUFFER[$cell_idx]='H'

		# if is ball cell
		elif [[ $cell_x -eq ${BALL["X"]} && $cell_y -eq ${BALL["Y"]} ]]; then
			FRAMEBUFFER[$cell_idx]='@'

		else
			FRAMEBUFFER[$cell_idx]=' '
		fi
	done
}


function draw_framebuffer
{
	tmp_fb=""

	for cell in "${FRAMEBUFFER[@]}"; do
		# we have to put the array in a string to echo it propperly
		tmp_fb+=$cell
	done

	echo -n "$tmp_fb"
}


function main {
	init_vars

	while true; do
		update_game_logic
		render_framebuffer
		draw_framebuffer
		#read
		#exit
	done
}


main

