/obj/item/device/flashlight
	name = "flashlight"
	desc = "A hand-held emergency light."
	icon = 'icons/obj/items/lighting.dmi'
	icon_state = "flashlight"
	item_state = "flashlight"
	w_class = SIZE_SMALL
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_WAIST

	matter = list("metal" = 50,"glass" = 20)

	actions_types = list(/datum/action/item_action)
	var/on = 0
	var/brightness_on = 5 //luminosity when on
	var/raillight_compatible = 1 //Can this be turned into a rail light ?

/obj/item/device/flashlight/initialize()
	..()
	if(on)
		icon_state = "[initial(icon_state)]-on"
	else
		icon_state = initial(icon_state)

/obj/item/device/flashlight/Dispose()
	if(on)
		if(ismob(src.loc))
			src.loc.SetLuminosity(-brightness_on)
		else
			SetLuminosity(0)
	. = ..()


/obj/item/device/flashlight/proc/update_brightness(var/mob/user = null)
	if(on)
		icon_state = "[initial(icon_state)]-on"
		if(loc && loc == user)
			user.SetLuminosity(brightness_on)
		else if(isturf(loc))
			SetLuminosity(brightness_on)
	else
		icon_state = initial(icon_state)
		if(loc && loc == user)
			user.SetLuminosity(-brightness_on)
		else if(isturf(loc))
			SetLuminosity(0)

/obj/item/device/flashlight/attack_self(mob/user)
	if(!isturf(user.loc))
		to_chat(user, "You cannot turn the light on while in [user.loc].") //To prevent some lighting anomalities.
		return 0
	on = !on
	update_brightness(user)
	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()
	return 1

/obj/item/device/flashlight/proc/turn_off_light(mob/bearer)
	if(on)
		on = 0
		update_brightness(bearer)
		for(var/X in actions)
			var/datum/action/A = X
			A.update_button_icon()
		return 1
	return 0

/obj/item/device/flashlight/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I,/obj/item/tool/screwdriver))
		if(!raillight_compatible) //No fancy messages, just no
			return
		if(on)
			to_chat(user, SPAN_WARNING("Turn off [src] first."))
			return
		if(istype(loc, /obj/item/storage))
			var/obj/item/storage/S = loc
			S.remove_from_storage(src)
		if(loc == user)
			user.drop_inv_item_on_ground(src) //This part is important to make sure our light sources update, as it calls dropped()
		var/obj/item/attachable/flashlight/F = new(src.loc)
		user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
		to_chat(user, SPAN_NOTICE("You modify [src]. It can now be mounted on a weapon."))
		to_chat(user, SPAN_NOTICE("Use a screwdriver on [F] to change it back."))
		qdel(src) //Delete da old flashlight
		return
	else
		..()

/obj/item/device/flashlight/attack(mob/living/M as mob, mob/living/user as mob)
	add_fingerprint(user)
	if(on && user.zone_selected == "eyes")

		if(((CLUMSY in user.mutations) || user.getBrainLoss() >= 60) && prob(50))	//too dumb to use flashlight properly
			return ..()	//just hit them in the head

		if(!(istype(user, /mob/living/carbon/human) || ticker) && ticker.mode.name != "monkey")	//don't have dexterity
			to_chat(user, SPAN_NOTICE("You don't have the dexterity to do this!"))
			return

		var/mob/living/carbon/human/H = M	//mob has protective eyewear
		if(istype(M, /mob/living/carbon/human) && ((H.head && H.head.flags_inventory & COVEREYES) || (H.wear_mask && H.wear_mask.flags_inventory & COVEREYES) || (H.glasses && H.glasses.flags_inventory & COVEREYES)))
			to_chat(user, SPAN_NOTICE("You're going to need to remove that [(H.head && H.head.flags_inventory & COVEREYES) ? "helmet" : (H.wear_mask && H.wear_mask.flags_inventory & COVEREYES) ? "mask": "glasses"] first."))
			return

		if(M == user)	//they're using it on themselves
			M.flash_eyes()
			M.visible_message(SPAN_NOTICE("[M] directs [src] to \his eyes."), \
									 SPAN_NOTICE("You wave the light in front of your eyes! Trippy!"))
			return

		user.visible_message(SPAN_NOTICE("[user] directs [src] to [M]'s eyes."), \
							 SPAN_NOTICE("You direct [src] to [M]'s eyes."))

		if(istype(M, /mob/living/carbon/human))	//robots and aliens are unaffected
			if(M.stat == DEAD || M.sdisabilities & BLIND)	//mob is dead or fully blind
				to_chat(user, SPAN_NOTICE("[M] pupils does not react to the light!"))
			else if(XRAY in M.mutations)	//mob has X-RAY vision
				M.flash_eyes()
				to_chat(user, SPAN_NOTICE("[M] pupils give an eerie glow!"))
			else	//they're okay!
				M.flash_eyes()
				to_chat(user, SPAN_NOTICE("[M]'s pupils narrow."))
	else
		return ..()


