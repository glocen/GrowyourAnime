--!strict
-- TestInput: drives the local player's real inputs from code, for the self-test and the Stage: the game's Scriptable
-- bindings, and Roblox's character controls read like a thumbstick (the PlayerModule's CharacterContext). Client only.

local Players = game:GetService("Players")

local TestInput = {}

TestInput.PadName = "NL_TestPad"
TestInput.ContextName = "GameplayContext" -- the InputContext under the Player that holds your Scriptable bindings

-- The test pad's dummy, if it stands (the self-test's server half builds both).
function TestInput.PadDummy(): Model?
	local pad = workspace:FindFirstChild(TestInput.PadName)
	return pad and pad:FindFirstChild("Dummy") :: Model?
end

-- The Scriptable binding of a gameplay action: Fire(true) presses it, Fire(false) lets go.
function TestInput.Binding(action: string): any
	local context = Players.LocalPlayer:WaitForChild(TestInput.ContextName)
	return (context :: any)[action].Script
end

-- Fire(Vector2) steers like a thumbstick: x right, y forward, from the camera; zero stops. Nil when the place doesn't run
-- Roblox's input-action character controls: Server Authority turns them on, and this game runs without it
-- (docs/engineering-plan.md, "The builder's calls"). Looked up at once: waiting for them cost the self-test 10 s a run.
function TestInput.MoveBinding(): any?
	local contexts = Players.LocalPlayer:FindFirstChild("InputContexts")
	local context = contexts and contexts:FindFirstChild("CharacterContext")
	return if context then (context :: any).MoveAction.ClassicThumbstickScriptableBinding else nil
end

return TestInput
