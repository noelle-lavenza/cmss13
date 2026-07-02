//Separate dm because it relates to two types of atoms + ease of removal in case it's needed.
//Also assemblies.dm for falsewall checking for this when used.
//I should really make the shuttle wall check run every time it's moved, but centcom uses unsimulated floors so !effort

/atom
	var/datum/smoothing_profile/smoothing_profile

/datum/smoothing_profile
	///A list of paths that our atom should tile with, turned into a typecache on creation
	var/list/tiles_with
	///A list of paths that our atom should tile with in a special manner (type-dependent), turned into a typecache on creation
	var/list/tiles_special
	///A list of turfs types that our atom should blend with, turned into a typecache on creation
	var/list/blend_turfs
	///A list of turfs types that our atom should not blend with, turned into a typecache on creation
	var/list/noblend_turfs
	///A list of object types that our atom should blend with, turned into a typecache on creation
	var/list/blend_objects
	///A list of object types that our atom should not blend with, turned into a typecache on creation
	var/list/noblend_objects

/datum/smoothing_profile/New()
	. = ..()
	tiles_with = typecacheof(tiles_with)
	if(tiles_special)
		tiles_special = typecacheof(tiles_special)
	if(blend_turfs)
		blend_turfs = typecacheof(blend_turfs)
	if(noblend_turfs)
		noblend_turfs = typecacheof(noblend_turfs)
	if(blend_objects)
		blend_objects = typecacheof(blend_objects)
	if(noblend_objects)
		noblend_objects = typecacheof(noblend_objects)

/// A cached lookup from typepath -> created smoothing profile
GLOBAL_ALIST_EMPTY(smoothing_profiles)

/atom/proc/relativewall() //atom because it should be useable both for walls, false walls, doors, windows, etc
	var/junction = 0 //flag used for icon_state
	var/turf/T //The turf we are checking
	var/atom/movable/k //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)
	var/list/tiles_with = smoothing_profile.tiles_with

	for(var/dir_to_check in GLOB.cardinals) //For all cardinal dir turfs
		T = get_step(src, dir_to_check)
		if(!istype(T))
			continue
		if(is_type_in_typecache(T, tiles_with))
			junction |= dir_to_check
			continue // we've already added this dir to junction
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				junction |= dir_to_check

	handle_icon_junction(junction)

/atom/proc/relativewall_neighbours()
	var/turf/checking_turf //The turf we are checking
	var/atom/movable/contained //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)
	var/list/tiles_with = smoothing_profile.tiles_with

	for(var/dir_to_check in GLOB.cardinals) //For all cardinal dir turfs
		checking_turf = get_step(src, dir_to_check)
		if(!istype(checking_turf))
			continue
		if(is_type_in_typecache(checking_turf, tiles_with))
			checking_turf.relativewall() //If we tile this type, junction it
		for(contained in checking_turf)
			if(is_type_in_typecache(contained, tiles_with))
				contained.relativewall() //get_dir to i, since k is something inside the turf T

/atom/proc/handle_icon_junction(junction)
	return

//Windows are weird. The walls technically tile with them, but they don't tile back. At least, not really.
//They require more states or something to that effect, but this is a workaround to use what we have.
//I could introduce flags here, but I feel like the faster the better. In this case an override with copy and pasted code is fine for now.
/obj/structure/window/framed/relativewall()
	var/jun_1 = 0 //Junction 1.
	var/jun_2 = 0 //Junction 2.
	var/turf/T
	var/atom/movable/k
	var/list/tiles_with = smoothing_profile.tiles_with
	var/list/tiles_special = smoothing_profile.tiles_special

	for(var/dir_to_check in GLOB.cardinals)
		T = get_step(src, dir_to_check)
		if(!istype(T))
			continue
		if(is_type_in_typecache(T, tiles_with))
			jun_1 |= dir_to_check

		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				jun_1 |= dir_to_check
			if(is_type_in_typecache(k, tiles_special))
				jun_2 |= dir_to_check

	handle_icon_junction(jun_1, jun_2)

