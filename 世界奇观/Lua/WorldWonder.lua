include("PlotIterators.lua")
include("UtilityFunctions.lua")
----------------------------------------------------------------------------------------------------------------------------
function WorldWonderBonus(playerID)
	local player = Players[playerID]
	
	
	if player == nil then
		print ("No players")
		return
	end
	
	if player:IsBarbarian() or player:IsMinorCiv() then
		print ("Minors are Not available!")
    	return
	end
	
	if player:GetNumCities() <= 0 then 
		print ("No Cities!")
		return
	end
	
	if player:CountNumBuildings(GameInfoTypes["BUILDING_BANAUE"]) > 0 and 
	not player:HasPolicy(GameInfo.Policies["POLICY_BANAUE"].ID) 
	then 
		player:SetNumFreePolicies(1)
		player:SetNumFreePolicies(0)
		player:SetHasPolicy(GameInfo.Policies["POLICY_BANAUE"].ID,true)	 
		print("Player has wonder 1! Give them policy 1!")
	end

	for city in player:Cities() do
		if city:IsHasBuilding(GameInfoTypes["BUILDING_GIFU"]) and 
        not city:IsHasBuilding(GameInfoTypes["BUILDING_JAPANESE_TENSHU"]) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_JAPANESE_TENSHU"], 1) 
			print("给予一座天守")
		end
	end
	for city in player:Cities() do
		if city:IsHasBuilding(GameInfoTypes["BUILDING_MADOL"]) and 
        not city:IsHasBuilding(GameInfoTypes["BUILDING_DUTCH_GRACHTENGORDEL"]) then
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_DUTCH_GRACHTENGORDEL"], 1) 
			print("给予一座运河网")
		end
	end
	
end--function END
GameEvents.PlayerDoTurn.Add(WorldWonderBonus)
----------------------------------------------------------------------------------------------------------------------------
-- 库加塔田园牧歌快乐加成
----------------------------------------------------------------------------------------------------------------------------
function JFD_GetNumberWorkedPastoral(playerID, city)
	local numWorkedPastoral = 0
    if city:IsHasBuilding(GameInfoTypes["BUILDING_KUJATAA"]) then
	    for cityPlot = 0, city:GetNumCityPlots() - 1, 1 do
	    	local plot = city:GetCityIndexPlot(cityPlot)
	    	if plot then
	    		if plot:GetOwner() == playerID then
	    			if city:IsWorkingPlot(plot) then	
	    				if plot:GetImprovementType() == GameInfoTypes["IMPROVEMENT_FARM"] then 
	    					numWorkedPastoral = numWorkedPastoral + 1
	    				end
						if plot:GetImprovementType() == GameInfoTypes["IMPROVEMENT_PASTURE"] then 
	    					numWorkedPastoral = numWorkedPastoral + 1
	    				end
	    			end
	    		end
	    	end
        end
	end
	
	return numWorkedPastoral
end
	
function PastoralHappiness(playerID)
	local player = Players[playerID]
	if player:IsAlive() then
		for city in player:Cities() do
			city:SetNumRealBuilding(GameInfoTypes["BUILDING_PASTORAL_BOUNS"], JFD_GetNumberWorkedPastoral(playerID, city))
		end
	end
end
GameEvents.PlayerDoTurn.Add(PastoralHappiness)
----------------------------------------------------------------------------------------------------------------------------
-- 巴米扬大佛靠近山脉额外加成
----------------------------------------------------------------------------------------------------------------------------
  local pDirection_types = {
		    DirectionTypes.DIRECTION_NORTHEAST,
		    DirectionTypes.DIRECTION_EAST,
		    DirectionTypes.DIRECTION_SOUTHEAST,
		    DirectionTypes.DIRECTION_SOUTHWEST,
		    DirectionTypes.DIRECTION_WEST,
		    DirectionTypes.DIRECTION_NORTHWEST
		  };

function BamiyanCompleted(iPlayer, iCity, iBuilding, bGold, bFaithOrCulture)      
		if iBuilding == GameInfoTypes["BUILDING_BAMIYAN"] then
		 local pPlayer = Players[iPlayer]
		 local pCity = pPlayer:GetCityByID(iCity)
		local pCentralPlot = pCity:Plot()
		 for loop, direction in ipairs(pDirection_types) do
		      local pAdjacentPlot = Map.PlotDirection(pCentralPlot:GetX(), pCentralPlot:GetY(), direction);
		      if (pAdjacentPlot ~= nil and pAdjacentPlot:IsMountain()) then
				pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_BAMIYAN_BONUS"], 1)
			end
		end
	end
end
GameEvents.CityConstructed.Add(BamiyanCompleted)
----------------------------------------------------------------------------------------------------------------------------
-- 卡纳克神庙：建造前提冲击平原、绿洲地貌
----------------------------------------------------------------------------------------------------------------------------
function KarnakCheck(iPlayer, iCity, iBuilding)
if (iBuilding == GameInfoTypes.BUILDING_KARNAK) then
   local pPlayer = Players[iPlayer]
   local pCity = Players[iPlayer]:GetCityByID(iCity)
    for i = 0, pCity:GetNumCityPlots() - 1, 1 do
	local pPlot = pCity:GetCityIndexPlot(i)
	if pPlot:GetOwner() == iPlayer and (pPlot:GetFeatureType() ==GameInfoTypes.FEATURE_FLOOD_PLAINS) or (pPlot:GetFeatureType() ==GameInfoTypes.FEATURE_OASIS) then	
     return true
	        end  
		 end   
	 return false
	  end
	  return true
 end
GameEvents.CityCanConstruct.Add(KarnakCheck)
----------------------------------------------------------------------------------------------------------------------------