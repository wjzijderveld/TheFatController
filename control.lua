require "defines"
require "util"


--Called if tech is unlocked
function init(player, oldGuiSettings)
	debugLog("Init: " .. player.name .. " - " .. player.force.name)
	if player.gui.left.fatController ~= nil then
		player.gui.left.fatController.destroy()
	end
	
	local guiSettings = {}
	local forceName = player.force.name
	if oldGuiSettings == nil then
		guiSettings = util.table.deepcopy({ displayCount = 9, page = 1})
		guiSettings.stationFilterList = buildStationFilterList(global.trainsByForce[player.force.name])
	else
		guiSettings = oldGuiSettings
	end
	
	if global.character == nil then
		global.character = {}
	end
	
	--destroyGui(guiSettings.fatControllerGui)
	--destroyGui(guiSettings.fatControllerButtons)
	
		
	debugLog("create guis")
	if player.gui.left.fatController == nil then
		guiSettings.fatControllerGui = player.gui.left.add({ type="flow", name="fatController", direction="vertical"})--, style="fatcontroller_thin_flow"}) --caption="Fat Controller", 
	else
		guiSettings.fatControllerGui = player.gui.left.fatController
	end
	if player.gui.top.fatControllerButtons == nil then
		guiSettings.fatControllerButtons = player.gui.top.add({ type="flow", name="fatControllerButtons", direction="horizontal", style="fatcontroller_thin_flow"})
	else
		guiSettings.fatControllerButtons = player.gui.top.fatControllerButtons
	end
	--game.players[1].gui.top.add({type="button", name="toggleTrainInfo", caption=game.gettext("text-trains") .. " +", style="fatcontroller_button_style"})
	
	 --game.players[1].gui.left.fatController text = {"msg-intro"} caption = {"text-trains"} .. " +"
	if guiSettings.fatControllerButtons.toggleTrainInfo == nil then
		guiSettings.fatControllerButtons.add({type="button", name="toggleTrainInfo", caption = {"text-trains-collapsed"}, style="fatcontroller_button_style"})
	end
	
	
	
	if guiSettings.fatControllerGui.trainInfo ~= nil then
		--guiSettings.fatControllerGui.trainInfo.destroy()
		--global.fatControllerGui.add({ type="frame", name="trainInfo", direction="vertical", style="fatcontroller_thin_frame"})
		newTrainInfoWindow(guiSettings)
		updateTrains(global.trainsByForce[forceName])
		--refreshTrainInfoGui(global.trains, global.fatControllerGui.trainInfo, global.guiSettings, game.players[1].character)
	end

		
	-- if global.trains == nil then
		-- global.trains = {}
	-- end
	
	if global.trainsByForce == nil then
		global.trainsByForce = {}
	end
	
	if global.trainsByForce[forceName] == nil then
		global.trainsByForce[forceName] = {}
	end
	
	guiSettings.pageCount = getPageCount(global.trainsByForce[forceName], guiSettings) 
	
	filterTrainInfoList(global.trainsByForce[forceName], guiSettings.activeFilterList)
	
	updateTrains(global.trainsByForce[forceName])
	refreshTrainInfoGui(global.trainsByForce[forceName], guiSettings, player.character)
	
	return guiSettings
end

