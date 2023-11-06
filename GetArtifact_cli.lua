local function choice(list, header)
	if header then
		print(header);
	end
	for i, choose in ipairs(list) do
		print("["..i.."]", choose);
	end
	local result = io.read();
	for x = 1, #list do
		if result and result == ""..x.."" then
			result = tonumber(result);
		end
	end
	print("***")
	if type(result) == "number" and result <= #list then
		return result;
	elseif type(result) == "nil" then
		os.exit();
	end
end

local function convert(num)
	if string.find(num, "^0%.") then
		num = ((tonumber(num*100) * 10 + (2^52 + 2^51)) - (2^52 + 2^51)) / (10).."%";
	else
		num = string.match(num + (2^52 + 2^51) - (2^52 + 2^51), "(.-)%.");
	end
	return num;
end

local function levelUp(num)
	Artifact["Level"] = Artifact["Level"]+1;
	Artifact["StatRoll"][num]=math.random(#Artifact.SubStat[num].ID);
	Artifact["StatList"][num][Artifact.Level]={
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
		}
	};
	for i = 1, 4 do
		Artifact["DefaultStat"][i]={
			["ID"]=Artifact["StatList"][i]["ID"],
			["Type"]=Artifact["StatList"][i]["Type"],
			["Value"]=Artifact["StatList"][i]["Value"],
		};
	end
end

local function resetLevel(cond)
	Artifact["Level"], ArtSubStat = nil;
	if cond then
		Artifact["StatList"] = Artifact.DefaultStat;
	end
end

::getResource::
	if res then
		resFile = ".cache/.giart"..os.time();
	else
		resFile = ".cache/GIArtifact";
	end
	if not io.open(resFile) then
		local getRes, status = require("socket.http").request("https://raw.githubusercontent.com/feddryx/GIArtifact/main/resources.lua");
		if status == 200 then
			if string.match(getRes, "^return") then
				io.output(resFile):write(getRes);
				io.close();
			end
		end
		if not io.open(resFile) then
			print("Unable to access the resources!");
			os.exit();
		end
		if res then
			os.remove(".cache/GIArtifact");
			os.rename(resFile, ".cache/GIArtifact");
		end
		res = nil; goto getResource;
	else
		res = loadfile(resFile)();
	end

::getChoice::
	List = {};
	for x = 1, #res.Artifacts do
		List[x] = "•"..res.Artifacts[x].Name;
	end
	List[#List+1] = "Sync resource file";
	List[#List+1] = "Exit";
	ArtResult = choice(List, "\nChoose Artifact:");
	if not ArtResult then goto getChoice;
	elseif ArtResult == #List-1 then
		goto getResource;
	elseif ArtResult == #List then
		os.exit();
	end

::getType::
	List = {};
	for x = 1, 5 do
		List[x] = "•"..res.Mainstats[x].Type;
	end
	List[#List+1] = "<--Back";
	TypeResult = choice(List);
	if not TypeResult then goto getType;
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
		List[#List+1] = "<--Back";
		MSResult = choice(List);
		if not MSResult then goto getMainStat;
		elseif MSResult == #List then
			goto getType;
		end
	end

::makeArtRes::
	Artifact = {
		["ID"] = res.Artifacts[ArtResult].ID[TypeResult],
		["Name"] = res.Artifacts[ArtResult].Name,
		["Type"] = res.Mainstats[TypeResult].Type,
		["SubStat"] = {},
		["StatRoll"] = {[0]=MSResult},
		["StatList"] = {
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
				Status = nil; break
			end
		end
	end
	
::rollSubStat::
	if not ArtSubStat then
		ArtSubStat = {}; backupStat();
	end
	for x = 1, 4 do
		if not Artifact.Level then
			ArtSubStat[x] = "•"..Artifact.SubStat[x].Type.."+"..convert(Artifact["StatList"][x].Value);
		elseif Artifact["StatList"][x][Artifact.Level] then
			Artifact["StatList"][x].Value = Artifact["StatList"][x].Value + Artifact["StatList"][x][Artifact.Level].Value;
			ArtSubStat[x] = ArtSubStat[x].." >> "..convert(Artifact["StatList"][x].Value);
		end
	end
	if not Artifact.Level then Artifact["Level"] = 0; end
	if Artifact.Level < 5 then
		ArtSubStat[5] = "↹Reroll"; ArtSubStat[6] = "<--Back";
		SSResult = choice(ArtSubStat, Artifact["Name"].." | "..Artifact["Type"].."\n"..Artifact.StatList[0].Type);
		if not SSResult then resetLevel(true); goto rollSubStat;
		elseif SSResult >= 1 and SSResult <= 4 then
			levelUp(SSResult); goto rollSubStat;
		elseif SSResult == 5 then 
			resetLevel(); goto makeSubStat;
		elseif SSResult == 6 then
			resetLevel(); goto getType;
		end
	end
	
::showResult::
	Prompt = Artifact["Name"].." | "..Artifact["Type"].."\n"..Artifact.StatList[0].Type.."\n";
	for x = 1, 4 do
		Prompt = Prompt.."\n"..ArtSubStat[x]:match("^(.-%+)")..string.gsub(ArtSubStat[x], "%+.*%>%s", "+"):match(".*%+(.-)$");
	end
	ResultChoices = choice({"Get Command", "Back"}, Prompt);
	if not ResultChoices then goto showResult;
	elseif ResultChoices == 1 then
		Artifact["command"] = "/g "..Artifact["ID"].." lv21 "..Artifact["StatList"][0].ID;
		for x = 1, 4 do
			Artifact["command"] = Artifact["command"].." "..Artifact["StatList"][x].ID;
			for i = 1, 5 do
				if Artifact["StatList"][x][i] then
					Artifact["command"] = Artifact["command"].." "..Artifact["StatList"][x][i].ID;
				end
			end
		end
		print("Command: " .. Artifact.command);
	elseif ResultChoices == 2 then 
		resetLevel(true); goto rollSubStat;
	end
