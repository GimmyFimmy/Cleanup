export type cleanup = {
	add: (self: cleanup, object: any, cleanup_method: string) -> cleanup & any,
	add_function: (self: cleanup, callback: (any) -> any) -> cleanup & any,
	add_instance: (self: cleanup, instance: Instance) -> cleanup & Instance,
	add_render: (self: cleanup, name: string, priority: number, callback: (any) -> any) -> cleanup & any,
	add_connection: (self: cleanup, connection: RBXScriptConnection, callback: (any) -> any) -> cleanup & RBXScriptConnection,
	add_task: (self: cleanup, task_to_cancel: any) -> cleanup & any,
	add_thread: (self: cleanup, thread: thread) -> cleanup & thread,
	add_class: (self: cleanup, class: any, ...any) -> cleanup & { any },
	attach: (self: cleanup, instance: Instance) -> cleanup & RBXScriptConnection,
	is_cleaning: (self: cleanup) -> boolean,
	clean: (self: cleanup, object: any) -> (),
	full_clean: (self: cleanup) -> (),
	destroy: (self: cleanup) -> ()
}

return { ... }