onTickAfterUnlocked = function(event)
	if global.unlocked and (global.guiSetting == nil or global.trainsByForce == nil) then
		--debugLog("Unlocked!")
		if global.trainsByForce == nil then 
			global.trainsByForce = {}
		end
		
		if global.guiSettings == nil then global.guiSettings = {} end
		
		for i,player in ipairs(game.players) do
			if global.guiSettings[i] == nil then
				--debugLog("Player: " .. i)
				global.guiSettings[i] = init(player, global.guiSettings[i])
			end
		end
		game.on_event(defines.events.on_tick, onTickAfterUnlocked)
	end
	
	if event.tick%60==13 then
		pageCount = -1
		if global.guiSettings == nil then
			loadGame()
		end
		local updateGui = false
		for i,guiSettings in ipairs(global.guiSettings) do
			if guiSettings.fatControllerGui ~= nil and guiSettings.fatControllerGui.trainInfo ~= nil then
				updateGui = true
			end
		end
		if updateGui then
			debugLog("updateGUI")
			for _,trains in pairs(global.trainsByForce) do
				updateTrains(trains)
			end
			refreshAllTrainInfoGuis(global.trainsByForce, global.guiSettings, game.players, false)
			for i,player in ipairs(game.players) do
				refreshTrainInfoGui(global.trainsByForce[player.force.name], global.guiSettings[i], player.character)
				global.guiSettings[i].pageCount = getPageCount(global.trainsByForce[player.force.name], global.guiSettings[i]) 
			end
		end
	end
	
	for i,guiSettings in ipairs(global.guiSettings) do
		if guiSettings.followEntity ~= nil then -- Are we in remote camera mode?
			if not guiSettings.followEntity.valid  or game.players[i].vehicle == nil then
				swapPlayer(game.players[i], global.character[i])
				if guiSettings.fatControllerButtons ~= nil and guiSettings.fatControllerButtons.returnToPlayer ~= nil then
					guiSettings.fatControllerButtons.returnToPlayer.destroy()
				end
				
				if not guiSettings.followEntity.valid then
					removeTrainInfoFromEntity(global.trainsByForce[game.players[i].force.name], guiSettings.followEntity)
					newTrainInfoWindow(guiSettings)
					refreshTrainInfoGui(global.trainsByForce[game.players[i].force.name], guiSettings, game.players[i].character)
					
				end
				
				global.character[i] = nil
				guiSettings.followEntity = nil
				
			elseif global.character[i] ~= nil and global.character[i].valid and guiSettings.fatControllerButtons ~= nil and guiSettings.fatControllerButtons.returnToPlayer == nil then
				guiSettings.fatControllerButtons.add({ type="button", name="returnToPlayer", caption={"text-player"}, style = "fatcontroller_selected_button"})
				--game.players[1].teleport(global.followEntity.position)
			elseif global.character[i] ~= nil and not global.character[i].valid  then
				game.set_game_state({gamefinished=true, playerwon=false})
			end
		end
	end
	
  -- on_the_path = 0,
  -- -- had path and lost it - must stop
  -- path_lost = 1,
  -- -- doesn't have anywhere to go
  -- no_schedule = 2,
  -- has no path and is stopped
  -- no_path = 3,
  -- -- braking before the railSignal
  -- arrive_signal = 4,
  -- wait_signal = 5,
  -- -- braking before the station
  -- arrive_station = 6,
  -- wait_station = 7,
  -- -- switched to the manual control and has to stop
  -- manual_control_stop = 8,
  -- -- can move if user explicitly sits in and rides the train
  -- manual_control = 9,
  -- -- train was switched to auto control but it is moving and needs to be stopped
  -- stop_for_auto_control = 10
	
	if event.tick%120 == 37 then
		local alarmState = {}
		alarmState.timeToStation = false
		alarmState.timeAtSignal = false
		alarmState.noPath = false
		local newAlarm = false
		for forceName,trains in pairs(global.trainsByForce) do
			for i,trainInfo in ipairs(trains) do
				local alarmSet = false
				if trainInfo.lastState == 1 or trainInfo.lastState == 3 then
					--game.players[1].print("No Path " .. i .. " " .. game.tick)
					if not trainInfo.alarm then 
						alarmState.noPath = true
						newAlarm = true
						trainInfo.updated = true
					end
					alarmSet = true
					trainInfo.alarm = true
				end
				-- 36000, 10 minutes
				if trainInfo.lastState ~= 7 and trainInfo.lastStateStation ~= nil and (trainInfo.lastStateStation + 36000 < game.tick and (trainInfo.lastState ~= 2 or trainInfo.lastState ~= 8 or trainInfo.lastState ~= 9)) then
					if not trainInfo.alarm then 
						alarmState.timeToStation = true
						newAlarm = true
						trainInfo.updated = true
					end
					alarmSet = true
					trainInfo.alarm = true
				end
				-- 72002 minutes lol, wtf?
				if trainInfo.lastState == 5 and (trainInfo.lastStateTick ~= nil and trainInfo.lastStateTick + 7200 < game.tick ) then
					if not trainInfo.alarm then 
						alarmState.timeAtSignal = true
						newAlarm = true
						trainInfo.updated = true
					end
					alarmSet = true
					trainInfo.alarm = true
				end
				if not alarmSet then
					if trainInfo.alarm then
						trainInfo.updated = true
					end
					trainInfo.alarm = false
				end
			end
		end
		
		for i,guiSettings in ipairs(global.guiSettings) do
			if guiSettings.alarm == nil or guiSettings.alarm.noPath == nil then
				guiSettings.alarm = {}
				guiSettings.alarm.timeToStation = true
				guiSettings.alarm.timeAtSignal = true
				guiSettings.alarm.noPath = true
			end
			if (guiSettings.alarm.timeToStation or guiSettings.alarm.timeAtSignal or guiSettings.alarm.noPath) and newAlarm then
				if guiSettings.alarm.timeToStation and alarmState.timeToStation then
					guiSettings.alarm.active = true
					alertPlayer(game.players[i], guiSettings, game.tick, ({"msg-alarm-tolongtostation"}))
				end
				if guiSettings.alarm.timeAtSignal and alarmState.timeAtSignal then
					guiSettings.alarm.active = true
					alertPlayer(game.players[i], guiSettings, game.tick, ({"msg-alarm-tolongatsignal"}))
				end
				if guiSettings.alarm.noPath and alarmState.noPath then
					guiSettings.alarm.active = true
					alertPlayer(game.players[i], guiSettings, game.tick, ({"msg-alarm-nopath"}))
				end
			else
				guiSettings.alarm.active = false
			end
		end
	end
	
	--if event.tick%30==4 and global.fatControllerGui.trainInfo ~= nil then
		--refreshTrainInfoGui(global.trains, global.fatControllerGui.trainInfo, global.guiSettings, game.players[1].character)
	--end
end

function alertPlayer(player,guiSettings,tick,message)
	if player ~= nil and guiSettings ~= nil and guiSettings.alarm ~= nil and guiSettings.alarm.active and (guiSettings.alarm.lastMessage == nil or guiSettings.alarm.lastMessage + 120 < tick) then
		guiSettings.lastMessage = tick
		player.print(message)
	end
end
-- game.on_init(function()
	-- debugLog("init")
-- end)

loadGame = function ()
	-- debugLog("LOADGAME!")
	-- if global.tech == nil then
		-- global.tech = game.players[1].force.technologies["rail-signals"]
		
	-- end
	-- global.unlocked = global.tech.researched
	
	-- Kill all old versions of TFC
	if global.fatControllerGui ~= nil or global.fatControllerButtons ~= nil then
		destroyGui(global.fatControllerGui)
		destroyGui(global.fatControllerButtons)
		global.fatControllerGui = nil
		global.fatControllerButtons = nil
		global.trains = nil
		global.trainsByForce = nil
		global.guiSettings = nil
		global.unlocked = nil
	end

	for _,force in pairs(game.forces) do
		if force.technologies["rail-signals"].researched then
			global.unlocked = true
		end
	end
	if global.unlocked then
		game.on_event(defines.events.on_tick, onTickAfterUnlocked)
	end
		
	
	if global.unlocked then
		--debugLog("Unlocked!")
		-- if global.trains == nil then 
			-- global.trains = {}
		-- end
		
		if global.trainsByForce == nil then 
			global.trainsByForce = {}
		end
		
		if global.guiSettings == nil then global.guiSettings = {} end
		
		for i,player in ipairs(game.players) do
			if global.guiSettings[i] == nil then
				--debugLog("Player: " .. i)
				global.guiSettings[i] = init(player, global.guiSettings[i])
			end
		end
		game.on_event(defines.events.on_tick, onTickAfterUnlocked)
	end
end

game.on_event(defines.events.on_player_created, function(event)
	if global.unlocked then
		if global.guiSettings == nil then 
			global.guiSettings = {} 
		end
		if global.guiSettings[event.player_index] == nil then
			global.guiSettings[event.player_index] = init(game.players[event.player_index], global.guiSettings[i])
		end
	end
end)

onTickBeforeUnlocked = function(event)
	if not global.unlocked then
		if event.tick%180==12 then
			
			for _,force in pairs(game.forces) do
				if force.technologies["rail-signals"].researched then
					global.unlocked = true
				end
			end
			
			if global.unlocked then
				game.on_event(defines.events.on_tick, onTickAfterUnlocked)
			end
		end
	end
end

game.on_event(defines.events.on_tick,onTickBeforeUnlocked)

game.on_load(loadGame)

function destroyGui(guiA)
	if guiA ~= nil and guiA.valid then
		guiA.destroy()
	end
end

