TOOL.Category		= "Construction"
TOOL.Name			= "#E2converter"
TOOL.Command		= nil
TOOL.SelectItem	= {}

TOOL.ClientConVar["radius"] = "64"

if (CLIENT) then

    local function  PosAngToString(p)
        return  p[1]..","..p[2]..","..p[3]
    end
	
    local function joun(strng_u , table)
		local str_ = "";
		for it, item in pairs(table) do
			str_ = str_ .. item .. strng_u or " "
		end
		return str_
	end
	local function timeToStr( time )
		local tmp = time
		local s = tmp % 60
		tmp = math.floor( tmp / 60 )
		local m = tmp % 60
		tmp = math.floor( tmp / 60 )
		local h = tmp % 24
		tmp = math.floor( tmp / 24 )
		local d = tmp % 7
		local w = math.floor( tmp / 7 )

		return string.format( "%02iw_%id_%02ih_%02im_%02is", w, d, h, m, s )
	end
	language.Add("tool.E2_holo.name", "E2converter")
	language.Add("tool.E2_holo.desc", " null 1")	
	language.Add("tool.E2_holo.0", " null 2")
	language.Add("tool.E2_holo.radius", "Radius")
	
	language.Add( "Tool.E2_holo.left_0", "Select/Deselect" )
	language.Add( "Tool.E2_holo.right_0", "Convert" )
	language.Add( "Tool.E2_holo.reload_0", "Clear selection" )

	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "" },
		{ name = "right_0", stage = 0, text = "" },
		{ name = "reload_0", stage = 0, text = "" },
		
	}
	
    local dir_ = "expression2/E2holoConvert" -- data 
    net.Receive("E2converter_file_d",function (len,ply)   
        local table_entity = net.ReadTable()
        local local_ent =   net.ReadTable()
        local name_file = dir_ .. "/" ..timeToStr( math.floor(SysTime ()))  ..".txt"
        local t_4 =  "\t"

        file.CreateDir( dir_ )
		local E2_code_s = {
			 "@name" , 
			 "@inputs" , 
			 "@outputs" , 
			 "@persist [Count]:number [DATA]:table IsHolo:number" , 
			 "#by UnderKo and KOT BACЬKA",
			 "if(first())" , "{",
			 "	IsHolo = 1",	 
			 "	holoCreate(0) holoParent(0,entity()) holoColor(0,vec4(0,0,0,0))",	 
			 "	holoPos(0,entity():toWorld(vec(0,0,10)))",
			 "	holoAng(0,ang())",
			 "	local Local_Entity = holoEntity(0)", 
			 
		}
		local E2_code_spawnh = 
[[
interval(100)
	if(IsHolo){
		while( (Count < DATA:count() + 1) && holoCanCreate()){
		local Tab = DATA[Count , table] 
		holoCreate(Count,Tab[1,vector] ,Tab[2,vector],Tab[3,angle],Tab[4,vector4])
		holoModel(Count,Tab[5,string]) holoParent(Count , holoEntity(0))
		if(Tab[6,string] != "null")
		{
			holoMaterial(Count,Tab[6,string])
		}
		Count++
	}    
} else { 
	while( (Count < DATA:count() + 1) && propCanSpawn()){
		local Tab = DATA[Count , table] 
		local E = propSpawn(Tab[5,string] , 1)
		if(Tab[6,string] != "null")
		{
			E:setMaterial(Tab[6,string])
		}
		E:setPos(Tab[1,vector])
		E:setAng(Tab[3,angle])
		Count++
	}
}
]]
		
        file.Append( name_file,joun("\n" , E2_code_s))
		
		for it, item in pairs(table_entity) do
            local local_position = item.position - local_ent.position
			if local_position == nill then 
				continue
			end
			-- holo  | Entity=holoCreate(number index,vector position,vector scale,angle ang,vector4 color)
			local E2_position =  "Local_Entity:toWorld(vec(" .. PosAngToString(local_position) ..  "))"
			local E2_v_scalse =  "vec(1)"
			local E2_angle    =  "ang("..PosAngToString( item.angle)..")"
			local E2_color    =  "vec4("..string.Replace(tostring(item.color), " ", ",")..")"
			local E2_model    = "\"null\""
			local E2_material    = "\"null\""
			if(string.len(item.model or "") >0) then 
				E2_model = "\""..item.model.."\""
			end
			if string.len(item.material) > 0 then
            	E2_material = "\""..item.material.."\""
			end
			local push_ = "	DATA:pushTable(table("..E2_position..","..E2_v_scalse..","..E2_angle..","..E2_color.."," .. E2_model..","..E2_material.."))\n" 

			file.Append( name_file, push_) 
          
        end 
        file.Append( name_file,"\n}\n") 
		file.Append( name_file,E2_code_spawnh)  
		RunConsoleCommand("wire_expression2_reloadeditor")
		chat.AddText(Color(255,255,255) , "[E2]: Save code: " .. name_file)
    end)
	net.Receive("E2converter_chat_text",function (len,ply)  		 
		chat.AddText(Color(255,255,255) , net.ReadString())
	end)
end

