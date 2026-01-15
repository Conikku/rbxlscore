--[=[
    @class rbxlscore.luau
    A module that evaluates a user's avatar based on their accessories.
    It retrieves the user's current wearing accessories and evaluates them using a point-based system
    to determine if the avatar has inappropriate content.
]=]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")

export type AccessoryInfo = {
	name: string,
	assetId: number,
	creatorId: number?
}

export type FlaggedItem = {
	item: AccessoryInfo,
	pattern: string,
	score: number
}

export type UserResult = {
	userId: number,
	score: number,
	flaggedItems: {FlaggedItem}
}

export type MultiUserResult = {
	success: boolean,
	users: {UserResult}?,
	totalScore: number?,
	message: string?
}

export type SingleUserResult = {
	success: boolean,
	userId: number?,
	score: number?,
	flaggedItems: {FlaggedItem}?,
	message: string?
}

export type PatternModifyResult = {
	success: boolean,
	message: string?
}

export type Pattern = {
	pattern: string,
	points: number
}

export type PatternData = {
	whiteList: {string},
	blackList: {Pattern}
}

local module = {}

-- Store the fetched patterns so that they are only fetched once.
module.fetchedPatterns = nil :: PatternData?

-- Toggle to ignore items created by Roblox account (User ID: 1)
module.ignoreRobloxItems = false

--[=[
    Retrieves all the accessories of a user, including shirts, pants, and any other assets that are currently worn.
    @param userId: number - The user ID of the player whose accessories are being retrieved.
    @returns accessories: {AccessoryInfo} - A table containing the names and asset IDs of the user's accessories.
]=]
module.getUserAccessories = function(userId: number): {AccessoryInfo}?
	if userId < 0 then
		return {}
	end
	
	local accessoryIds = {}
	local humanoidDescription = Players:GetHumanoidDescriptionFromUserIdAsync(userId)

	if humanoidDescription.GraphicTShirt ~= 0 then
		table.insert(accessoryIds, humanoidDescription.GraphicTShirt)
	end

	if humanoidDescription.Shirt ~= 0 then
		table.insert(accessoryIds, humanoidDescription.Shirt)
	end

	if humanoidDescription.Pants ~= 0 then
		table.insert(accessoryIds, humanoidDescription.Pants)
	end

	for _, data in humanoidDescription:GetAccessories(true) do
		table.insert(accessoryIds, data.AssetId)
	end

	local accessories: {AccessoryInfo} = {}
	for _, id in accessoryIds do
		local success, message = pcall(function()
			local data = Marketplace:GetProductInfoAsync(id)
			table.insert(accessories, {
				name = data.Name,
				assetId = id,
				creatorId = data.Creator.CreatorTargetId or data.Creator.Id
			})
		end)

		if not success then
			warn("RBXLSCORE_Error: " .. message, id)
		end
	end

	return accessories
end

