extends Node

## Signal: enemy_killed
## Emitted when an enemy is killed.
signal event_enemy_killed(enemy)

##signal: enemy_despawn
## Emitted when an enemy is despawned.
signal event_enemy_despawn(enemy)

## Signal: player_damaged
## Emitted when the player is damaged.
signal event_player_damaged(amount)

## Signal: weapon_equipped
## Emitted when a weapon is equipped.
signal event_weapon_equipped(weapon_id)

## Signal: arena_start
## Emitted when an arena event starts.
## Parameter:
##   position: The starting position as a Vector3.
signal event_arena_start(position)

## Signal: arena_end
## Emitted when an arena event ends.
signal event_arena_end

## Signal: powerup_collected
## Emitted when a power-up is collected.
## Parameter:
##   powerup_data: The collected power-up data.
signal event_powerup_collected(powerup_data)

## Signal: show_dialogue
## Emitted when dialogue should be displayed.
## Parameter:
##   dialogue_id: The identifier for the dialogue.
signal event_show_dialogue(dialogue_id)

## Signal: hide_dialogue
## Emitted when dialogue should be hidden.
signal event_hide_dialogue

## Signal: event_fired
## A generic signal for firing custom events.
## Parameters:
##   event_name (String): The name of the event.
##   data (Variant): Optional event data.
signal event_event_fired(event_name, data)

## Function: _on_connect_once_callback
## Purpose: Handles a one-time signal callback, calls the target method,
##          and then disconnects itself.
## Parameters:
##   target (Object): The target object whose method is to be invoked.
##   method (String): The method to call on the target.
##   signal_name (String): The signal from which to disconnect.
##   arg (Variant): The argument passed by the signal.
func _on_connect_once_callback(arg, target: Object, method: String, signal_name: String):
	# 'arg' is the signal parameter (e.g. a Vector3). The rest of the parameters come from binding.
	target.callv(method, [arg])
	# Disconnect this callback from the signal.
	disconnect(signal_name, Callable(self, "_on_connect_once_callback").bind(target, method, signal_name))

## Function: connect_once
## Purpose: Connects to a signal with a callback that automatically disconnects
##          after the first firing.
## Parameters:
##   signal_name (String): The signal to connect.
##   target (Object): The target object whose method should be called.
##   method (String): The method to call on the target.
func connect_once(signal_name: String, target: Object, method: String):
	var callable_once = Callable(self, "_on_connect_once_callback").bind(target, method, signal_name)
	connect(signal_name, callable_once)

## Function: subscribe_to_event
## Purpose: Connects a target's method to a generic event signal.
## Parameters:
##   event_name (String): The event signal name.
##   target (Object): The target object to connect.
##   method (String): The target's method to invoke when the event fires.
func subscribe_to_event(event_name: String, target: Object, method: String):
	connect(event_name, Callable(target, method))

## Function: unsubscribe_from_event
## Purpose: Disconnects a previously connected target's method from an event signal.
## Parameters:
##   event_name (String): The event signal name.
##   target (Object): The target object to disconnect.
##   method (String): The target's method that was connected.
func unsubscribe_from_event(event_name: String, target: Object, method: String):
	disconnect(event_name, Callable(target, method))

## Function: emit_event
## Purpose: Emits a generic event signal with optional data.
## Parameters:
##   event_name (String): The name of the event to emit.
##   data (Variant): Optional data to include with the event (defaults to null).
func emit_event(event_name: String, data = null):
	emit_signal(event_name, data)
