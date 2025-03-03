extends Command
class_name DashCommand

func execute(actor):
	actor.dash.handle_dash(actor, 0)  # Pass delta if needed
