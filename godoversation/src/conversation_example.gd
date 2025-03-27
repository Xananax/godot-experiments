extends Conversation

signal open_merchant_inventory

var merchant := Actor.Make("merchant", preload("./merchant.png"))
var wolf := Actor.Make("wolf", preload("./wolf.png"))

func start_merchant() -> void:
	actor(merchant)
	say("hello, what do you want to buy?")
	say("I've got weares if you have the coin")
	if visits(start_wolf) > 1:
		say("I see you met the worlf, I'll make you a price")
		merchant.set_meta("special_price", true)
	say("do you want to talk, or buy?")
	choice("buy", see_merchant_wares)
	choice("talk a bit", merchant_talk)


func merchant_talk() -> void:
	actor(merchant)
	if has_visited(merchant_talk):
		say("Talk again, eh?")
	if visits(start_wolf) > 10:
		say("I see you've met the wolf a lot of times!")
	elif visits(start_wolf) > 0:
		say("I see you've met the wolf")
	else:
		say("you really should meet the wolf")


func see_merchant_wares() -> void:
	actor(merchant)
	say("I got the good stuff")
	var open_inv_choice := Conversation.Choice.new()
	open_inv_choice.text = "Open merchant inventory"
	open_inv_choice.was_picked.connect(func() -> void:
		open_merchant_inventory.emit()
	)
	add_choice(open_inv_choice)
	leave_choice()


func start_wolf():
	actor(wolf)
	say("woof")
	leave_choice()