/obj/item/device/flashlight/pickup(mob/user)
	if(on && src.loc != user)
		user.SetLuminosity(brightness_on)
		SetLuminosity(0)
	..()


/obj/item/device/flashlight/dropped(mob/user)
	if(on && src.loc != user)
		user.SetLuminosity(-brightness_on)
		SetLuminosity(brightness_on)
	..()
/obj/item/device/flashlight/on
	on = TRUE

/obj/item/device/flashlight/pen
	name = "penlight"
	desc = "A pen-sized light, used by medical staff."
	icon_state = "penlight"
	item_state = ""
	flags_atom = FPRINT|CONDUCT
	brightness_on = 2
	w_class = SIZE_TINY
	raillight_compatible = 0

/obj/item/device/flashlight/drone
	name = "low-power flashlight"
	desc = "A miniature lamp, that might be used by small robots."
	icon_state = "penlight"
	item_state = ""
	brightness_on = 2
	w_class = SIZE_TINY
	raillight_compatible = 0

//The desk lamps are a bit special
/obj/item/device/flashlight/lamp
	name = "desk lamp"
	desc = "A desk lamp with an adjustable mount."
	icon_state = "lamp"
	item_state = "lamp"
	brightness_on = 5
	w_class = SIZE_LARGE
	on = 1
	raillight_compatible = 0

//Menorah!
/obj/item/device/flashlight/lamp/menorah
	name = "Menorah"
	desc = "For celebrating Chanukah."
	icon_state = "menorah"
	item_state = "menorah"
	brightness_on = 2
	w_class = SIZE_LARGE
	on = 1

//Green-shaded desk lamp
/obj/item/device/flashlight/lamp/green
	desc = "A classic green-shaded desk lamp."
	icon_state = "lampgreen"
	item_state = "lampgreen"
	brightness_on = 5

/obj/item/device/flashlight/lamp/verb/toggle_light()
	set name = "Toggle light"
	set category = "Object"
	set src in oview(1)

	if(istype(usr, /mob/living/carbon/Xenomorph)) //Sneaky xenos turning off the lights
		attack_alien(usr)
		return

	if(!usr.stat)
		attack_self(usr)

// FLARES

/obj/item/device/flashlight/flare
	name = "flare"
	desc = "A red USCM issued flare. There are instructions on the side, it reads 'pull cord, make light'."
	w_class = SIZE_SMALL
	brightness_on = 5 //As bright as a flashlight, but more disposable. Doesn't burn forever though
	icon_state = "flare"
	item_state = "flare"
	actions = list()	//just pull it manually, neckbeard.
	raillight_compatible = 0
	var/fuel = 0
	var/on_damage = 7

/obj/item/device/flashlight/flare/New()
	fuel = rand(800, 1000) // Sorry for changing this so much but I keep under-estimating how long X number of ticks last in seconds.
	..()

/obj/item/device/flashlight/flare/Dispose()
	processing_objects -= src
	..()

/obj/item/device/flashlight/flare/process()
	fuel = max(fuel - 1, 0)
	if(!fuel || !on)
		turn_off()
		if(!fuel)
			icon_state = "[initial(icon_state)]-empty"
		processing_objects -= src

/obj/item/device/flashlight/flare/proc/turn_off()
	on = 0
	heat_source = 0
	force = initial(force)
	damtype = initial(damtype)
	if(ismob(loc))
		var/mob/U = loc
		update_brightness(U)
	else
		update_brightness(null)

