extends BallModEffect
class_name MiracleMod

func on_ball_lost(ball: CharacterBody2D) -> bool:
	ball.velocity = Vector2(ball.velocity.x, -absf(ball.velocity.y))
	ball._consume_mod("miracle")
	return true
