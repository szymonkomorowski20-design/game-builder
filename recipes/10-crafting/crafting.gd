class_name Crafting
extends RefCounted
## Recipe-based crafting on top of Inventory (recipe 09). A recipe: inputs {id: count} → output id × count.
## Crafting is atomic: inputs are only consumed if the output fits.

## recipes: Array of {"id": StringName, "inputs": {id: count}, "output": StringName, "amount": int}
static func can_craft(inv: Inventory, recipe: Dictionary) -> bool:
	for id in recipe.inputs:
		if inv.count_of(id) < int(recipe.inputs[id]):
			return false
	return true


static func craft(inv: Inventory, recipe: Dictionary) -> bool:
	if not can_craft(inv, recipe):
		return false
	# Take inputs, try to add output; roll back if it does not fit.
	for id in recipe.inputs:
		inv.remove(id, int(recipe.inputs[id]))
	var left := inv.add(recipe.output, int(recipe.get("amount", 1)))
	if left > 0:
		inv.remove(recipe.output, int(recipe.get("amount", 1)) - left)
		for id in recipe.inputs:
			inv.add(id, int(recipe.inputs[id]))
		return false
	return true
