----------------------------------------------------------------------------------------------------------------------------
local g_DoWorldWonder = nil;
local ThreeStrikesID = GameInfo.UnitPromotions["PROMOTION_THREE_STRIKES"].ID
local MountedUnitID = GameInfo.UnitPromotions["PROMOTION_KNIGHT_COMBAT"].ID

function WorldWonderStarted(iType, iPlotX, iPlotY)
	if iType == GameInfoTypes["BATTLETYPE_MELEE"]
	or iType == GameInfoTypes["BATTLETYPE_RANGED"]
	or iType == GameInfoTypes["BATTLETYPE_AIR"]
	or iType == GameInfoTypes["BATTLETYPE_SWEEP"]
	then
		g_DoWorldWonder = {
			attPlayerID = -1,
			attUnitID   = -1,
			defPlayerID = -1,
			defUnitID   = -1,
			attODamage  = 0,
			defODamage  = 0,
			PlotX = iPlotX,
			PlotY = iPlotY,
			bIsCity = false,
			defCityID = -1,
			battleType = iType,
		};
		--print("战斗开始.")
	end
end
GameEvents.BattleStarted.Add(WorldWonderStarted);
----------------------------------------------------------------------------------------------------------------------------
function WorldWonderJoined(iPlayer, iUnitOrCity, iRole, bIsCity)
	if g_DoWorldWonder == nil
	or Players[ iPlayer ] == nil or not Players[ iPlayer ]:IsAlive()
	or (not bIsCity and Players[ iPlayer ]:GetUnitByID(iUnitOrCity) == nil)
	or (bIsCity and (Players[ iPlayer ]:GetCityByID(iUnitOrCity) == nil or iRole == GameInfoTypes["BATTLEROLE_ATTACKER"]))
	or iRole == GameInfoTypes["BATTLEROLE_BYSTANDER"]
	then
		return;
	end
	if bIsCity then
		g_DoWorldWonder.defPlayerID = iPlayer;
		g_DoWorldWonder.defCityID = iUnitOrCity;
		g_DoWorldWonder.bIsCity = bIsCity;
	elseif iRole == GameInfoTypes["BATTLEROLE_ATTACKER"] then
		g_DoWorldWonder.attPlayerID = iPlayer;
		g_DoWorldWonder.attUnitID = iUnitOrCity;
		g_DoWorldWonder.attODamage = Players[ iPlayer ]:GetUnitByID(iUnitOrCity):GetDamage();
	elseif iRole == GameInfoTypes["BATTLEROLE_DEFENDER"] or iRole == GameInfoTypes["BATTLEROLE_INTERCEPTOR"] then
		g_DoWorldWonder.defPlayerID = iPlayer;
		g_DoWorldWonder.defUnitID = iUnitOrCity;
		g_DoWorldWonder.defODamage = Players[ iPlayer ]:GetUnitByID(iUnitOrCity):GetDamage();
	end
	
	-- Prepare for Capture Unit!
	if not bIsCity and g_DoWorldWonder.battleType == GameInfoTypes["BATTLETYPE_MELEE"]
	and Players[g_DoWorldWonder.attPlayerID] ~= nil and Players[g_DoWorldWonder.attPlayerID]:GetUnitByID(g_DoWorldWonder.attUnitID) ~= nil
	and Players[g_DoWorldWonder.defPlayerID] ~= nil and Players[g_DoWorldWonder.defPlayerID]:GetUnitByID(g_DoWorldWonder.defUnitID) ~= nil
	then
		local attPlayer = Players[g_DoWorldWonder.attPlayerID];
		local attUnit   = attPlayer:GetUnitByID(g_DoWorldWonder.attUnitID);
		local defPlayer = Players[g_DoWorldWonder.defPlayerID];
		local defUnit   = defPlayer:GetUnitByID(g_DoWorldWonder.defUnitID);


		if attUnit:GetCaptureChance(defUnit) > 0 then
			local unitClassType = defUnit:GetUnitClassType();
			local unitPlot = defUnit:GetPlot();
			local unitOriginalOwner = defUnit:GetOriginalOwner();
		
			local sCaptUnitName = nil;
			if defUnit:HasName() then
				sCaptUnitName = defUnit:GetNameNoDesc();
			end
			
			local unitLevel = defUnit:GetLevel();
			local unitEXP   = attUnit:GetExperience();
			local attMoves = attUnit:GetMoves();
			print("attacking Unit remains moves:"..attMoves);
		
			tCaptureSPUnits = {unitClassType, unitPlot, g_DoWorldWonder.attPlayerID, unitOriginalOwner, sCaptUnitName, unitLevel, unitEXP, attMoves};
		end
	end
