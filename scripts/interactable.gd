extends Area3D
## 通用可互动物体。玩家的射线击中它,显示 prompt,按 E 调用 action。

var prompt: String = ""
var enabled: bool = true
var action: Callable = Callable()
var prompt_fn: Callable = Callable()

func current_prompt() -> String:
	if not enabled:
		return ""
	if prompt_fn.is_valid():
		return str(prompt_fn.call())
	return prompt

func interact() -> void:
	if enabled and action.is_valid():
		action.call()
