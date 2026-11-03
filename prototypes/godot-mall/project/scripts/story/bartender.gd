## The Cuco's bartender (workstream CUCOS, Nov 3 2026; design/godot-cucos.md): a counter attendant
## (scripts/attendants/attendant.gd: behind the bar, wanders a little, faces the player) whose
## action is the shop, except when the player holds the coupon:
##  - holding cu_coupon: data/story/cucos/bartender.dialogue (Steven's coupon lines; the coupon is
##    used up, the top-shelf margarita and, once, the doubloon are given);
##  - otherwise: mall.shop.open(<entry.shop>) (workstream SHOPS); until SHOPS lands, the stub
##    scripts/story/shop_stub.gd runs the same data/story/shops.json entry as a conversation.
extends "res://scripts/attendants/attendant.gd"

const ShopStub = preload("res://scripts/story/shop_stub.gd")

func interact(p: Node) -> void:
	var m = p.get("mall") if p else null
	if m and str(m.held_id()) == "cu_coupon" and story and dialogue != "":
		story.talk(self, dialogue)
		return
	open_shop(p)

## SHOPS's mall.shop.open(id) when it exists, else the stub.
func open_shop(p: Node) -> void:
	var id := str(entry.get("shop", ""))
	if id == "":
		return
	var m = p.get("mall") if p else null
	if m and "shop" in m and m.shop != null and m.shop.has_method("open"):
		m.shop.open(id)
		return
	ShopStub.open(story, self, id)