end
GameEvents.BattleJoined.Add(WorldWonderJoined);
----------------------------------------------------------------------------------------------------------------------------
function WorldWonderEffect()
 	 --Defines and status checks
	if g_DoWorldWonder == nil or Players[ g_DoWorldWonder.defPlayerID ] == nil
	or Players[ g_DoWorldWonder.attPlayerID ] == nil or not Players[ g_DoWorldWonder.attPlayerID ]:IsAlive()
	or Players[ g_DoWorldWonder.attPlayerID ]:GetUnitByID(g_DoWorldWonder.attUnitID) == nil
	-- or Players[ g_DoWorldWonder.attPlayerID ]:GetUnitByID(g_DoWorldWonder.attUnitID):IsDead()
	or Map.GetPlot(g_DoWorldWonder.PlotX, g_DoWorldWonder.PlotY) == nil
	then
		return;
	end
	
	local attPlayerID = g_DoWorldWonder.attPlayerID;
	local attPlayer = Players[ attPlayerID ];
	local defPlayerID = g_DoWorldWonder.defPlayerID;
	local defPlayer = Players[ defPlayerID ];
	
	local attUnit = attPlayer:GetUnitByID(g_DoWorldWonder.attUnitID);
	local attPlot = attUnit:GetPlot();
	
	local plotX = g_DoWorldWonder.PlotX;
	local plotY = g_DoWorldWonder.PlotY;
	local batPlot = Map.GetPlot(plotX, plotY);
	local batType = g_DoWorldWonder.battleType;
	
	local bIsCity = g_DoWorldWonder.bIsCity;
	local defUnit = nil;
	local defPlot = nil;
	local defCity = nil;
	
	local attFinalUnitDamage = attUnit:GetDamage();
	local defFinalUnitDamage = 0;
	local attUnitDamage = attFinalUnitDamage - g_DoWorldWonder.attODamage;
	local defUnitDamage = 0;
	
	if not bIsCity and defPlayer:GetUnitByID(g_DoWorldWonder.defUnitID) then
		defUnit = defPlayer:GetUnitByID(g_DoWorldWonder.defUnitID);
		defPlot = defUnit:GetPlot();
		defFinalUnitDamage = defUnit:GetDamage();
		defUnitDamage = defFinalUnitDamage - g_DoWorldWonder.defODamage;
	elseif bIsCity and defPlayer:GetCityByID(g_DoWorldWonder.defCityID) then
		defCity = defPlayer:GetCityByID(g_DoWorldWonder.defCityID);
	end
	
	g_DoWorldWonder = nil;
		--Complex Effects Only for Human VS AI(reduce time and enhance stability)
	if not attPlayer:IsHuman() and not defPlayer:IsHuman() then
		return;
	end

	-- Not for Barbarins
	if attPlayer:IsBarbarian() then
		return;
	end

	------织田铁炮队“马栅”	
	if not bIsCity and defUnit:IsHasPromotion(ThreeStrikesID) and attUnit:GetDomainType() == DomainTypes.DOMAIN_LAND and attUnit:IsHasPromotion(MountedUnitID) then
			attUnit:SetMoves(0)
			print ("Attacker Stopped!")	
			if defPlayer:IsHuman() then
				Events.GameplayAlertMessage( Locale.ConvertTextKey( "TXT_KEY_THREE_STRIKES_LOST_MOVEMENT", attUnit:GetName(), defUnit:GetName()))
			end
			if attPlayer:IsHuman() then
				Events.GameplayAlertMessage( Locale.ConvertTextKey( "TXT_KEY_THREE_STRIKES_LOST_MOVEMENT_ATT", attUnit:GetName(), defUnit:GetName()))
			end	
	end
	