function buildStationFilterList(trains)
	local newList = {}
	if trains ~= nil then
		for i, trainInfo in ipairs(trains) do
			-- if trainInfo.group ~= nil then
				-- newList[trainInfo.group] = true
			-- end
			if trainInfo.stations ~= nil then
				for station, value in pairs(trainInfo.stations) do
					--debugLog(station)
					newList[station] = true
				end
			end
		end
	end
	return newList
end

function getLocomotives(train)
	if train ~= nil and train.valid then
		local locos = {}
		for i,carriage in ipairs(train.carriages) do
			if carriage ~= nil and carriage.valid and isTrainType(carriage.type) then
				table.insert(locos, carriage)
			end
		end
		return locos
	end
end

function getNewTrainInfo(train)
	if train ~= nil then
		local carriages = train.carriages
		if carriages ~= nil and carriages[1] ~= nil and carriages[1].valid then
			local newTrainInfo = {}
			newTrainInfo.train = train
			--newTrainInfo.firstCarriage = getFirstCarriage(train)
			newTrainInfo.locomotives = getLocomotives(train)
			
			--newTrainInfo.display = true
			return newTrainInfo
		end
	end
end

entityBuilt = function(event)
	local entity = event.created_entity
	if entity.type == "locomotive" and global.unlocked then --or entity.type == "cargo-wagon"
		getTrainInfoOrNewFromEntity(global.trainsByForce[entity.force.name], entity)
	end
end

game.on_event(defines.events.on_built_entity, entityBuilt)
game.on_event(defines.events.on_robot_built_entity, entityBuilt)

game.on_event(defines.events.on_force_created, function(event)
	if global.trainsByForce ~= nil then
		global.trainsByForce[event.force.name] = {}
	end
end)

  -- -- normal state - following the path
  -- on_the_path = 0,
  -- -- had path and lost it - must stop
  -- path_lost = 1,
  -- -- doesn't have anywhere to go
  -- no_schedule = 2,
  -- -- has no path and is stopped
  -- no_path = 3,
  -- -- braking before the railSignal
  -- arrive_signal = 4,
  -- wait_signal = 5,
  -- -- braking before the station
  -- arrive_station = 6,
  -- wait_station = 7,
  -- -- switched to the manual control and has to stop
  -- manual_control_stop = 8,
  -- -- can move if user explicitly sits in and rides the train
  -- manual_control = 9,
  -- -- train was switched to auto control but it is moving and needs to be stopped
  -- stop_for_auto_control = 10

game.on_event(defines.events.on_train_changed_state, function(event)
	--debugLog("State Change - " .. game.tick)
	if not global.unlocked then --This is retarded, just set the event on unlock
		return
	end
	
	if global.trainsByForce == nil then
		global.trainsByForce = {}
	end
	
	if global.guiSettings == nil then
		return
	end
	
	local train = event.train
	local entity = train.carriages[1]
	
	
	if global.trainsByForce[entity.force.name] == nil then
		global.trainsByForce[entity.force.name] = {}
	end
	trains = global.trainsByForce[entity.force.name]
	local trainInfo = getTrainInfoOrNewFromEntity(trains, entity)
	if trainInfo ~= nil then
		local newtrain = false
		if trainInfo.updated == nil then
			newtrain = true
		else
		end
		updateTrainInfo(trainInfo,game.tick)
		if newtrain then
			for i,player in ipairs(game.players) do
				global.guiSettings[i].pageCount = getPageCount(trains, global.guiSettings[i]) 
			end
		end
		refreshAllTrainInfoGuis(global.trainsByForce, global.guiSettings, game.players, newtrain)
	end
end)

function getTrainInfoOrNewFromEntity(trains, entity)
	local trainInfo = getTrainInfoFromEntity(trains, entity)
	if trainInfo == nil then
		local newTrainInfo = getNewTrainInfo(entity.train)
		table.insert(trains, newTrainInfo)
		return newTrainInfo
	else
		return trainInfo
	end
end