if SERVER then 
    util.AddNetworkString("E2converter_file_d")
	util.AddNetworkString("E2converter_chat_text")




	function SayPlayer(player , string_p)
		net.Start("E2converter_chat_text")
        	net.WriE2_code_sring(string_p)           
   	 	net.Send(player) 
	end
	local function FilterEntityTable(t)
		local filtered = {}
	
		for i, ent in ipairs(t) do
			if (not ent:IsWeapon()) and (not ent:IsPlayer()) then table.insert(filtered, ent) end
		end
	
		return filtered
	end

	
end

local function isAllowed( ply, ent )
	if ent:IsPlayer() or ent:IsWeapon() then return false end
	if CPPI then return ent:CPPICanTool(ply, "e2_holo") end
	return true
end

function TOOL.BuildCPanel(cp)
    cp:AddControl("Header", {Text = "#tool.e2_holo.name", Description = "Конвертирует пропы в холки."})
	cp:AddControl("Slider", { Label = "#tool.e2_holo.radius", Type = "int", Min = "64", Max = "1024", Command = "e2_holo_radius" } )
end

function TOOL:SelectEntity(ent, ply)
	if (!ent || !ent.IsValid || !ent:IsValid()) then return false end
	
    local item = {}
    item.entity = ent
    item.position = ent:GetPos()
    item.angle = ent:GetAngles()    
    item.model = ent:GetModel()
    item.material = ent:GetMaterial()
	item.color =  ent:GetColor()
	
	ent.TrueColor = ent:GetColor()
	
    ent:SetColor(Color(124, 90, 255, 255))
	
	ply.SelectItem = ply.SelectItem or {}
    table.insert(ply.SelectItem, item)
     
	return true
end

function TOOL:DeselectEntity(ent, ply)
	if (!ent || !ent.IsValid || !ent:IsValid()) then return false end
	
	ent:SetColor(ent.TrueColor)
	
	for it, item in ipairs(ply.SelectItem) do
		if (item.entity == ent) then
			table.remove(ply.SelectItem, it)
			return true	
		end
	end 
	
	return false
end

function TOOL:IsSelected(ent, ply)
	if not ply.SelectItem then return false end
	for _, item in pairs(ply.SelectItem) do
		if (item.entity == ent) then
			return true	
		end
	end
	
	return false
end

function TOOL:ClearSelection(ply)
	for _, item in pairs(ply.SelectItem) do
		if IsValid(item.entity) then
			item.entity:SetColor(Color(item.color.r, item.color.g, item.color.b, item.color.a))
		end
	end
	
 
	ply.SelectItem = {}
     
end

function TOOL:LeftClick( trace )
	
	if (!trace.Entity ) then return false end
	if (!trace.Entity:IsValid()) then return false end
	--if (trace.Entity:IsPlayer()) then return false end
	if not SERVER then return true end	
	local ply = self:GetOwner()
	local b = false
	if ply:KeyDown(IN_SPEED) then
		local sph = ents.FindInSphere(trace.HitPos, tonumber(self:GetClientInfo("radius")))
		local c = 0
		for k, v in pairs(sph) do
			print(v)
			if isAllowed(ply, v) then
				if not self:IsSelected(v, ply) then
					c = c + 1
					self:SelectEntity(v, ply)
				end
			end 	
		end		 
		ply:ChatPrint("Count selected: " .. table.Count(ply.SelectItem))
		 
		return true
	end
	
	if (SERVER && !util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone)) then return false end

	local ent = trace.Entity
	self.isused = false
	
	if (self:IsSelected(ent, ply)) then
		 
		b = self:DeselectEntity(ent, ply)
	else
		
		b = self:SelectEntity(ent, ply)
	end	
	ply:ChatPrint("Count selected: " .. table.Count(ply.SelectItem))	
	return b
end

function TOOL:RightClick( trace )
    if (CLIENT) then return true end
	local ply = self:GetOwner()
    local ent = trace.Entity

    if(table.Count(ply.SelectItem) > 0) then

		net.Start("E2converter_file_d")
			net.WriteTable(ply.SelectItem )
			if(IsValid(ent)) then 				
				net.WriteTable( { position =  ent:GetPos() ,angle = ent:GetAngles()  })
			else
				net.WriteTable( { position =  self:GetOwner():GetEyeTraceNoCursor().HitPos  ,angle = Angle(0, 0, 0)  })
			end			
			net.Send(self:GetOwner()) 
		self:ClearSelection(self:GetOwner())	


	end
end


function TOOL:Reload( trace )
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	if(ply:KeyDown(IN_SPEED)) then 
		if (#ply.SelectItem > 0) then
			self:ClearSelection(ply)			 
		end
		ply:ChatPrint("Clear all")
	else	
		local ent = ply:GetEyeTraceNoCursor().Entity
		if(ent:IsPlayer()) then 
			if (self:IsSelected(ent, ply)) then		 
				self:DeselectEntity(ent, ply)
				ply:ChatPrint("Removed: " .. ent:GetModel())
			else
				ply:ChatPrint("Нетууу!")
			end
		end						
	end	
end

function TOOL:Deploy()
	if (CLIENT) then return true end
	local ply = self:GetOwner()	 
	if (#ply.SelectItem > 0) then
		self:ClearSelection(ply)
	end
end