/obj/item/device/flashlight/flare/attack_self(mob/user)

	// Usual checks
	if(!fuel)
		to_chat(user, SPAN_NOTICE("It's out of fuel."))
		return
	if(on)
		return

	. = ..()
	// All good, turn it on.
	if(.)
		user.visible_message(SPAN_NOTICE("[user] activates the flare."), SPAN_NOTICE("You pull the cord on the flare, activating it!"))
		playsound(src,'sound/handling/flare_activate_2.ogg', 50, 1) //cool guy sound
		force = on_damage
		heat_source = 1500
		damtype = "fire"
		processing_objects += src
		if(iscarbon(user))
			var/mob/living/carbon/U = user
			U.throw_mode_on()

/obj/item/device/flashlight/flare/on

	New()

		..()
		on = 1
		heat_source = 1500
		update_brightness()
		force = on_damage
		damtype = "fire"
		processing_objects += src

/obj/item/device/flashlight/slime
	gender = PLURAL
	name = "glowing slime"
	desc = "A glowing ball of what appears to be amber."
	icon = 'icons/obj/items/lighting.dmi'
	icon_state = "floor1" //not a slime extract sprite but... something close enough!
	item_state = "slime"
	w_class = SIZE_TINY
	brightness_on = 6
	on = 1 //Bio-luminesence has one setting, on.
	raillight_compatible = 0

/obj/item/device/flashlight/slime/New()
	SetLuminosity(brightness_on)
	spawn(1) //Might be sloppy, but seems to be necessary to prevent further runtimes and make these work as intended... don't judge me!
		update_brightness()
		icon_state = initial(icon_state)

/obj/item/device/flashlight/slime/attack_self(mob/user)
	return //Bio-luminescence does not toggle.

/******************************Lantern*******************************/

/obj/item/device/flashlight/lantern
	name = "lantern"
	icon_state = "lantern"
	desc = "A mining lantern."
	brightness_on = 6			// luminosity when on


//Signal Flare
/obj/item/device/flashlight/flare/signal
	name = "signal flare"
	desc = "A green USCM issued signal flare. The telemetry computer works on chemical reaction that releases smoke and light and thus works only while the flare is burning."
	icon_state = "cas_flare"
	item_state = "cas_flare"
	layer = ABOVE_FLY_LAYER
	var/faction = ""
	var/datum/cas_signal/signal

/obj/item/device/flashlight/flare/signal/New()
	..()
	fuel = rand(80, 100)


/obj/item/device/flashlight/flare/signal/attack_self(mob/user)

	// Usual checks
	if(!fuel)
		to_chat(user, SPAN_NOTICE("It's out of fuel."))
		return
	if(on)
		return

	if(!isturf(user.loc))
		to_chat(user, "You cannot turn the light on while in [user.loc].") //To prevent some lighting anomalities.
		return 0
	on = !on
	update_brightness(user)
	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()
	// All good, turn it on.
	user.visible_message(SPAN_NOTICE("[user] activates the flare."), SPAN_NOTICE("You pull the cord on the flare, activating it!"))
	force = on_damage
	heat_source = 1500
	damtype = "fire"
	processing_objects += src
	faction = user.faction
	activate_signal(user)


/obj/item/device/flashlight/flare/signal/proc/activate_signal(mob/user)
	set waitfor = 0
	sleep(50)
	if(faction && cas_groups[faction])
		var/target_id = rand(1,100000)
		signal = new(src)
		signal.name = name
		signal.target_id = target_id
		cas_groups[user.faction].add_signal(signal)
		anchored = TRUE
		visible_message(SPAN_DANGER("[src]'s flame reaches full strength. It's fully active now."), null, 5)

/obj/item/device/flashlight/flare/signal/attack_hand(mob/user)
	if (!user) return

	if(anchored)
		to_chat(user, "[src] is too hot. You will burn your hand if you pick it up.")
		return

	..()

/obj/item/device/flashlight/flare/signal/Dispose()
	if(signal)
		cas_groups[faction].remove_signal(signal)
		qdel(signal)
	..()

/obj/item/device/flashlight/flare/signal/turn_off()
	anchored = FALSE
	if(signal)
		cas_groups[faction].remove_signal(signal)
		qdel(signal)
	..()