game.on_event(defines.events.on_gui_click, function(event)
	if not global.unlocked then --This is retarded, just set the event on unlock
		return
	end
	
	local refreshGui = false
	local newInfoWindow = false
	local rematchStationList = false
	local guiSettings = global.guiSettings[event.element.player_index]
	local player = game.players[event.element.player_index]
	local trains = global.trainsByForce[player.force.name]
	debugLog("CLICK! " .. event.element.name .. game.tick)
	
	if guiSettings.alarm == nil then
		guiSettings.alarm = {}
	end
	

	if event.element.name == "toggleTrainInfo" then
		if guiSettings.fatControllerGui.trainInfo == nil then
			newInfoWindow = true
			refreshGui = true
			event.element.caption = {"text-trains"}
		else
			guiSettings.fatControllerGui.trainInfo.destroy()
			event.element.caption = {"text-trains-collapsed"}
		end 
	elseif event.element.name == "returnToPlayer" then
		if global.character[event.element.player_index] ~= nil then
			if player.vehicle ~= nil then
				player.vehicle.passenger = nil
			end
			swapPlayer(player, global.character[event.element.player_index])
			global.character[event.element.player_index] = nil
			event.element.destroy()
			guiSettings.followEntity = nil
		end
	elseif endsWith(event.element.name,"_toggleManualMode") then
		local trainInfo = getTrainInfoFromElementName(trains, event.element.name)
		if trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid then
			trainInfo.train.manual_mode = not trainInfo.train.manual_mode
			swapCaption(event.element, "ll", ">")
		end
	elseif endsWith(event.element.name,"_toggleFollowMode") then
		local trainInfo = getTrainInfoFromElementName(trains, event.element.name)
		if trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid then
			if global.character[event.element.player_index] == nil then --Move to train
				if trainInfo.train.carriages[1].passenger ~= nil then
					player.print({"msg-intrain"})
				else
					global.character[event.element.player_index] = player.character
					guiSettings.followEntity = trainInfo.train.carriages[1] -- HERE
					
					--fatControllerEntity = 
					swapPlayer(player,newFatControllerEntity(player))
					--event.element.style = "fatcontroller_selected_button"
					event.element.caption = "X"
					trainInfo.train.carriages[1].passenger = player.character
				end
			elseif guiSettings.followEntity ~= nil and trainInfo.train ~= nil and trainInfo.train.valid then
				if player.vehicle ~= nil then
					player.vehicle.passenger = nil
				end
				if guiSettings.followEntity == trainInfo.train.carriages[1] or trainInfo.train.carriages[1].passenger ~= nil then --Go back to player
					swapPlayer(player, global.character[event.element.player_index])
					--event.element.style = "fatcontroller_button_style"
					event.element.caption = "c"
					if guiSettings.fatControllerButtons ~= nil and guiSettings.fatControllerButtons.returnToPlayer ~= nil then
						guiSettings.fatControllerButtons.returnToPlayer.destroy()
					end
					global.character[event.element.player_index] = nil
					guiSettings.followEntity = nil
				else -- Go to different train
					
					guiSettings.followEntity = trainInfo.train.carriages[1] -- AND HERE
					--event.element.style = "fatcontroller_selected_button"
					event.element.caption = "X"
					
					trainInfo.train.carriages[1].passenger = player.character
					--game.players[1].vehicle = trainInfo.train.carriages[1]
				end
			end
			
		end
	elseif event.element.name == "page_back" then
		if guiSettings.page > 1 then
			guiSettings.page = guiSettings.page - 1
			--global.fatControllerGui.trainInfo.trainInfoControls.page_number.caption = global.guiSettings.page
			--newTrainInfoWindow(global.fatControllerGui, global.guiSettings)
			--refreshTrainInfoGui(global.trains, global.fatControllerGui.trainInfo, global.guiSettings)
			newInfoWindow = true
			refreshGui = true
		end
	elseif event.element.name == "page_forward" then
		if guiSettings.page < getPageCount(trains, guiSettings) then
			guiSettings.page = guiSettings.page + 1
			--debugLog(global.guiSettings.page)
			--newTrainInfoWindow(global.fatControllerGui, global.guiSettings)
			--refreshTrainInfoGui(global.trains, global.fatControllerGui.trainInfo, global.guiSettings)
			newInfoWindow = true
			refreshGui = true
		end
	elseif event.element.name == "page_number" then
		togglePageSelectWindow(player.gui.center, guiSettings)
	elseif event.element.name == "pageSelectOK" then
		local gui = player.gui.center.pageSelect
		if gui ~= nil then
			
			local newInt = tonumber(gui.pageSelectValue.text)
			
			if newInt then
				if newInt < 1 then
					newInt = 1
				elseif newInt > 50 then
					newInt = 50
				end
				guiSettings.displayCount = newInt
				guiSettings.pageCount = getPageCount(trains, guiSettings) 
				guiSettings.page = 1
				refreshGui = true
				newInfoWindow = true
			else
				player.print({"msg-notanumber"})
			end
			gui.destroy()
		end
	elseif event.element.name == "toggleStationFilter" then 
		guiSettings.stationFilterList = buildStationFilterList(trains)
		toggleStationFilterWindow(player.gui.center, guiSettings)
	elseif event.element.name == "clearStationFilter" or event.element.name == "stationFilterClear" then
		if guiSettings.activeFilterList ~= nil then
			guiSettings.activeFilterList = nil
			
			rematchStationList = true
			newInfoWindow = true
			refreshGui = true
		end
		if player.gui.center.stationFilterWindow ~= nil then
			player.gui.center.stationFilterWindow.destroy()
		end
	elseif event.element.name == "stationFilterOK" then
		local gui = player.gui.center.stationFilterWindow
		if gui ~= nil and gui.checkboxGroup ~= nil then
			local newFilter = {}
			local listEmpty = true
			for station,value in pairs(guiSettings.stationFilterList) do
				local checkboxA = gui.checkboxGroup[station .. "_stationFilter"]
				if checkboxA ~= nil and checkboxA.state then
					listEmpty = false
					--debugLog(station)
					newFilter[station] = true
				end
			end
			if not listEmpty then
				guiSettings.activeFilterList = newFilter
				
				--glo.filteredTrains = buildFilteredTrainInfoList(global.trains, global.guiSettings.activeFilterList)
			else
				guiSettings.activeFilterList = nil
			end
			
			gui.destroy()
			guiSettings.page = 1
			rematchStationList = true
			newInfoWindow = true
			refreshGui = true
		end
	elseif endsWith(event.element.name,"_stationFilter") then
		local stationName = string.gsub(event.element.name, "_stationFilter", "")
		if event.element.state then
			if guiSettings.activeFilterList == nil then
				guiSettings.activeFilterList = {}
			end
		
			guiSettings.activeFilterList[stationName] = true
		elseif guiSettings.activeFilterList ~= nil then
			guiSettings.activeFilterList[stationName] = nil
			if tableIsEmpty(guiSettings.activeFilterList) then
				guiSettings.activeFilterList = nil
			end
		end
		--debugLog(event.element.name)
		guiSettings.page = 1
		rematchStationList = true
		newInfoWindow = true
		refreshGui = true
	--alarmOK alarmTimeToStation alarmTimeAtSignal alarmNoPath alarmButton
	elseif event.element.name == "alarmButton" or event.element.name == "alarmOK" then 
		toggleAlarmWindow(player.gui.center, guiSettings)
	elseif event.element.name == "alarmTimeToStation" then
		guiSettings.alarm.timeToStation = event.element.state
	elseif event.element.name == "alarmTimeAtSignal" then
		guiSettings.alarm.timeAtSignal = event.element.state
	elseif event.element.name == "alarmNoPath" then
		guiSettings.alarm.noPath = event.element.state
	end
	
	if rematchStationList then
		filterTrainInfoList(trains, guiSettings.activeFilterList)
		guiSettings.pageCount = getPageCount(trains, guiSettings) 
	end
	
	if newInfoWindow then
		newTrainInfoWindow(guiSettings)
	end
	
	if refreshGui then
		refreshTrainInfoGui(trains, guiSettings, player.character)
	end
	

end)

-- function swapStyle(guiElement, styleA, styleB)
	-- if guiElement ~= nil and styleA ~= nil and styleB ~= nil then
		-- if guiElement.style == styleA then
			-- guiElement.style = styleB
		-- elseif guiElement.style == styleB then
			-- guiElement.style = styleA
		-- end
	-- end
-- end

function swapCaption(guiElement, captionA, captionB)
	if guiElement ~= nil and captionA ~= nil and captionB ~= nil then
		if guiElement.caption == captionA then
			guiElement.caption = captionB
		elseif guiElement.caption == captionB then
			guiElement.caption = captionA
		end
	end

end

function tableIsEmpty(tableA)
	if tableA ~= nil then
		for i,v in pairs(tableA) do
			return false
		end
	end
	return true
end