--[=[
    Fetch the patterns from the remote JSON file on GitHub.
    This JSON contains patterns used for matching accessories and checking for inappropriate content.
    It will only fetch the data once and cache it.
    @returns PatternData? - The fetched pattern data or nil if fetching failed
]=]
local function fetchPatternsFromGit(): PatternData?
	-- Check if the patterns have already been fetched
	if module.fetchedPatterns then
		return module.fetchedPatterns
	end

	local url = "https://raw.githubusercontent.com/DevKrazes/RBXLSCORE/refs/heads/main/patterns.json"
	local response
	local success, errorMessage = pcall(function()
		response = HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		module.fetchedPatterns = data  -- Cache the fetched patterns
		return data
	else
		warn("Error fetching patterns: " .. errorMessage)
		return nil
	end
end

--[=[
    Find the original case matched pattern in the accessory name
    @param accessoryName: string - The full accessory name
    @param lowerPattern: string - The lowercase pattern that matched
    @returns string - The matched pattern with original casing
]=]
local function findOriginalCaseMatch(accessoryName: string, lowerPattern: string): string
	local lowerAccessoryName = accessoryName:lower()
	local startPos, endPos = string.find(lowerAccessoryName, lowerPattern)

	if startPos and endPos then
		return string.sub(accessoryName, startPos, endPos)
	end

	return lowerPattern -- Fallback to lowercase pattern if extraction fails
end

--[=[
    Check if an accessory should be ignored based on the Roblox filter toggle
    @param accessory: AccessoryInfo - The accessory to check
    @returns boolean - True if the accessory should be ignored
]=]
local function shouldIgnoreAccessory(accessory: AccessoryInfo): boolean
	if module.ignoreRobloxItems and accessory.creatorId == 1 then
		return true
	end
	return false
end

--[=[
    Check the accessories of multiple users for flagged patterns, determining the appropriateness of each avatar.
    The server evaluates the avatars based on a point-based system, returning the results for each user in a table format.

    @param userIds: {number} - A list of user IDs to be evaluated.
    @returns MultiUserResult - Contains the evaluation results of the avatars.
]=]
module.CheckUserIds = function(userIds: {number}): MultiUserResult
	local patterns = fetchPatternsFromGit()
	if not patterns then
		return { success = false, message = "Failed to fetch patterns from Git" }
	end

	local result: MultiUserResult = {
		success = true,
		users = {},
		totalScore = 0,
	}

	for _, userId in userIds do
		if userId < 0 then
			continue
		end
		
		local accessories = module.getUserAccessories(userId)
		if not accessories then
			return { success = false, message = `Accessories failed to fetch for user {userId}` }
		end

		
		if #accessories == 0 then
			continue
		end

		local flaggedItems: {FlaggedItem} = {}
		local bestMatchPerAccessory: {[AccessoryInfo]: FlaggedItem} = {}
		local userScore = 0

		for _, accessory in accessories do
			-- Skip if this accessory should be ignored
			if shouldIgnoreAccessory(accessory) then
				continue
			end

			local accessoryName = accessory.name
			local lowerAccessoryName = accessoryName:lower()

			for _, item in patterns.blackList do
				local lowerPattern = item.pattern:lower()
				if string.match(lowerAccessoryName, lowerPattern) then
					local isWhitelisted = false

					for _, pattern in patterns.whiteList do
						if string.match(lowerAccessoryName, pattern:lower()) then
							isWhitelisted = true
							break
						end
					end

					if not isWhitelisted then
						local matchFound = string.match(lowerAccessoryName, lowerPattern)
						if matchFound then
							local originalCaseMatch = findOriginalCaseMatch(accessoryName, lowerPattern)
							local currentBest = bestMatchPerAccessory[accessory]
							if not currentBest or item.points > currentBest.score then
								bestMatchPerAccessory[accessory] = {
									item = accessory,
									pattern = originalCaseMatch,
									score = item.points
								}
							end
						end
					end
				end
			end
		end

		for _, match in bestMatchPerAccessory do
			table.insert(flaggedItems, match)
			userScore += match.score
			result.totalScore += match.score
		end

		table.insert(result.users, {
			userId = userId,
			score = userScore,
			flaggedItems = flaggedItems
		})
	end

	return result
end

--[=[
    Check the user's accessories for flagged patterns, determining the appropriateness of the avatar.
    The server evaluates the avatar based on a point-based system and returns the result in table format.
    
    @param userId: number - The user ID of the player being evaluated.
    @returns SingleUserResult - Contains the evaluation results of the avatar.
]=]
module.CheckUserId = function(userId: number): SingleUserResult
	if userId < 0 then
		return { success = false, message = "User is fake" } -- 💔
	end
	
	local accessories = module.getUserAccessories(userId)
	if not accessories then
		return { success = false, message = `Accessories failed to fetch for user {userId}` }
	end

	local patterns = fetchPatternsFromGit()
	if not patterns then
		return { success = false, message = "Failed to fetch patterns from Git" }
	end

	local flaggedItems: {FlaggedItem} = {}
	local bestMatchPerAccessory: {[AccessoryInfo]: FlaggedItem} = {}
	local totalScore = 0

	for _, accessory in accessories do
		-- Skip if this accessory should be ignored
		if shouldIgnoreAccessory(accessory) then
			continue
		end

		local accessoryName = accessory.name
		local lowerAccessoryName = accessoryName:lower()

		for _, item in patterns.blackList do
			local lowerPattern = item.pattern:lower()
			if string.match(lowerAccessoryName, lowerPattern) then
				local isWhitelisted = false

				for _, pattern in patterns.whiteList do
					if string.match(lowerAccessoryName, pattern:lower()) then
						isWhitelisted = true
						break
					end
				end

				if not isWhitelisted then
					local matchFound = string.match(lowerAccessoryName, lowerPattern)
					if matchFound then
						local originalCaseMatch = findOriginalCaseMatch(accessoryName, lowerPattern)
						local currentBest = bestMatchPerAccessory[accessory]
						if not currentBest or item.points > currentBest.score then
							bestMatchPerAccessory[accessory] = {
								item = accessory,
								pattern = originalCaseMatch,
								score = item.points
							}
						end
					end
				end
			end
		end
	end

	for _, match in bestMatchPerAccessory do
		table.insert(flaggedItems, match)
		totalScore += match.score
	end

	local result: SingleUserResult = {
		success = true,
		userId = userId,
		score = totalScore,
		flaggedItems = flaggedItems
	}

	return result
end

--[=[
    Adds new patterns in the whiteList or blackList.
    This allows you to dynamically modify the patterns used for evaluation.
    @param listType: string - The list type, either "whiteList" or "blackList".
    @param pattern: string - The new pattern to add or replace in the list.
    @param points: number? - Used for blackList pattern to evaluate total score. 
    @returns PatternModifyResult - Contains the result of the pattern modification attempt.
]=]
module.modifyPattern = function(listType: string, pattern: string, points: number?): PatternModifyResult
	local patterns = fetchPatternsFromGit()

	if not patterns then
		return { success = false, message = "Unable to fetch patterns." }
	end

	if listType == "whiteList" then
		table.insert(patterns.whiteList, pattern)
	elseif listType == "blackList" then
		table.insert(patterns.blackList, { pattern = pattern, points = points or 0 })
	else
		return { success = false, message = "Invalid list type. Must be either 'whiteList' or 'blackList'." }
	end

	-- Cache the modified patterns
	module.fetchedPatterns = patterns
	return { success = true }
end

return module
