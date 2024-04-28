--	MIT License
--	
--	Copyright (c) 2024 Vu Nguyen
--	
--	Permission is hereby granted, free of charge, to any person obtaining a copy
--	of this software and associated documentation files (the "Software"), to deal
--	in the Software without restriction, including without limitation the rights
--	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--	copies of the Software, and to permit persons to whom the Software is
--	furnished to do so, subject to the following conditions:
--	
--	The above copyright notice and this permission notice shall be included in all
--	copies or substantial portions of the Software.
--	
--	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--	SOFTWARE.
--
--
--
--  INSTRUCTIONS: 1. PLACE THIS SCRIPT INSIDE OF ANY CHARACTER MODEL
--                2. CREATE A FOLDER NAMED "waypoints" IN WORKSPACE
--                3. POPULATE "waypoints" WITH VARIOUS SCATTERED BRICKS AS WAYPOINTS
--                4. PRESS PLAY
--
----------------------------------------------------------------------------------

--ADJUSTABLE VARIABLES

local object = script.Parent --Reference to model of the character/object
local humanoid = object.Humanoid --Reference to humanoid inside of the object

MAX_DISTANCE = 40 --Max distance the object can spot a player from in studs
WALK_SPEED = 16 --Object speed when walking (patrolling, etc.)
SPRINT_SPEED = 22 --Object speed when sprinting (spotted player)
ATTACK_RANGE = 4 --Range in which the object can kill the player in studs

--ADJUST THESE IF YOU'RE USING A CUSTOM MODEL

local pathParams = {
	["AgentHeight"] = 6, --Object's radius in studs
	["AgentRadius"] = 4, --Object's height in studs
	["AgentCanJump"] = true, --Whether or not an object can jump while pathfinding (Bricks, Meshes, etc.)
	["AgentCanClimb"] = false, --Whether or not an object can climb while pathfinding (Truss, Ladders, etc.)
	["WaypointSpacing"] = 4, --Spacing between waypoints (Higher = Greater Accuracy when Pathfinding)
	["Costs"] = nil --Determines which materials the agent will favour when pathfinding (Ex: {Water = 100, Brick = 50})
}

--SERVICES

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
object.PrimaryPart:SetNetworkOwner(nil)

local function targetVisible(target)
	--Cast a wall on a potential obstruction and check if it's the target
	local origin = object.HumanoidRootPart.Position
	local direction  = (target.HumanoidRootPart.Position - object.HumanoidRootPart.Position).unit * 40
	local ray = Ray.new(origin, direction)

	local hit, pos = workspace:FindPartOnRay(ray, object)

	if hit and hit:IsDescendantOf(target) then return true end
	
	return false
end

local function findTarget()
	
	local maxDistance = MAX_DISTANCE
	
	--Check the distance of every single player to the object
	local players = game.Players:GetPlayers()
	local nearestTarget

	for index, player in pairs(players) do
		
		if not player.Character then continue end
		
		local target = player.Character
		local distance = (object.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
		
		--Loop until the target is within visible range and a close proximity
		if distance > maxDistance or not targetVisible(target) then continue end
		
		nearestTarget = target
		maxDistance = distance
	end

	return nearestTarget
end

local function getPath(destination)
	
	--Create a path with the parameters above
	local path = PathfindingService:CreatePath(pathParams)

	path:ComputeAsync(object.HumanoidRootPart.Position, destination.Position)

	return path
end	

local function attackTarget(target)
	--Check to see the distance between the object and target
	local distance = (object.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude

	if distance > ATTACK_RANGE then return humanoid:MoveTo(target.HumanoidRootPart.Position) end
	
	target.Humanoid.Health = 0
end

local function walkTo(destination)
	
	local path = getPath(destination)

	for index, waypoint in pairs(path:GetWaypoints()) do
		
		local target = findTarget()
		
		if target then
			--print("TARGET FOUND", target.Name)
			humanoid.WalkSpeed = SPRINT_SPEED
			--If the target is found, attack the target by moving to their position
			attackTarget(target)
			break
		end
		--Continue moving to the next waypoint if no target is found
		--print("Moving to ", waypoint.Position)
		humanoid:MoveTo(waypoint.Position)
		humanoid.MoveToFinished:Wait()
		
		if humanoid.WalkSpeed ~= SPRINT_SPEED then continue end
		humanoid.WalkSpeed = WALK_SPEED
	end	
end

local function getRandomWaypoint()
	--Get all the waypoints and move to a random one
	local waypoints = workspace.waypoints:GetChildren()
	--You can change this to be in sequence using a counting variable
	local randomNum = math.random(1, #waypoints)
	walkTo(waypoints[randomNum])
end

while wait(0.1) do
	--Walk to different waypoints randomly
	getRandomWaypoint()
end

