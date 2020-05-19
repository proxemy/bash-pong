#!/bin/bash

declare tempvar
declare -A FIELD_SIZE=( ["X"]=0 ["Y"]=0 ["CELL_COUNT"]=0)
declare -a ball				# ball[0] = Y pos, ball[1] = X pos
declare -a d_ball			# movement. d_ball[0] = deltaY, d_ball[1] = deltaX
declare -a field 			# status of every single field
declare -i ball_field		# ball field in field array
declare -i player1			# player1 = Y pos, X pos = 2
declare -i player2			# player2 = Y pos , X pos = (FIELD_SIZE["Y"] - 1)
declare -i activefield		# index for active field
declare -i player_height		# size of players.


function init_vars
{
	# set static game variables
	tty_size=$(stty size)
	tty_size=( $tty_size )

	FIELD_SIZE["Y"]=${tty_size[0]}
	FIELD_SIZE["X"]=${tty_size[1]}
	let FIELD_SIZE["CELL_COUNT"]=${FIELD_SIZE["X"]}*${FIELD_SIZE["Y"]}

	let player_height=${FIELD_SIZE["X"]}/10

	# set the initial random vector of the ball
	direction_x=$(( 1 - 2 * ($RANDOM % 2) ))
	direction_y=$(( 1 - 2 * ($RANDOM % 2) ))

	d_ball[0]=$(( ($RANDOM % 4 + 1) * direction_x ))
	d_ball[1]=$(( ($RANDOM % 2 + 1) * direction_y ))

	# sets whole field array as empty
	for (( i=0; i<${FIELD_SIZE["CELL_COUNT"]}; i++ )); do
		field[$i]=0
	done
}


function game_loop {
	if (( ${ball[1]} <= 2 )) || (( ${ball[1]} >= ${FIELD_SIZE["Y"]} - 2 )); then				# game over cond
		calculate_ball_vector "1"
	elif (( ${ball[0]} <= 2 )) || (( ${ball[0]} >= ${FIELD_SIZE["X"]} - 2 )); then				# ball border bounce
		calculate_ball_vector "0"
	elif [ ${field[ (($ball_field-1)) ]} == 3 ] || [ ${field[ (($ball_field+1)) ]} == 3 ]; then	# player collision cond
		echo "PLAYER COLLISION ball = ${ball[@]}, player1=$player1, player2=$player2"
		exit
	fi

	tempvar=$(( (${ball[0]} - 1) * ${FIELD_SIZE["Y"]} + ${ball[1]} ))	# sets former ball field to empty
	field[$tempvar]=0

	ball[0]=$(( ${ball[0]} + ${d_ball[0]} )) # ball movement
	ball[1]=$(( ${ball[1]} + ${d_ball[1]} ))

	if (( ${ball[0]} <= 1 )); then			# ball border check, so it cant cross borders or change border fields (no re-init)
		#let "ball[0] += 1"
		ball[0]=2
	elif (( ${ball[0]} >= ${FIELD_SIZE["X"]}-1 )); then
		#let "ball[0] -= 1"
		ball[0]=$(( ${FIELD_SIZE["X"]} - 1 ))
	fi
	if (( ${ball[1]} <= 2 )); then
		#let "ball[1] += 1"
		ball[1]=3
	elif (( ${ball[1]} >= ${FIELD_SIZE["Y"]}-2 )); then
		#let "ball[1] -= 1"
		ball[1]=$(( ${FIELD_SIZE["Y"]} - 3 ))
	fi

	if (( $player1 < ball[0] )); then
		let "player1 += 1"
	elif (( $player1 > ball[0] )); then
		let "player1 -= 1"
	fi
	if (( $player2 < ball[0] )); then
		let "player2 += 1"
	elif (( $player2 > ball[0] )); then
		let "player2 -= 1"
	fi
}


