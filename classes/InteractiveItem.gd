extends InteractiveZone

class_name InteractiveItem

@export
var item_id : Item.ItemIDs
@export_range(1,10)
var amount : int = 1

func _action() -> void:
	var item := Item.new(item_id,amount)
	var result : Player.CanAddItemResult = Player.current_player.can_add_item(item)
	if result == Player.CanAddItemResult.OK:
		Player.current_player.add_item(item)
		queue_free()
	elif result == Player.CanAddItemResult.FailedTooHeavy:
		Player.current_player.interaction_message("Too heavy...",false,true)
	else:
		Player.current_player.interaction_message("I don't have space",false,true)
