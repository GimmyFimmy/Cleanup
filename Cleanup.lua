--[=[

    cleanup_util:
     - advanced util to track and cleanup objects
     - based on 'Trove' and 'Janitor'
     - made by @Gimmy_Fimmy
     
    cleanup:
     - new -> create new cleanup
     - add -> add object and cleanup method to cleanup
     - add_function -> add function to cleanup
     - add_instance -> add instance to cleanup
     - add_render -> add bind to render stepped to cleanup
     - add_connection -> add connection to cleanup
     - add_task -> add task to cleanup
     - add_thread -> add thread to cleanup
     - add_class -> add class to cleanup and initialize it if needed
     - attach -> attach cleanup to instance
     - clean -> clean specific object
     - full_clean -> clean all cleanup objects
     - destroy -> destroy cleanup
     
]=]

local cleanup_util = {}
cleanup_util.__index = cleanup_util

local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")

local FUNCTION_MARKER = newproxy()
local CLEANUP_METHODS = table.freeze({"Destroy", "Disconnect", "destroy", "disconnect"})

local TYPES = require(replicated_storage.Types)

function cleanup_util:_clean(object: any, cleanup_method: string)
	if cleanup_method == FUNCTION_MARKER then
		object()
	else
		object[cleanup_method](object)
	end
end

function cleanup_util:_deep_clean(object: any)
	for _index, _object in ipairs(self._objects) do
		if _object[1] == object then
			self:_clean(_object[1], _object[2])
			
			table.remove(self._objects, _index)
		end
	end
end

function cleanup_util.new()
	local self = setmetatable({}, cleanup_util)
	self._cleaning = false
	self._objects = {}
	return self :: TYPES.cleanup
end

function cleanup_util:add(object: any, cleanup_method: string)
	assert(self._cleaning == false, "can't call functions while cleaning")
	assert(cleanup_method ~= nil, "cleanup method nil or missing")
	assert(object ~= nil, "object nil or missing")
	
	table.insert(self._objects, { object, cleanup_method })
	
	return self, object
end

function cleanup_util:add_function(callback: (any) -> any)
	return self:add(callback, FUNCTION_MARKER)
end

function cleanup_util:add_instance(instance: Instance)
	return self:add(instance, "Destroy")
end

function cleanup_util:add_render(name: string, priority: number, callback: (any) -> any)
	run_service:BindToRenderStep(name, priority, callback)
	
	return self:add(function()
		run_service:UnbindFromRenderStep(name)
	end, FUNCTION_MARKER)
end

function cleanup_util:add_connection(connection: RBXScriptConnection, callback: (any) -> any)
	return self:add(connection:Connect(callback), "Disconnect")
end

function cleanup_util:add_task(task_to_cancel: any)
	return self:add(function()
		task.cancel(task_to_cancel)
	end, FUNCTION_MARKER)
end


function cleanup_util:add_thread(thread: thread)
	return self:add(function()
		coroutine.close(thread)
	end, FUNCTION_MARKER)
end

function cleanup_util:add_class(class: any, ...)
	local class_type = typeof(class)
	local class_result
	
	if class_type == "function" then
		class_result = class(...)
	elseif class_type == "table" then
		class_result = class.new(...)
	end
	
	for _, cleanup_method in ipairs(CLEANUP_METHODS) do
		if typeof(class_result[cleanup_method]) == "function" then
			return self:add(class_result, cleanup_method)
		end
	end
end

function cleanup_util:attach(instance: Instance)
	return self:add_connection(instance.Destroying, function()
		self:full_clean()
	end)
end

function cleanup_util:is_cleaning()
	return self._cleaning
end

function cleanup_util:clean(object: any)
	assert(self._cleaning == false, "can't call functions while cleaning")
	
	self._cleaning = true
	self:_deep_clean(object)
	self._cleaning = false
	
	return self
end

function cleanup_util:full_clean()
	assert(self._cleaning == false, "can't call functions while cleaning")
	
	self._cleaning = true
	
	for _, object in ipairs(self._objects) do
		self:_clean(object[1], object[2])
	end
	
	table.clear(self._objects)
	
	self._cleaning = false
	
	return self
end

function cleanup_util:destroy()
	self:full_clean()
	
	table.clear(self)
	setmetatable(self, nil)
end

return { new = cleanup_util.new }