function calculate_ball_vector {
	if (( $1 == 0 )); then		# border bounce
		let "d_ball[0] -= 2 * d_ball[0]"	#inverts delta
		#echo "new d_ball=\"${d_ball[1]}\""
	elif (( $1 == 1 )); then	# player bounce
		let "d_ball[1] -= 2 * d_ball[1]"		#inverts delta
	else
		echo "ERROR at f_ball(1) with ball[0,1]=\"${ball[@]}\", and d_ball[0,1]=\"${d_ball[@]}\""
		exit
	fi
}


function render_framebuffer {
	tempvar=$(( (${ball[0]} - 1) * ${FIELD_SIZE["Y"]} + ${ball[1]} ))	# calculates Xth field[] in array from X/Y ball-coordg
	field[$tempvar]=3	#sets ball
	ball_field=$tempvar

	for (( i=2; i<=${FIELD_SIZE["X"]}-1; i++ )); do		# empties the player column so players move and dont expand
		tempvar=$(( ($i - 1) * ${FIELD_SIZE["Y"]} + 2 ))
		field[$tempvar]=0	#empties left column

		tempvar=$(( $i * ${FIELD_SIZE["Y"]} - 2 ))
		field[$tempvar]=0	#empties right column
	done

	for (( i=playersize; i>=0; i-- )); do					# sets the player bodies in field[] according to player coords
		tempvar=$(( ($player1 - $i) * ${FIELD_SIZE["Y"]} + 2 ))		# calculates player 1 fields
		field[$tempvar]=2	#sets player1 UPPER end
		tempvar=$(( ($player1 + $i) * ${FIELD_SIZE["Y"]} + 2 ))		# calculates player 1 fields
		field[$tempvar]=2	#sets player1 LOWER end

		tempvar=$(( ($player2 - $i) * ${FIELD_SIZE["Y"]} - 2 ))		# calculates player 2 fields
		field[$tempvar]=2	#sets player2 UPPER end
		tempvar=$(( ($player2 + $i) * ${FIELD_SIZE["Y"]} - 2 ))		# calculates player 2 fields
		field[$tempvar]=2	#sets player2 LOWER end
	done
}


function init_framebuffer {
	for (( i=0; i<${FIELD_SIZE["CELL_COUNT"]}; i++ )); do

		if (( $i <= ${FIELD_SIZE["X"]} - 1 )) || (( $i >= ${#field[@]} - ${FIELD_SIZE["X"]} - 1 )) || # cond for horizontal borders
		(( $i % ${FIELD_SIZE["X"]} == 0 )) || (( $i % ${FIELD_SIZE["X"]} == ${FIELD_SIZE["X"]} - 1 )) # cond for vertical borders
		then
			field[$i]=1		# sets field border
		fi
	done


	ball[0]=${FIELD_SIZE["X"]}	# set ball Y in middle
	let "ball[0]/=2"

	ball[1]=${FIELD_SIZE["Y"]}	# set ball X in middle
	let "ball[1]/=2"

	player1=${FIELD_SIZE["Y"]}	# set player1 in middle
	let "player1/=2"

	player2=${FIELD_SIZE["Y"]}	# set player2 in middle
	let "player2/=2"
}


function echo_framebuffer {
	unset tempvar
	for (( i=0; i<=${#field[@]}-1; i++ )); do		#writes the field status into one string so only one echo is needed
		if [ ${field[$i]} == 0 ]; then		# draw empty field
			tempvar+=" "
		elif [ ${field[$i]} == 1 ]; then	# draw field border
			tempvar+="#"
		elif [ ${field[$i]} == 2 ]; then	# draw players
			tempvar+="N"
		elif [ ${field[$i]} == 3 ]; then	# draw ball
			tempvar+="@"
		else
			echo "ERROR at drawing i=\"$i\" with field[\$i]=\"${field[$i]}\" and #field[@]=\"${#field[@]}\", exiting"
			exit
		fi
	done
	clear
	echo -n "$tempvar"
	echo -ne "\rball=\"${ball[@]}\", d_ball=\"${d_ball[@]}\""
	sleep 0.1
}


function main {
	clear
	init_vars
	init_framebuffer

	while true; do
		game_loop
		render_framebuffer
		echo_framebuffer
		#exit
	done
}


main