end
GameEvents.BattleFinished.Add(WorldWonderEffect)
----------------------------------------------------------------------------------------------------------------------------
-- Unit death cause population loss -- MOD by CaptainCWB
function UnitDeathCounter(iKerPlayer, iKeePlayer, eUnitType)
	if (PreGame.GetGameOption("GAMEOPTION_SP_CASUALTIES") == 0) then
		print("War Casualties - OFF!");
		return;
	end
	
	if Players[iKeePlayer] == nil or not Players[iKeePlayer]:IsAlive() or Players[iKeePlayer]:GetCapitalCity() == nil
	or Players[iKeePlayer]:IsMinorCiv() or Players[iKeePlayer]:IsBarbarian()
	or GameInfo.Units[eUnitType] == nil
	-- UnCombat units do not count
	or(GameInfo.Units[eUnitType].Combat == 0 and GameInfo.Units[eUnitType].RangedCombat == 0)
	then
		return;
	end
	
	local defPlayer = Players[iKeePlayer];
	local iCasualty = defPlayer:GetCapitalCity():GetNumBuilding(GameInfoTypes["BUILDING_WAR_CASUALTIES"]);
	local sUnitType = GameInfo.Units[eUnitType].Type;
	local iDCounter = 6;
	
	if     GameInfo.Unit_FreePromotions{ UnitType = sUnitType, PromotionType = "PROMOTION_NO_CASUALTIES" }() then
		print ("This unit won't cause Casualties!");
		return;
	elseif GameInfo.Unit_FreePromotions{ UnitType = sUnitType, PromotionType = "PROMOTION_HALF_CASUALTIES" }() then
		iDCounter = iDCounter/2;
	end
	if defPlayer:HasPolicy(GameInfo.Policies["POLICY_CENTRALISATION"].ID) then
		iDCounter = 2*iDCounter/3;
	end
	
	print ("DeathCounter(Max-12): ".. iCasualty .. " + " .. iDCounter);
	if iCasualty + iDCounter < 12 then
		defPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes["BUILDING_WAR_CASUALTIES"], iCasualty + iDCounter);
	else
		defPlayer:GetCapitalCity():SetNumRealBuilding(GameInfoTypes["BUILDING_WAR_CASUALTIES"], 0);
		local PlayerCitiesCount = defPlayer:GetNumCities();
		if PlayerCitiesCount <= 0 then ---- In case of 0 city error
			return;
		end
		local apCities = {};
		local iCounter = 0;
		
		for pCity in defPlayer:Cities() do
			local cityPop = pCity:GetPopulation();
			if ( cityPop > 1 and defPlayer:IsHuman() ) or cityPop > 5 then
				apCities[iCounter] = pCity
				iCounter = iCounter + 1
			end
		end
		
		if (iCounter > 0) then
			local iRandChoice = Game.Rand(iCounter, "Choosing random city")
			local targetCity = apCities[iRandChoice]
			local Cityname = targetCity:GetName()
			local iX = targetCity:GetX();
			local iY = targetCity:GetY();
			
			if targetCity:GetPopulation() > 1 then
				targetCity:ChangePopulation(-1, true)
				print ("population lost!"..Cityname)
			else 
				return;
			end
			if defPlayer:IsHuman() then
				local text = Locale.ConvertTextKey("TXT_KEY_SP_NOTE_POPULATION_LOSS",targetCity:GetName())
				local heading = Locale.ConvertTextKey("TXT_KEY_SP_NOTE_POPULATION_LOSS_SHORT")
				defPlayer:AddNotification(NotificationTypes.NOTIFICATION_STARVING, text, heading, iX, iY)
			end
		end
	end
end
----------------------------------------------------------------------------------------------------------------------------