//Windows are weird. The walls technically tile with them, but they don't tile back. At least, not really.
//They require more states or something to that effect, but this is a workaround to use what we have.
//I could introduce flags here, but I feel like the faster the better. In this case an override with copy and pasted code is fine for now.
/obj/structure/window_frame/relativewall()
	var/jun_1 = 0 //Junction 1.
	var/jun_2 = 0 //Junction 2.
	var/turf/T
	var/i
	var/k
	var/list/tiles_with = smoothing_profile.tiles_with
	var/list/tiles_special = smoothing_profile.tiles_special

	for(i in GLOB.cardinals)
		T = get_step(src, i)
		if(!istype(T))
			continue
		if(is_type_in_typecache(T, tiles_with))
			jun_1 |= i
			// don't break, have to check jun_2

		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				jun_1 |= i
			if(is_type_in_typecache(k, tiles_special))
				jun_2 |= i

	handle_icon_junction(jun_1, jun_2)

// Special case for smoothing walls around multi-tile doors.
/obj/structure/machinery/door/airlock/multi_tile/relativewall_neighbours()
	var/turf/T //The turf we are checking
	var/atom/movable/k
	var/list/tiles_with = smoothing_profile.tiles_with

	if (dir == SOUTH)
		T = locate(x, y+2, z)
		if(is_type_in_typecache(T, tiles_with))
			T.relativewall()
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				k.relativewall()

		T = get_step(src, SOUTH)
		if(is_type_in_typecache(T, tiles_with))
			T.relativewall()
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				k.relativewall()

	else if (dir == EAST)
		T = locate(x+2, y, z)
		if(is_type_in_typecache(T, tiles_with))
			T.relativewall()
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				k.relativewall()

		T = get_step(src, WEST)
		if(is_type_in_typecache(T, tiles_with))
			T.relativewall()
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				k.relativewall()

// Not proud of this.
/obj/structure/mineral_door/resin/handle_icon_junction(junction)
	if(junction & (SOUTH|NORTH))
		setDir(WEST)
	else if(junction & (EAST|WEST))
		setDir(NORTH)

/obj/structure/window/framed/handle_icon_junction(jun_1, jun_2)
	if(!icon_exists(icon, "[basestate][jun_2 ? jun_2 : jun_1]")) //Missing states for 5, 6, 7, 9, 10, 11, 13, 14, 15 for the vast majority of /obj/structure/window/framed
		icon_state = "[basestate]0"
		junction = 0
		return

	icon_state = "[basestate][jun_2 ? jun_2 : jun_1]" //Use junction 2 if possible, junction 1 otherwise.
	if(jun_2)
		junction = jun_2
	else
		junction = jun_1

/obj/structure/window_frame/handle_icon_junction(jun_1, jun_2)
	if(!icon_exists(icon, "[basestate][jun_2 ? jun_2 : jun_1]_frame")) //Missing states for 5, 6, 7, 9, 10, 11, 13, 14, 15 for the vast majority of /obj/structure/window_frame
		icon_state = "[basestate]0_frame"
		junction = 0
		return

	icon_state = "[basestate][jun_2 ? jun_2 : jun_1]_frame" //Use junction 2 if possible, junction 1 otherwise.
	if(jun_2)
		junction = jun_2
	else
		junction = jun_1



/turf/closed/wall/handle_icon_junction(junction)
	icon_state = "[walltype][junction]"
	junctiontype = junction

/obj/structure/grille/almayer/handle_icon_junction(junction)
	icon_state = "grille[junction]"


/turf/open/floor/vault/relativewall()
	return

// we use a different wall smoothing system now
/turf/closed/wall/relativewall()
	return

/turf/closed/shuttle/relativewall()
	//TODO: Make something for this and make it work with shuttle rotations
	return

/turf/open/shuttle/relativewall()
	return

/turf/closed/wall/indestructible/relativewall()
	return


/turf/open/asphalt/cement/relativewall()
	var/junction = 0 //flag used for icon_state
	var/i //iterator
	var/turf/T //The turf we are checking
	var/atom/movable/k //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)
	var/list/tiles_with = smoothing_profile.tiles_with

	for(i in GLOB.alldirs) //For all dir turfs
		T = get_step(src, i)
		if(!istype(T))
			continue
		if(is_type_in_typecache(T, tiles_with))
			junction |= i
			break
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				junction |= i
				break

	handle_icon_junction(junction)