function toggleStationFilterWindow(gui, guiSettings)
	if gui ~= nil then
		if gui.stationFilterWindow == nil then
			--local sortedList = table.sort(a)
			local window = gui.add({type="frame", name="stationFilterWindow", caption={"msg-stationFilter"}, direction="vertical" }) --style="fatcontroller_thin_frame"}) 
			window.add({type="table", name="checkboxGroup", colspan=3})
			for name, value in pairsByKeys(guiSettings.stationFilterList) do
				if guiSettings.activeFilterList ~= nil and guiSettings.activeFilterList[name] then 
					window.checkboxGroup.add({type="checkbox", name=name .. "_stationFilter", caption=name, state=true}) --style="filter_group_button_style"})
				else
					window.checkboxGroup.add({type="checkbox", name=name .. "_stationFilter", caption=name, state=false}) --style="filter_group_button_style"})
				end
				
				
			end
			window.add({type="flow", name="buttonFlow"})
			window.buttonFlow.add({type="button", name="stationFilterClear", caption={"msg-Clear"}})
			window.buttonFlow.add({type="button", name="stationFilterOK", caption={"msg-OK"}})
			
		else
			gui.stationFilterWindow.destroy()
		end
	end
end



function togglePageSelectWindow(gui, guiSettings)
	if gui ~= nil then
		if gui.pageSelect == nil then
			local window = gui.add({type="frame", name="pageSelect", caption={"msg-displayCount"}, direction="vertical" }) --style="fatcontroller_thin_frame"}) 
			window.add({type="textfield", name="pageSelectValue", text=guiSettings.displayCount .. ""})
			window.pageSelectValue.text = guiSettings.displayCount .. ""
			window.add({type="button", name="pageSelectOK", caption={"msg-OK"}})
		else
			gui.pageSelect.destroy()
		end
	end
end

function toggleAlarmWindow(gui, guiSettings)
	if gui ~= nil then
		if gui.alarmWindow == nil then
			local window = gui.add({type="frame",name="alarmWindow", caption={"text-alarmwindow"}, direction="vertical" })
			local stateTimeToStation = true
			if guiSettings.alarm ~= nil and not guiSettings.alarm.timeToStation then
				stateTimeToStation = false
			end
			window.add({type="checkbox", name="alarmTimeToStation", caption={"text-alarmtimetostation"}, state=stateTimeToStation}) --style="filter_group_button_style"})
			local stateTimeAtSignal = true
			if guiSettings.alarm ~= nil and not guiSettings.alarm.timeAtSignal then
				stateTimeAtSignal = false
			end
			window.add({type="checkbox", name="alarmTimeAtSignal", caption={"text-alarmtimeatsignal"}, state=stateTimeAtSignal}) --style="filter_group_button_style"})
			local stateNoPath = true
			if guiSettings.alarm ~= nil and not guiSettings.alarm.noPath then
				stateNoPath = false
			end
			window.add({type="checkbox", name="alarmNoPath", caption={"text-alarmtimenopath"}, state=stateNoPath}) --style="filter_group_button_style"})
			window.add({type="button", name="alarmOK", caption={"msg-OK"}})
		else
			gui.alarmWindow.destroy()
		end
	end
end

function getPageCount(trains, guiSettings)
	local trainCount = 0
	for i,trainInfo in ipairs(trains) do
		if guiSettings.activeFilterList == nil or trainInfo.matchesStationFilter then
			trainCount = trainCount + 1
		end
	end
	return math.floor((trainCount - 1) / guiSettings.displayCount) + 1 
end

local onEntityDied = function (event)
	if global.unlocked and global.guiSettings ~= nil then
		for forceName,trains in pairs(global.trainsByForce) do
			updateTrains(trains)
		end
		
		
		for i, player in ipairs(game.players) do
			local guiSettings = global.guiSettings[i]
			if guiSettings.followEntity ~= nil and guiSettings.followEntity == event.entity then --Go back to player
				if game.players[i].vehicle ~= nil then
					game.players[i].vehicle.passenger = nil
				end
				
				swapPlayer(game.players[i], global.character[i])
				
				if guiSettings.fatControllerButtons.returnToPlayer ~= nil then
					guiSettings.fatControllerButtons.returnToPlayer.destroy()
				end
				
				global.character[i] = nil
				guiSettings.followEntity = nil
			end
		end
		
		refreshAllTrainInfoGuis(global.trainsByForce, global.guiSettings, game.players, true)
		
	end
end

function refreshAllTrainInfoGuis(trainsByForce, guiSettings, players, destroy)
	for i,player in ipairs(players) do
		--local trainInfo = guiSettings[i].fatControllerGui.trainInfo
		if guiSettings[i] ~= nil and guiSettings[i].fatControllerGui.trainInfo ~= nil then
			if destroy then
				guiSettings[i].fatControllerGui.trainInfo.destroy()
				newTrainInfoWindow(guiSettings[i])
			end
			refreshTrainInfoGui(trainsByForce[player.force.name], guiSettings[i], player.character)
		end
	end
end

game.on_event(defines.events.on_entity_died, onEntityDied)

game.on_event(defines.events.on_preplayer_mined_item, onEntityDied)

function isUnlocked(technologies)
	return technologies["rail-signals"].researched 
end

function swapPlayer(player, character)
	--player.teleport(character.position)
	if player.character ~= nil and player.character.valid and player.character.name == "fatcontroller" then
		player.character.destroy()
	end
	player.character = character
end

function isTrainType(type)
	if type == "locomotive" then
		return true
	end
	return false
end

function getTrainInfoFromElementName(trains, elementName)
	for i, trainInfo in ipairs(trains) do
		if trainInfo ~= nil and trainInfo.guiName ~= nil and startsWith(elementName, trainInfo.guiName .. "_") then
			return trainInfo
		end
	end
end


function getTrainInfoFromEntity(trains, entity)
	if trains ~= nil then
		for i, trainInfo in ipairs(trains) do
			if trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid and entity == trainInfo.train.carriages[1] then
				return trainInfo
			end
		end
	end
end

function removeTrainInfoFromElementName(trains, elementName)
	for i, trainInfo in ipairs(trains) do
		if trainInfo ~= nil and trainInfo.guiName ~= nil and startsWith(elementName, trainInfo.guiName .. "_") then
			table.remove(trains, i)
			return
		end
	end
end

function removeTrainInfoFromEntity(trains, entity)
	for i, trainInfo in ipairs(trains) do
		if trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid and trainInfo.train.carriages[1] == entity then
			table.remove(trains, i)
			return
		end
	end
