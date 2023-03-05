local function convert(num)
	if string.find(num, "^0%.") then
		num = ((tonumber(num*100) * 10 + (2^52 + 2^51)) - (2^52 + 2^51)) / (10).."%";
	else
		num = string.match(num + (2^52 + 2^51) - (2^52 + 2^51), "(.-)%.");
	end
	return num
end

local function levelUp(num)
	currentLevel = currentLevel+1;
	Artifact["StatRoll"][num]=math.random(#Artifact.SubStat[num].ID);
	Artifact["StatList"][num][currentLevel]={
		["ID"]=Artifact.SubStat[num].ID[Artifact.StatRoll[num]],
		["Type"]=Artifact.SubStat[num].Type,
		["Value"]=Artifact.SubStat[num].Value[Artifact.StatRoll[num]],
	};
end

local function backupStat()
	Artifact["DefaultStat"]={
		[0]={
			["ID"]=Artifact["StatList"][0]["ID"],
			["Type"]=Artifact["StatList"][0]["Type"],
		},
		[1]={
			["ID"]=Artifact["StatList"][1]["ID"],
			["Type"]=Artifact["StatList"][1]["Type"],
			["Value"]=Artifact["StatList"][1]["Value"],
		},
		[2]={
			["ID"]=Artifact["StatList"][2]["ID"],
			["Type"]=Artifact["StatList"][2]["Type"],
			["Value"]=Artifact["StatList"][2]["Value"],
		},
		[3]={
			["ID"]=Artifact["StatList"][3]["ID"],
			["Type"]=Artifact["StatList"][3]["Type"],
			["Value"]=Artifact["StatList"][3]["Value"],
		},
		[4]={
			["ID"]=Artifact["StatList"][4]["ID"],
			["Type"]=Artifact["StatList"][4]["Type"],
			["Value"]=Artifact["StatList"][4]["Value"],
		},
	};
end

local function resetLevel(cond)
	currentLevel = nil; ArtSubStat = nil;
	if cond == true then
		Artifact["StatList"] = Artifact["DefaultStat"];
	end
end

local function InvalidResponse()
	Alert = gg.alert("You didn't choose anything!\n\nDo you want to exit?", "Continue", "Minimize", "Exit");
	if Alert == 2 then gg.setVisible(false);
		while true do
			if gg.isVisible(true) then break
			else 
				gg.sleep(1);
			end
		end
	elseif Alert == 3 then
		os.exit();
	end
end

::getResource::
	if res then
		resFile = gg.EXT_CACHE_DIR.."/"..math.random(1,999999);
	else
		resFile = gg.EXT_CACHE_DIR.."/GIArtifact";
	end
	if not io.open(resFile) then
		local getRes = gg.makeRequest("https://raw.githubusercontent.com/Fathoni267/GIArtifact/main/resources.lua")["content"];
		if getRes then
			if string.match(getRes, "^return") then
				io.output(resFile):write(getRes);
			end
		end
		if not io.open(resFile) then
			gg.alert("Unable to access the resources!");
			os.exit();
		end
		if res then
			os.remove(gg.EXT_CACHE_DIR.."/GIArtifact");
			os.rename(resFile, gg.EXT_CACHE_DIR.."/GIArtifact");
		end
		res = nil; goto getResource;
	else
		res = load(io.input(resFile):read("*all"))();
	end

::getChoice::
	List = {};
	for x = 1, #res.Artifacts do
		List[x] = "•"..res.Artifacts[x].Name;
	end
	List[#List+1] = "Sync resource file";
	ArtifactResult = gg.choice(List, nil, "Choose Artifact:");
	if not ArtifactResult then InvalidResponse(); goto getChoice;
	elseif ArtifactResult == #List then
		goto getResource;
	end

::getType::
	List = {};
	for x = 1, 5 do
		List[x] = "•"..res.Artifacts[ArtifactResult].Type[x];
	end
	List[#List+1] = "↩️Back";
	TypeResult = gg.choice(List);
	if not TypeResult then InvalidResponse(); goto getType;
	elseif TypeResult == #List then
		goto getChoice;
	end

::getMainStat::
	if TypeResult <= 2 then MSResult = 1;
	else
		List = {};
		for x = 1, #res.Mainstats[TypeResult].Name do
			List[x] = "•"..res.Mainstats[TypeResult].Name[x];
		end
		List[#List+1] = "↩️Back";
		MSResult = gg.choice(List);
		if not MSResult then InvalidResponse(); goto getMainStat;
		elseif MSResult == #List then
			goto getType;
		end
	end

::makeArtRes::
	Artifact = {
		["ID"] = res.Artifacts[ArtifactResult].ID[TypeResult],
		["Name"] = res.Artifacts[ArtifactResult].Name,
		["Type"] = res.Artifacts[ArtifactResult].Type[TypeResult],
		["MainStat"] = res.Mainstats[TypeResult],
		["SubStat"] = {},
		["StatRoll"] = {[0]=MSResult},
		["StatList"]={
			[0]={
				["ID"] = res.Mainstats[TypeResult].ID[MSResult],
				["Type"] = res.Mainstats[TypeResult].Name[MSResult],
			},
		},
	};

::makeSubStat::
	for x = 1, 4 do 
		while true do
			Artifact["SubStat"][x]=res.Substats[math.random(#res.Substats)];
			Artifact["StatRoll"][x]=math.random(#Artifact.SubStat[x].ID);
			Artifact["StatList"][x]={
				["ID"]=Artifact.SubStat[x].ID[Artifact.StatRoll[x]],
				["Type"]=Artifact.SubStat[x].Type,
				["Value"]=Artifact.SubStat[x].Value[Artifact.StatRoll[x]],
			};
			for y = 1, x do
				if Artifact.StatList[x].Type == Artifact.StatList[y-1].Type then break
				elseif y == x then
					Status = "Passed";
				end
			end
			if Status == "Passed" then
				Status = false; break
			end
		end
	end
	
::rollSubStat::
	if not ArtSubStat then
		ArtSubStat = {}; 
		if not Artifact["defaultStat"] then backupStat(); end
	end
	for x = 1, 4 do
		if not currentLevel then
			ArtSubStat[x] = "•"..Artifact.SubStat[x].Type.."+"..convert(Artifact["StatList"][x].Value);
		elseif Artifact["StatList"][x][currentLevel] then
			Artifact["StatList"][x].Value = Artifact["StatList"][x].Value + Artifact["StatList"][x][currentLevel].Value;
			ArtSubStat[x] = ArtSubStat[x].." >> "..convert(Artifact["StatList"][x].Value);
		end
	end
	if not currentLevel then currentLevel = 0; end
	if currentLevel < 5 then
		ArtSubStat[5] = "🔄Reroll";
		ArtSubStat[6] = "↩️Back";
		SSResult = gg.choice(ArtSubStat, nil, Artifact["Name"].." | "..Artifact["Type"].."\n"..Artifact.StatList[0].Type);
		if not SSResult then InvalidResponse(); resetLevel(true); goto rollSubStat;
		elseif SSResult == 1 then
			levelUp(1); goto rollSubStat;
		elseif SSResult == 2 then
			levelUp(2); goto rollSubStat;
		elseif SSResult == 3 then
			levelUp(3); goto rollSubStat;
		elseif SSResult == 4 then
			levelUp(4); goto rollSubStat;
		elseif SSResult == 5 then 
			resetLevel(); goto makeArtRes;
		elseif SSResult == 6 then
			resetLevel(); goto getType;
		end
	end
	
::showResult::
	ArtResult = Artifact["Name"].." | "..Artifact["Type"].."\n"..Artifact.StatList[0].Type .."\n";
	for x = 1, 4 do
		ArtResult = ArtResult.."\n".. ArtSubStat[x]:match("^(.-%+)")..string.gsub(ArtSubStat[x], "%+.*%>%s", "+"):match(".*%+(.-)$");
	end
	ArtResult = gg.alert(ArtResult, "Copy", "↩️Back");
	if ArtResult == 0 then InvalidResponse(); goto showResult;
	elseif ArtResult == 1 then
		local command = "/g "..Artifact["ID"].." "..Artifact["StatList"][0].ID;
		for x = 1, 4 do
			command = command.." "..Artifact["StatList"][x].ID;
			for i = 1, 5 do
				if Artifact["StatList"][x][i] then
					command = command.." "..Artifact["StatList"][x][i].ID;
				end
			end
		end
		gg.copyText(command, false);
		print("Command copied!");
	elseif ArtResult == 2 then 
		resetLevel(true); goto rollSubStat;
	end
