GLOBAL_DATUM_INIT(openspace_backdrop_one_for_all, /atom/movable/openspace_backdrop, new)

/atom/movable/openspace_backdrop
	name = "openspace_backdrop"
	anchored = TRUE
	icon = 'icons/turf/floors/floors.dmi'
	icon_state = "grey"
	plane = OPENSPACE_BACKDROP_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/turf/open_space
	is_weedable = NOT_WEEDABLE
	name = "open space"
	icon_state = "transparent"
	baseturfs = /turf/open_space
	plane = OPEN_SPACE_PLANE_START
	is_weedable = NOT_WEEDABLE

// Most of this is copied from the parent call to avoid proc-call overhead.
// On large maps we have so many of these it's actually worth worrying about,
// unlike on TG.
/turf/open_space/Initialize()
	SHOULD_CALL_PARENT(FALSE) // this doesn't parent call for optimisation reasons
	if(flags_atom & INITIALIZED)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_atom |= INITIALIZED

	// by default, vis_contents is inherited from the turf that was here before
	vis_contents.Cut()

	GLOB.turfs += src

	assemble_baseturfs()

	levelupdate()

	var/turf/above = SSmapping.get_turf_above(src)
	var/turf/below = SSmapping.get_turf_below(src)

	if(above)
		above.multiz_new(dir=DOWN)

	if(below)
		below.multiz_new(dir=UP)

	pass_flags = GLOB.pass_flags_cache[type]
	if (isnull(pass_flags))
		pass_flags = new()
		initialize_pass_flags(pass_flags)
		GLOB.pass_flags_cache[type] = pass_flags
	else
		initialize_pass_flags()

	for(var/atom/movable/AM in src)
		Entered(AM)

	RegisterSignal(src, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(on_atom_created))

	ADD_TRAIT(src, TURF_Z_TRANSPARENT_TRAIT, TRAIT_SOURCE_INHERENT)
	return INITIALIZE_HINT_LATELOAD

// Make things that were created on our turf fall down, since they don't call Entered
/turf/open_space/proc/on_atom_created(atom/created_atom)
	SIGNAL_HANDLER
	if(ismovable(created_atom))
		check_fall(created_atom)

/turf/open_space/attack_alien(mob/user)
	attack_hand(user)

/turf/open_space/attack_hand(mob/user)
	climb_down(user)

/turf/open_space/Entered(atom/movable/entered_movable, atom/old_loc)
	. = ..()
	check_fall(entered_movable)

/turf/open_space/on_throw_end(atom/movable/thrown_atom)
	check_fall(thrown_atom)

/turf/open_space/proc/climb_down(mob/user)
	if(user.action_busy)
		return

	var/turf/current_turf = get_turf(src)

	if(!istype(current_turf, /turf/open_space))
		return

	var/climb_down_time = 1 SECONDS

	if(ishuman_strict(user))
		climb_down_time = 2.5 SECONDS

	if(isxeno(user))
		var/mob/living/carbon/xenomorph/xeno_victim = user
		if(xeno_victim.mob_size >= MOB_SIZE_BIG)
			climb_down_time = 3 SECONDS
		else
			climb_down_time = 1 SECONDS

	if(user.action_busy)
		return
	user.visible_message(SPAN_WARNING("[user] starts climbing down."), SPAN_WARNING("You start climbing down."))

	if(!do_after(user, climb_down_time, INTERRUPT_ALL, BUSY_ICON_CLIMBING))
		to_chat(user, SPAN_WARNING("You were interrupted!"))
		return

	user.visible_message(SPAN_WARNING("[user] climbs down."), SPAN_WARNING("You climb down."))

	var/turf/below = SSmapping.get_turf_below(current_turf)
	while(istype(below, /turf/open_space))
		below = SSmapping.get_turf_below(below)

	user.forceMove(below)
	return

/turf/open_space/proc/check_fall(atom/movable/movable)
	if(movable.flags_atom & NO_ZFALL)
		return

	var/height = 1
	var/turf/below = SSmapping.get_turf_below(get_turf(src))

	while(istype(below, /turf/open_space))
		below = SSmapping.get_turf_below(below)
		height++

	movable.forceMove(below)
	movable.onZImpact(below, height)

// this is purely visual with none of the interaction mechanics
/turf/solid_open_space
	name = "open space"
	icon_state = "transparent_solid"
	baseturfs = /turf/solid_open_space
	plane = OPEN_SPACE_PLANE_START
	is_weedable = NOT_WEEDABLE
	density = TRUE

/turf/solid_open_space/Initialize()
	SHOULD_CALL_PARENT(FALSE) // this doesn't parent call for optimisation reasons
	if(flags_atom & INITIALIZED)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_atom |= INITIALIZED
	ADD_TRAIT(src, TURF_Z_TRANSPARENT_TRAIT, TRAIT_SOURCE_INHERENT)
	icon_state = "transparent"
	return INITIALIZE_HINT_LATELOAD