end

function getHighestInventoryCount(trainInfo)
	local inventry = nil
	
	if trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid and trainInfo.train.carriages ~= nil then
		local itemsCount = 0
		local largestItem = {}
		local items = {}
		
		
		
		for i, carriage in ipairs(trainInfo.train.carriages) do
			if carriage ~= nil and carriage.valid and carriage.type == "cargo-wagon" then
				if carriage.name == "rail-tanker" then
					debugLog("Looking for Oil!")
					local liquid = remote.call("railtanker","getLiquidByWagon",carriage)
					if liquid ~= nil and (largestItem.count == nil or liquid.amount > largestItem.count) then
						debugLog("Oil!")
						--if liquid.type == nil then liquid.type = "NILMotherFucker" end
						
						
						largestItem.name = liquid.type
						largestItem.count = math.floor(liquid.amount)
					end
				else
					local inv = carriage.get_inventory(1)
					local contents = inv.get_contents()
					for name, count in pairs(contents) do
						if items[name] ~= nil then
							items[name] = items[name] + count
						else
							items[name] = count
							itemsCount = itemsCount + 1
						end
						if largestItem.count == nil or largestItem.count < items[name] then
							largestItem.name = name
							largestItem.count = items[name]
						end
					end
				end
			end

		end
		
		if largestItem.name ~= nil then
			--local displayName = game.get_localised_item_name(largestItem.name)
			-- if startsWith(displayName, "Unknown-key") then
				-- displayName = largestItem.name
			-- end
			local displayName = largestItem.name
			inventory = displayName .. ": " .. largestItem.count
			if itemsCount > 1 then
				inventory = inventory .. "..."
			end
		else
			inventory = ""
		end
	end
	debugLog("inventory: " ..  inventory)
	return inventory
end

--NEVER CALLED
function updateInventoryCount(trains)
	for i, trainInfo in ipairs(trains) do
		if trainInfo.train ~= nil and trainInfo.train.valid and trainInfo.train.speed == 0 then
			local tempInventory = getHighestInventoryCount(trainInfo)
			if tempInventory ~= nil then
				trainInfo.inventory = tempInventory
			end
		end
	end
end

function newFatControllerEntity(player)
	return player.surface.create_entity({name="fatcontroller", position=player.position, force=player.force})
	-- local entities = game.find_entities_filtered({area={{position.x, position.y},{position.x, position.y}}, name="fatcontroller"})
	-- if entities[1] ~= nil then
		-- return entities[1]
	-- end
end

function newTrainInfoWindow(guiSettings)
	
	if guiSettings == nil then
		guiSettings = util.table.deepcopy({ displayCount = 9, page = 1})
	end
	local gui = guiSettings.fatControllerGui
	if gui ~= nil and gui.trainInfo ~= nil then
		gui.trainInfo.destroy()
	end
	
	local newGui
	
	if gui ~= nil and gui.trainInfo ~= nil then
		newGui = gui.trainInfo
	else
		newGui = gui.add({ type="flow", name="trainInfo", direction="vertical", style="fatcontroller_thin_flow"})
	end
	
	if newGui.trainInfoControls == nil then
		newGui.add({type = "frame", name="trainInfoControls", direction="horizontal", style="fatcontroller_thin_frame"})
	end
	
	if newGui.trainInfoControls.pageButtons == nil then
		newGui.trainInfoControls.add({type = "flow", name="pageButtons",  direction="horizontal", style="fatcontroller_button_flow"})
	end
	
	if newGui.trainInfoControls.pageButtons.page_back == nil then
		
		if guiSettings.page > 1 then
			newGui.trainInfoControls.pageButtons.add({type="button", name="page_back", caption="<", style="fatcontroller_button_style"})
		else
			newGui.trainInfoControls.pageButtons.add({type="button", name="page_back", caption="<", style="fatcontroller_disabled_button"})
		end
	end
	
	-- if guiSettings.page > 1 then
		-- newGui.trainInfoControls.pageButtons.page_back.style = "fatcontroller_button_style"
	-- else
		-- newGui.trainInfoControls.pageButtons.page_back.style = "fatcontroller_disabled_button"
	-- end
	
	if newGui.trainInfoControls.pageButtons.page_number == nil then
		newGui.trainInfoControls.pageButtons.add({type="button", name="page_number", caption=guiSettings.page .. "/" .. guiSettings.pageCount, style="fatcontroller_button_style"})
	else
		newGui.trainInfoControls.pageButtons.page_number.caption = guiSettings.page .. "/" .. guiSettings.pageCount
	end
	
	if newGui.trainInfoControls.pageButtons.page_forward == nil then
		if guiSettings.page < guiSettings.pageCount then
			newGui.trainInfoControls.pageButtons.add({type="button", name="page_forward", caption=">", style="fatcontroller_button_style"})
		else
			newGui.trainInfoControls.pageButtons.add({type="button", name="page_forward", caption=">", style="fatcontroller_disabled_button"})
		end
		
	end
	
	-- if guiSettings.page < guiSettings.pageCount then
		-- newGui.trainInfoControls.pageButtons.page_forward.style = "fatcontroller_button_style"
	-- else
		-- newGui.trainInfoControls.pageButtons.page_forward.style = "fatcontroller_disabled_button"
	-- end
	
	if newGui.trainInfoControls.filterButtons == nil then
		newGui.trainInfoControls.add({type = "flow", name="filterButtons",  direction="horizontal", style="fatcontroller_button_flow"})
	end
	
	if newGui.trainInfoControls.filterButtons.toggleStationFilter == nil then
		
		if guiSettings.activeFilterList ~= nil then 
			newGui.trainInfoControls.filterButtons.add({type="button", name="toggleStationFilter", caption="s", style="fatcontroller_selected_button"})
		else
			newGui.trainInfoControls.filterButtons.add({type="button", name="toggleStationFilter", caption="s", style="fatcontroller_button_style"})
		end
	end
	
	if newGui.trainInfoControls.filterButtons.clearStationFilter == nil then
		--if guiSettings.activeFilterList ~= nil then 
			--newGui.trainInfoControls.filterButtons.add({type="button", name="clearStationFilter", caption="x", style="fatcontroller_selected_button"})
		--else
			newGui.trainInfoControls.filterButtons.add({type="button", name="clearStationFilter", caption="x", style="fatcontroller_button_style"})
		--end
	end
	
	if newGui.trainInfoControls.alarm == nil then
		newGui.trainInfoControls.add({type = "flow", name="alarm",  direction="horizontal", style="fatcontroller_button_flow"})
	end
	
	if newGui.trainInfoControls.alarm.alarmButton == nil then
		newGui.trainInfoControls.alarm.add({type="button", name="alarmButton", caption="!", style="fatcontroller_button_style"})
	end
	-- if guiSettings.activeFilterList ~= nil then 
		-- newGui.trainInfoControls.filterButtons.toggleStationFilter.style = "fatcontroller_selected_button"
		-- newGui.trainInfoControls.filterButtons.clearStationFilter.style = "fatcontroller_button_style"
	-- else
		-- newGui.trainInfoControls.filterButtons.toggleStationFilter.style = "fatcontroller_button_style"
		-- newGui.trainInfoControls.filterButtons.clearStationFilter.style = "fatcontroller_disabled_button"
	-- end
	
	
	

	
	return newGui