/turf/open/asphalt/cement_sunbleached/relativewall()
	var/junction = 0 //flag used for icon_state
	var/i //iterator
	var/turf/T //The turf we are checking
	var/atom/movable/k //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)
	var/list/tiles_with = smoothing_profile.tiles_with

	for(i in GLOB.alldirs) //For all dir turfs
		T = get_step(src, i)
		if(!istype(T))
			continue
		if(is_type_in_typecache(T, tiles_with))
			junction |= i
			break
		for(k in T)
			if(is_type_in_typecache(k, tiles_with))
				junction |= i
				break

	handle_icon_junction(junction)

// Smoothing presets
/datum/smoothing_profile/all_with_wall
	tiles_with = list(
		/turf/closed/wall,
		/obj/structure/window/framed,
		/obj/structure/window_frame,
		/obj/structure/girder,
		/obj/structure/machinery/door,
	)
	blend_turfs = list(/turf/closed/wall)
	noblend_turfs = list(/turf/closed/wall/mineral, /turf/closed/wall/almayer/research/containment)
	blend_objects = list(/obj/structure/machinery/door, /obj/structure/window_frame, /obj/structure/window/framed)
	noblend_objects = list(/obj/structure/machinery/door/window)

/datum/smoothing_profile/almayer_airlock_windows
	tiles_with = list(
		/obj/structure/window/framed/almayer,
		/obj/structure/machinery/door/airlock,
	)

/datum/smoothing_profile/almayer_airlock_windows_hull
	tiles_with = list(
		/obj/structure/window/framed/almayer,
		/obj/structure/machinery/door/airlock,
		/turf/closed/wall/almayer,
	)

/datum/smoothing_profile/almayer_airlock_windows_allwall
	tiles_with = list(
		/obj/structure/window/framed/almayer,
		/obj/structure/machinery/door/airlock,
		/turf/closed/wall,
	)

/datum/smoothing_profile/all_with_wall/almayer
	tiles_with = list(
		/turf/closed/wall,
		/obj/structure/window/framed,
		/obj/structure/window_frame,
		/obj/structure/girder,
		/obj/structure/machinery/door,
		/obj/structure/machinery/cm_vending/sorted/attachments/blend,
		/obj/structure/machinery/cm_vending/sorted/cargo_ammo/cargo/blend,
		/obj/structure/machinery/cm_vending/sorted/cargo_guns/cargo/blend,
	)

/datum/smoothing_profile/strata_airlock_windows
	tiles_with = list(
		/obj/structure/window/framed/strata,
		/obj/structure/machinery/door/airlock,
	)

/datum/smoothing_profile/prison_airlock_windows
	tiles_with = list(
		/obj/structure/window/framed/prison,
		/obj/structure/machinery/door/airlock,
	)

/datum/smoothing_profile/upp_ship_airlock_windows_hull
	tiles_with = list(
		/obj/structure/window/framed/upp_ship,
		/obj/structure/machinery/door/airlock,
		/turf/closed/wall/upp_ship,
	)

/datum/smoothing_profile/all_with_wall/upp_ship
	tiles_with = list(
		/turf/closed/wall,
		/obj/structure/window/framed,
		/obj/structure/window_frame,
		/obj/structure/girder,
		/obj/structure/machinery/door,
		/obj/structure/machinery/cm_vending/sorted/attachments/upp_attachments/blend,
		/obj/structure/machinery/cm_vending/sorted/cargo_ammo/upp_cargo_ammo/blend,
		/obj/structure/machinery/cm_vending/sorted/cargo_guns/upp_cargo_guns/blend,
	)

/datum/smoothing_profile/mineral_wall
	tiles_with = list(/turf/closed/wall/mineral)

/datum/smoothing_profile/mineral_wall_and_wood
	tiles_with = list(/turf/closed/wall/mineral, /turf/closed/wall/wood)

/datum/smoothing_profile/just_wall
	tiles_with = list(/turf/closed/wall)

/datum/smoothing_profile/just_wall/window_special
	tiles_special = list(
		/obj/structure/machinery/door/airlock,
		/obj/structure/window/framed,
		/obj/structure/girder,
		/obj/structure/window_frame
	)

/datum/smoothing_profile/all_but_door
	tiles_with = list(
		/turf/closed/wall,
		/obj/structure/window/framed,
		/obj/structure/window_frame,
		/obj/structure/girder
	)
