extends Control
class_name CalibrationMenu

signal calibration_finished

@onready var instruction_label: Label = $Panel/Margin/VBox/InstructionLabel
@onready var step_title: Label = $Panel/Margin/VBox/StepTitle
@onready var progress_bar: ProgressBar = $Panel/Margin/VBox/ProgressBar
@onready var landmark_canvas: Control = $Panel/Margin/VBox/CamFrame/LandmarkCanvas
@onready var skip_button: Button = $Panel/Margin/VBox/Buttons/SkipButton

enum CalibStep {
	DETECT_HAND,
	MOVE_CORNERS,
	MAKE_GESTURE,
	DONE
}

var current_step: CalibStep = CalibStep.DETECT_HAND
var _step_timer: float = 0.0
var _corners_visited: Dictionary = {"TL": false, "TR": false, "BL": false, "BR": false}

func _ready() -> void:
	update_step_ui()

func _process(delta: float) -> void:
	if landmark_canvas:
		landmark_canvas.queue_redraw()
	
	match current_step:
		CalibStep.DETECT_HAND:
			if HandInput.is_tracking or SettingsManager.control_mode == 2:
				_step_timer += delta
				progress_bar.value = (_step_timer / 1.0) * 100.0
				if _step_timer >= 1.0:
					advance_step(CalibStep.MOVE_CORNERS)
			else:
				_step_timer = maxf(0.0, _step_timer - delta)
				progress_bar.value = 0.0
				
		CalibStep.MOVE_CORNERS:
			var pos: Vector2 = HandInput.smoothed_hand_pos
			if pos.x < 0.4 and pos.y < 0.4: _corners_visited["TL"] = true
			if pos.x > 0.6 and pos.y < 0.4: _corners_visited["TR"] = true
			if pos.x < 0.4 and pos.y > 0.6: _corners_visited["BL"] = true
			if pos.x > 0.6 and pos.y > 0.6: _corners_visited["BR"] = true
			
			var count: int = 0
			for k in _corners_visited:
				if _corners_visited[k]: count += 1
			progress_bar.value = (float(count) / 4.0) * 100.0
			
			if count >= 3 or SettingsManager.control_mode == 2:
				advance_step(CalibStep.MAKE_GESTURE)
				
		CalibStep.MAKE_GESTURE:
			if HandInput.is_grabbing_gesture or (SettingsManager.control_mode == 2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
				_step_timer += delta
				progress_bar.value = (_step_timer / 0.5) * 100.0
				if _step_timer >= 0.5:
					advance_step(CalibStep.DONE)
					
		CalibStep.DONE:
			_step_timer += delta
			if _step_timer >= 1.2:
				finish_calibration()

func advance_step(next_step: CalibStep) -> void:
	current_step = next_step
	_step_timer = 0.0
	progress_bar.value = 0.0
	update_step_ui()

func update_step_ui() -> void:
	match current_step:
		CalibStep.DETECT_HAND:
			step_title.text = "Step 1 of 3: Hand Detection"
			instruction_label.text = "Raise your hand in front of the camera.\nKeep your fingers open and palm visible."
		CalibStep.MOVE_CORNERS:
			step_title.text = "Step 2 of 3: Range of Motion"
			instruction_label.text = "Move your hand around the frame towards the corners to calibrate full claw reach."
		CalibStep.MAKE_GESTURE:
			step_title.text = "Step 3 of 3: Grab Gesture"
			instruction_label.text = "Pinch your thumb and index finger together, or close your fist, to test claw grab."
		CalibStep.DONE:
			step_title.text = "★ Calibration Complete! ★"
			instruction_label.text = "Your hand tracking is calibrated and ready. Starting game..."
			progress_bar.value = 100.0

func _on_skip_pressed() -> void:
	finish_calibration()

func finish_calibration() -> void:
	calibration_finished.emit()
	visible = false
