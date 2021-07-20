extends Control


func _input(event):
	if event is InputEventScreenTouch:
		
		if event.is_pressed():
		
			var nearlyChild
			var distanceToNearlyChild = INF
			
			# ищем ближайшего ребёнка
			for child in get_children():
				var distanceToChild = event.position.distance_to(child.rect_position)
				if distanceToChild < distanceToNearlyChild:
					distanceToNearlyChild = distanceToChild
					nearlyChild = child
			
			if nearlyChild.is_in_group("joystick"):
				nearlyChild.update_output(event.position)
				nearlyChild.set_active(event.index)
			
		else:
			
			for child in get_children():
				if child.is_in_group("joystick"):
					if child.touchIndex == event.index:
						child.set_unactive()