end

-- function getFirstCarriage(train)
	-- if train ~= nil and train.valid then
		-- for i, carriage in ipairs(train.carriages) do
			-- if carriage ~= nil and carriage.valid and isTrainType(carriage.type) then
				-- return carriage
			-- end
		-- end
	-- end
-- end

function getTrainFromLocomotives(locomotives)
	if locomotives ~= nil then
		for i,loco in ipairs(locomotives) do
			if loco ~= nil and loco.valid and loco.train ~= nil and loco.train.valid then
				return loco.train
			end
		end
	end
end

function isTrainInfoDuplicate(trains, trainInfoB, index)
	--local trainInfoB = trains[index]
	if trainInfoB ~= nil and trainInfoB.train ~= nil and trainInfoB.train.valid then
		for i, trainInfo in ipairs(trains) do
			--debugLog(i)
			if i ~= index and trainInfo.train ~= nil and trainInfo.train.valid and compareTrains(trainInfo.train, trainInfoB.train) then
				return true
			end
		end
	end
	
	
	return false
end

function compareTrains(trainA, trainB)
	if trainA ~= nil and trainA.valid and trainB ~= nil and trainB.valid and trainA.carriages[1] == trainB.carriages[1] then
		return true
	end
	return false
end

function updateTrains(trains)
	--if trains ~= nil then
		for i, trainInfo in ipairs(trains) do
			
			--refresh invalid train objects
			if trainInfo.train == nil or not trainInfo.train.valid then
				trainInfo.train = getTrainFromLocomotives(trainInfo.locomotives)
				trainInfo.locomotives = getLocomotives(trainInfo.train)
				if isTrainInfoDuplicate(trains, trainInfo, i) then
					trainInfo.train = nil
				end
			end
			
			if (trainInfo.train == nil or not trainInfo.train.valid) then
				
				table.remove(trains, i)
			else
				trainInfo.locomotives = getLocomotives(trainInfo.train)
				updateTrainInfo(trainInfo, game.tick)
				--debugLog(trainInfo.train.state)
			end
		end
	--end
end

function updateTrainInfoIfChanged(trainInfo, field, value) 
	if trainInfo ~= nil and field ~= nil and trainInfo[field] ~= value then
		trainInfo[field] = value
		trainInfo.updated = true
		return true
	end
	return false
end

