#!/bin/bash

declare tempvar
declare -i newgame			# bool(0/1)
declare -a maxfieldsize		# maxfieldsize[0] = Y pos, maxfieldsize[1] = X pos
declare -a ball				# ball[0] = Y pos, ball[1] = X pos
declare -a d_ball			# movement. d_ball[0] = deltaY, d_ball[1] = deltaX
declare -a field 			# status of every single field
declare -i ball_field		# ball field in field array
declare -i player1			# player1 = Y pos, X pos = 2
declare -i player2			# player2 = Y pos , X pos = (maxfieldsize[1] - 1)
declare -i activefield		# index for active field
declare -i playersize		# size of players.
declare -i framecount		# frame counter

framecount=0
newgame=1
maxfieldsize=(`stty size`)

playersize=${maxfieldsize[0]}
let "playersize/=10"	 	# 10th of Y-maxplayfieldsize
#echo "playersize = $playersize"

# sets whole field array as empty
for (( i=0; i<=${maxfieldsize[0]}*${maxfieldsize[1]} - 1; i++ )); do
	field[$i]=0
done
#echo "ERROR at drawing i = \"$i\" with field[\$i]=${field[$i]} and #field[@]=${#field[@]}, exiting"



function game_loop	# calculates ball and player movement
{
	if (( ${ball[1]} <= 2 )) || (( ${ball[1]} >= ${maxfieldsize[1]} - 2 )); then				# game over cond
		calculate_ball_vector "1"
	elif (( ${ball[0]} <= 2 )) || (( ${ball[0]} >= ${maxfieldsize[0]} - 2 )); then				# ball border bounce
		calculate_ball_vector "0"
	elif [ ${field[ (($ball_field-1)) ]} == 3 ] || [ ${field[ (($ball_field+1)) ]} == 3 ]; then	# player collision cond
		echo "PLAYER COLLISION ball = ${ball[@]}, player1=$player1, player2=$player2"
		exit
	fi

	tempvar=$(( (${ball[0]} - 1) * ${maxfieldsize[1]} + ${ball[1]} ))	# sets former ball field to empty
	field[$tempvar]=0

	ball[0]=$(( ${ball[0]} + ${d_ball[0]} )) # ball movement
	ball[1]=$(( ${ball[1]} + ${d_ball[1]} ))

	if (( ${ball[0]} <= 1 )); then			# ball border check, so it cant cross borders or change border fields (no re-init)
		#let "ball[0] += 1"
		ball[0]=2
	elif (( ${ball[0]} >= ${maxfieldsize[0]}-1 )); then
		#let "ball[0] -= 1"
		ball[0]=$(( ${maxfieldsize[0]} - 1 ))
	fi
	if (( ${ball[1]} <= 2 )); then
		#let "ball[1] += 1"
		ball[1]=3
	elif (( ${ball[1]} >= ${maxfieldsize[1]}-2 )); then
		#let "ball[1] -= 1"
		ball[1]=$(( ${maxfieldsize[1]} - 3 ))
	fi

	#if (( framecount % 2 == 0 )); then		# player movement
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
	#fi
}


function calculate_ball_vector # calculates impact and outbound angle. 0=border bounce, 1=player bounce.
{
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


function render_framebuffer # writes the calculated coords to field[]
{

	tempvar=$(( (${ball[0]} - 1) * ${maxfieldsize[1]} + ${ball[1]} ))	# calculates Xth field[] in array from X/Y ball-coordg
	field[$tempvar]=3	#sets ball
	ball_field=$tempvar

	for (( i=2; i<=${maxfieldsize[0]}-1; i++ )); do		# empties the player column so players move and dont expand
		tempvar=$(( ($i - 1) * ${maxfieldsize[1]} + 2 ))
		field[$tempvar]=0	#empties left column

		tempvar=$(( $i * ${maxfieldsize[1]} - 2 ))
		field[$tempvar]=0	#empties right column
	done

	for (( i=playersize; i>=0; i-- )); do					# sets the player bodies in field[] according to player coords
		tempvar=$(( ($player1 - $i) * ${maxfieldsize[1]} + 2 ))		# calculates player 1 fields
		field[$tempvar]=2	#sets player1 UPPER end
		tempvar=$(( ($player1 + $i) * ${maxfieldsize[1]} + 2 ))		# calculates player 1 fields
		field[$tempvar]=2	#sets player1 LOWER end

		tempvar=$(( ($player2 - $i) * ${maxfieldsize[1]} - 2 ))		# calculates player 2 fields
		field[$tempvar]=2	#sets player2 UPPER end
		tempvar=$(( ($player2 + $i) * ${maxfieldsize[1]} - 2 ))		# calculates player 2 fields
		field[$tempvar]=2	#sets player2 LOWER end
	done
}


function init_framebuffer {	# initilizes all fields and coords to start

	for (( i=0; i<=${maxfieldsize[0]}*${maxfieldsize[1]}-1; i++ )); do

		if (( $i <= ${maxfieldsize[1]} - 1 )) || (( $i >= ${#field[@]} - ${maxfieldsize[1]} - 1 )) || # cond for horizontal borders
		(( $i % ${maxfieldsize[1]} == 0 )) || (( $i % ${maxfieldsize[1]} == ${maxfieldsize[1]} - 1 )) # cond for vertical borders
		then
			field[$i]=1		# sets field border
		fi
	done

	if (( $newgame == 1 )); then
		if (( $RANDOM % 2 == 0 )); then	# sets ball start impulse
			d_ball[0]=$(( $RANDOM % 4 + 1))
		else
			d_ball[0]=-$(( $RANDOM % 4 + 1))
		fi
		if (( $RANDOM % 2 == 0 )); then
			d_ball[1]=$(( $RANDOM % 2 + 1))
		else
			d_ball[1]=-$(( $RANDOM % 2 + 1))
		fi

		ball[0]=${maxfieldsize[0]}	# set ball Y in middle
		let "ball[0]/=2"

		ball[1]=${maxfieldsize[1]}	# set ball X in middle
		let "ball[1]/=2"

		player1=${maxfieldsize[0]}	# set player1 in middle
		let "player1/=2"

		player2=${maxfieldsize[0]}	# set player2 in middle
		let "player2/=2"

		newgame=0
	fi
}


function echo_framebuffer {	# summs up all the field[]s in one string and echos it
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
	framecount+=1
	clear
	echo -n "$tempvar"
	echo -ne "\rball=\"${ball[@]}\", d_ball=\"${d_ball[@]}\""
	sleep 0.1
}

#echo "1 --- ${#field[@]}"
init_framebuffer
#echo "2 --- ${#field[@]}"
#f_set_fields
#echo "3 --- ${#field[@]} --- ${field[@]}"
#f_draw_screen

while true; do
	game_loop
	render_framebuffer
	echo_framebuffer
done

#echo "${#field[@]} --- \"${field[1860]}\""
