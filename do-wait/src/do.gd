class_name Do


static func wait(wait_time_sec: float) -> Callable:
	var timer = NonTreeTimer.new(wait_time_sec)
	return func timerStart() -> void:
		timer.start()
		await timer.timeout
		print("timeout")


static func tree_wait(node: Node, wait_time_sec: float) -> Callable:
	return func tree_timer_start() -> void:
		await node.get_tree().create_timer(wait_time_sec).timeout
		print("tree timeout")


static func do(what: Array[Callable]) -> _Do:
	var d := _Do.new()
	d.actions(what)
	return d


class _Do:
	
	signal done
	signal cycle
	var _actions: Array[Callable]
	
	func execute(times := 1) -> void:
		prints("-----", _actions, times)
		for time in times:
			for fn in _actions:
				await _run(fn)
			cycle.emit()
		done.emit()
	
	func actions(new_actions: Array[Callable]) -> void:
		_actions = new_actions
	
	func _run(fn: Callable) -> void:
		print("running %s" % [fn])
		await fn.call()
		print("fn done")


class NonTreeTimer:
	
	signal timeout()
	var wait_time := 0.5;
	var _thread: Thread

	func _init(initial_wait_time := 0.5):
		wait_time = initial_wait_time

	func start():
		_thread = Thread.new()
		_thread.start(_start)
		
	
	func destroy() -> void:
		_thread.wait_to_finish()
		timeout.emit()
	
	
	func _start() -> void:
		var start_time := Time.get_ticks_msec()
		var wait_time_ms := wait_time * 1000.0
		while true:
			var current_time = Time.get_ticks_msec()
			if current_time - start_time >= wait_time_ms:
				call_deferred("destroy")
				break