function updateTrainInfo(trainInfo, tick)
	if trainInfo ~= nil then
		trainInfo.updated = false
	
		if trainInfo.lastState == nil or trainInfo.lastState ~= trainInfo.train.state then
			trainInfo.updated = true
			if trainInfo.train.state == 7 then
				trainInfo.lastStateStation = tick
			end
			trainInfo.lastState = trainInfo.train.state
			trainInfo.lastStateTick = tick
		end
		
		updateTrainInfoIfChanged(trainInfo, "manualMode", trainInfo.train.manual_mode)
		updateTrainInfoIfChanged(trainInfo, "speed", trainInfo.train.speed)
		
				--SET InventoryText (trainInfo.train.state == 9 or trainInfo.train.state == 7
		if (trainInfo.train.state == 7 or (trainInfo.train.state == 9 and trainInfo.train.speed == 0)) or not trainInfo.updatedInventory then
			local tempInventory = getHighestInventoryCount(trainInfo)
			trainInfo.updatedInventory = true
			if tempInventory ~= nil then
				updateTrainInfoIfChanged(trainInfo, "inventory", tempInventory)
			end
		end
		
		--SET CurrentStationText
		if trainInfo.train.schedule ~= nil and trainInfo.train.schedule.current ~= nil and trainInfo.train.schedule.current ~= 0 then
			if trainInfo.train.schedule.records[trainInfo.train.schedule.current] ~= nil then
				updateTrainInfoIfChanged(trainInfo, "currentStation", trainInfo.train.schedule.records[trainInfo.train.schedule.current].station)
			else
				updateTrainInfoIfChanged(trainInfo, "currentStation", "Auto")
			end
		end
		

		if trainInfo.train.schedule ~= nil and trainInfo.train.schedule.records ~= nil and trainInfo.train.schedule.records[1] ~= nil then
			trainInfo.stations = {}
			-- if trainInfo.stations == nil then
				
			-- end
			for i, record in ipairs(trainInfo.train.schedule.records) do
				trainInfo.stations[record.station] = true
			end
		else
			trainInfo.stations = nil
		end
	end
end

function containsEntity(entityTable, entityA)
	if entityTable ~= nil and entityA ~= nil then
		for i, entityB in ipairs(entityTable) do
			if entityB ~= nil and entityB == entityA then
				return true
			end
		end
	end
	return false
end

function refreshTrainInfoGui(trains, guiSettings, character)
	local gui = guiSettings.fatControllerGui.trainInfo
	if gui ~= nil then
		local removeTrainInfo = {}
		
		local pageStart = ((guiSettings.page - 1) * guiSettings.displayCount) + 1
		debugLog("Page:" .. pageStart)
		
		local display = 0
		local filteredCount = 0
		
		for i, trainInfo in ipairs(trains) do
			local newGuiName = nil
			if display < guiSettings.displayCount then
				if guiSettings.activeFilterList == nil or trainInfo.matchesStationFilter then
					filteredCount = filteredCount + 1

					newGuiName = "Info" .. filteredCount
					if filteredCount >= pageStart then
						--removeGuiFromCount = removeGuiFromCount + 1
						display = display + 1
						if trainInfo.updated or gui[newGuiName] == nil then --trainInfo.guiName ~= newGuiName or
							trainInfo.guiName = newGuiName
							
							if gui[trainInfo.guiName] == nil then
								gui.add({ type="frame", name=trainInfo.guiName, direction="horizontal", style="fatcontroller_thin_frame"})
							end
							local trainGui = gui[trainInfo.guiName]
							
							
							--Add buttons
							if trainGui.buttons == nil then
								trainGui.add({type = "flow", name="buttons",  direction="horizontal", style="fatcontroller_traininfo_button_flow"})
							end

							if trainGui.buttons[trainInfo.guiName .. "_toggleManualMode"] == nil then
								trainGui.buttons.add({type="button", name=trainInfo.guiName .. "_toggleManualMode", caption="ll", style="fatcontroller_button_style"})
							end
							
							if trainInfo.manualMode then 
								--debugLog("Set >")
								trainGui.buttons[trainInfo.guiName .. "_toggleManualMode"].caption = ">"
							else
								--debugLog("Set ll")
								trainGui.buttons[trainInfo.guiName .. "_toggleManualMode"].caption = "ll"
							end
							
							
							if trainGui.buttons[trainInfo.guiName .. "_toggleFollowMode"] == nil then
								trainGui.buttons.add({type="button", name=trainInfo.guiName .. "_toggleFollowMode", caption={"text-controlbutton"}, style="fatcontroller_button_style"})
							end
							

							--Add info
							if trainGui.info == nil then
								trainGui.add({type = "flow", name="info",  direction="vertical", style="fatcontroller_thin_flow"})
							end
							
							if trainGui.info.topInfo == nil then
								trainGui.info.add({type="label", name="topInfo", style="fatcontroller_label_style"})
							end
							if trainGui.info.bottomInfo == nil then
								trainGui.info.add({type="label", name="bottomInfo", style="fatcontroller_label_style"}) 
							end
							
							local topString = ""
							local station = trainInfo.currentStation
							if station == nil then station = "" end
							if trainInfo.lastState ~= nil then
								if trainInfo.lastState == 1  or trainInfo.lastState == 3 then
									topString = "No Path "-- .. trainInfo.lastState
								elseif trainInfo.lastState == 2 then
									topString = "Stopped"
								elseif trainInfo.lastState == 5 then
									topString = "Signal || " .. station
								elseif trainInfo.lastState == 8  or trainInfo.lastState == 9   or trainInfo.lastState == 10 then
									topString = "Manual" 
									if trainInfo.speed == 0 then
										topString = topString .. ": " .. "Stopped" -- REPLACE WITH TRANSLAION
									else
										topString = topString .. ": " .. "Moving" -- REPLACE WITH TRANSLAION
									end
								elseif trainInfo.lastState == 7 then
									topString = "Station || " .. station
								else
									topString = "Moving -> " .. station
								end
							end
							
							local bottomString = ""
							
							if trainInfo.inventory ~= nil then
								bottomString = trainInfo.inventory
							else
								bottomString = ""
							end
							
							if guiSettings.alarm ~= nil and trainInfo.alarm then
								topString = "! " .. topString
							end
							
							trainGui.info.topInfo.caption = topString
							trainGui.info.bottomInfo.caption = bottomString
						end
						
						-- if character ~= nil and containsEntity(trainInfo.locomotives, character.opened) then --character.opened ~= nil and
							-- gui[newGuiName].buttons[trainInfo.guiName .. "_removeTrain"].style = "fatcontroller_selected_button"
						-- else
							-- --debugLog("Failed: " .. i)
							-- gui[newGuiName].buttons[trainInfo.guiName .. "_removeTrain"].style = "fatcontroller_button_style"
						-- end
						
						if character ~= nil and character.name == "fatcontroller" and containsEntity(trainInfo.locomotives, character.vehicle) then
							gui[newGuiName].buttons[newGuiName .. "_toggleFollowMode"].style = "fatcontroller_selected_button"
							gui[newGuiName].buttons[newGuiName .. "_toggleFollowMode"].caption = "X"
						else
							gui[newGuiName].buttons[newGuiName .. "_toggleFollowMode"].style = "fatcontroller_button_style"
							gui[newGuiName].buttons[newGuiName .. "_toggleFollowMode"].caption = "c"
						end
						
					end
				end
			end
			
			trainInfo.guiName = newGuiName
		end
	end
end

function filterTrainInfoList(trains, activeFilterList)
	--if trains ~= nil  then
		for i,trainInfo in ipairs(trains) do
			if activeFilterList ~= nil then
				trainInfo.matchesStationFilter = matchStationFilter(trainInfo, activeFilterList) 
			else
				trainInfo.matchesStationFilter = true
			end
		end

	--end
	
end

function matchStationFilter(trainInfo, activeFilterList)
	local fullMatch = false
	if trainInfo ~= nil and trainInfo.stations ~= nil then
		for filter, value in pairs(activeFilterList) do
			if trainInfo.stations[filter] then
				fullMatch = true
			else 
				return false
			end
		end
	end
	
	return fullMatch
end

-- function findTrainInfoFromEntity(trains, entity)
	-- for i, trainInfo in ipairs(trains) do
		-- if train ~= nil and train.valid and train.carriages[1] ~= nil and trainInfo ~= nil and trainInfo.train.carriages[1] ~= nil and entity.equals(trainB.train.carriages[1]) then
			-- return trainInfo
		-- end
	-- end
-- end

function trainInList(trains, train)
	for i, trainInfo in ipairs(trains) do
		if train ~= nil and train.valid and train.carriages[1] ~= nil and trainInfo ~= nil and trainInfo.train ~= nil and trainInfo.train.valid and trainInfo.train.carriages[1] ~= nil and train.carriages[1] == trainInfo.train.carriages[1] then
			return true
		end
	end
	return false
end

-- function addNewTrainGui(gui, train)
	-- if train ~= nil and train.valid and train.carriages[1] ~= nil and train.carriages[1].valid then
		-- if gui.toggleTrain ~= nil then
			-- gui.toggleTrain.destroy()
		-- end
		
	-- end
-- end

function matchStringInTable(stringA, tableA)
	for i, stringB in ipairs(tableA) do
		if stringA == stringB then
			return true
		end
	end
	return false
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function debugLog(message)
	if true then -- set for debug
		for i,player in ipairs(game.players) do
			player.print(message)
		end
	end
end

function endsWith(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function startsWith(String,Start)
	debugLog(String)
	debugLog(Start)
   return string.sub(String,1,string.len(Start))==Start
end

function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
			else return a[i], t[a[i]]
		end
	end
	return iter
end