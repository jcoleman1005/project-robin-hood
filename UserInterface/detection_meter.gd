extends ProgressBar

# This function is called by the Guard to update the meter's fill amount.
# It expects a value between 0.0 (empty) and 1.0 (full).
func update_progress(progress: float):
	# Set the value of the progress bar.
	value = progress
	
	# If the meter is empty, hide it. Otherwise, show it.
	if progress <= 0:
		hide()
	else:
		show()
