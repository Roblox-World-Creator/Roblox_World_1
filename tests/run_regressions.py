"""Run server regression cases against actual Luau modules using a small Roblox stub.
Usage: python tests/run_regressions.py --luau PATH_TO_LUAU_EXE
This verifies game rules; Studio is still required for rendering/physics/network tests.
"""
from pathlib import Path
import argparse, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
PRELUDE = r'''
local modules = {}
local script = {Parent = {ChainAttackService="ChainAttackService",CrowdControlService="CrowdControlService"}}
local function require(id) assert(modules[id], "Missing module " .. tostring(id)); return modules[id] end
local dummy
local mt = {__index=function(_, key) return function() return dummy end end, __mul=function() return dummy end, __add=function() return dummy end, __sub=function() return dummy end}
dummy = setmetatable({}, mt)
local Color3 = {new=function() return dummy end, fromRGB=function() return dummy end, fromHSV=function() return dummy end}
local Vector3 = {new=function() return dummy end, one=dummy, zero=dummy}
local Vector2 = Vector3
local CFrame = {new=function() return dummy end, Angles=function() return dummy end, identity=dummy}
local NumberSequence = {new=function() return dummy end}
local ColorSequence = NumberSequence
local NumberRange = NumberSequence
local RaycastParams={new=function() return {} end}
local Enum = setmetatable({}, {__index=function(_, name) return setmetatable({}, {__index=function(_, key) return name .. "." .. key end}) end})
local function signal()
 local callbacks={}
 return {Connect=function(_,f) table.insert(callbacks,f); return {Disconnect=function() end} end, Fire=function(_,...) for _,f in ipairs(callbacks) do f(...) end end}
end
local methods={}
local Instance={}
function Instance.new(class)
 local v={_props={ClassName=class, Name=class, Value=class=="StringValue" and "" or class=="BoolValue" and false or 0},_children={},_attrs={},_signals={}}
 return setmetatable(v, {__index=function(t,k)
  if methods[k] then return methods[k] end
  if t._props[k] ~= nil then return t._props[k] end
  for _,c in ipairs(t._children) do if c.Name==k then return c end end
 end,__newindex=function(t,k,value)
  if k=="Parent" then
   local old=t._props.Parent
   if old then local index=table.find(old._children,t);if index then table.remove(old._children,index) end end
   if value then table.insert(value._children,t) end
  end
  t._props[k]=value
 end})
end
function methods:IsA(class) return self.ClassName==class end
function methods:FindFirstChild(name) for _,c in ipairs(self._children) do if c.Name==name then return c end end end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function methods:FindFirstChildOfClass(class) for _,c in ipairs(self._children) do if c.ClassName==class then return c end end end
function methods:GetChildren() return table.clone(self._children) end
function methods:SetAttribute(k,v) self._attrs[k]=v; if self._signals[k] then self._signals[k]:Fire() end end
function methods:GetAttribute(k) return self._attrs[k] end
function methods:GetAttributeChangedSignal(k) self._signals[k]=self._signals[k] or signal(); return self._signals[k] end
function methods:Destroy() self.Parent=nil end
function methods:FireClient(...) end
local function object(parent,class,name) local v=Instance.new(class);v.Name,v.Parent=name,parent;return v end
local players=Instance.new("Players")
players.PlayerAdded,players.PlayerRemoving=signal(),signal()
local player=object(players,"Player","Tester")
player.CharacterAdded=signal()
player:SetAttribute("DataLoaded",true)
player:SetAttribute("Level",1);player:SetAttribute("Evolution",0);player:SetAttribute("Coins",1000)
function players:GetPlayers() return {player} end
local rep=Instance.new("ReplicatedStorage")
local remotes=object(rep,"Folder","Remotes")
local shared=object(rep,"Folder","Shared")
for _,name in ipairs({"InventoryRemote","InventoryEvent","PowerRemote","EvolutionRemote","QuestRemote","QuestEvent"}) do
 local r=object(remotes,"RemoteFunction",name);r.OnServerEvent=signal()
end
local workspace=Instance.new("Workspace")
local game={GetService=function(_,name) return ({Players=players,ReplicatedStorage=rep,Debris={AddItem=function() end}})[name] end}
local task={spawn=function(f,...) f(...) end, wait=function() end, delay=function() end}
local function typeof(v) return type(v) end
local loaded={Inventory={IronBlade={Count=1,Locked=true},HealthPotion={Count=3},ManaPotion={Count=2}},Equipment={Weapon="IronBlade"}}
local saves={GetLoadedData=function() return loaded end}
local progression={RefreshStats=function() end,AddCoins=function(p,n) p:SetAttribute("Coins",(p:GetAttribute("Coins") or 0)+n) end,AddXP=function(p,n) p:SetAttribute("XP",(p:GetAttribute("XP") or 0)+n) end}
local count=0
local function check(ok,message) assert(ok,message);count+=1 end
'''
CASES = r'''
local items, powers = modules.ItemConfig, modules.ProgressionConfig
for id, definition in pairs(items.Items) do
 check(not definition.AbilityId or powers.Abilities[definition.AbilityId], "Item ability missing: "..id)
 check(definition.MaximumStack and definition.MaximumStack > 0, "Invalid stack: "..id)
end
for id,recipe in pairs(items.Recipes) do
 check(items.Items[id] and recipe.Quantity <= items.Items[id].MaximumStack, "Bad recipe output "..id)
 for ingredient in pairs(recipe.Ingredients) do check(items.Items[ingredient],"Missing ingredient "..ingredient) end
end
for _,name in ipairs(powers.AbilityOrder) do
 local ability=powers.Abilities[name]
 check(ability and ability.RequiredLevel <= powers.MaximumLevel and (ability.RequiredEvolution or 0)<=3, "Unreachable ability "..name)
end

local obtainable={BossCore=true}
for id,definition in pairs(items.Items) do if definition.BuyPrice then obtainable[id]=true end end
for id in pairs(items.Recipes) do obtainable[id]=true end
for _,loot in pairs(items.LootTables) do
 for _,entry in ipairs(loot) do check(items.Items[entry.ItemId],"Unknown loot item "..entry.ItemId);obtainable[entry.ItemId]=true end
end
for enemy,drop in pairs(items.MobDrops) do
 check(modules.EnemyConfig[enemy],"Unknown enemy in drop table "..enemy)
 if drop.Part then check(items.Items[drop.Part],"Missing monster material "..drop.Part);obtainable[drop.Part]=true end
 for _,entry in ipairs(drop.Rare or {}) do check(items.Items[entry.ItemId],"Missing rare drop "..entry.ItemId);obtainable[entry.ItemId]=true end
end
for id in pairs(items.Items) do check(obtainable[id],"No normal acquisition route for "..id) end
for id,realm in pairs(modules.RealmConfig.Realms) do
 check(realm.RecommendedLevel<=powers.MaximumLevel,"Unreachable realm "..id)
 for _,enemy in ipairs(realm.Mobs) do check(modules.EnemyConfig[enemy],"Missing realm monster "..enemy) end
end

local inventory=modules.InventoryService
inventory.Start(items,saves,progression,powers)
check(player:GetAttribute("InventoryReady"),"Inventory setup")
check(player.Equipment.Weapon.Value=="IronBlade","Starter weapon")
check(not inventory.Grant(player,"HealthPotion",0/0),"Reject NaN grants")
check(not inventory.Grant(player,"HealthPotion",math.huge),"Reject infinite grants")
check(not inventory.Grant(player,"Unknown",1),"Reject unknown grants")
local success,_,amount=inventory.Grant(player,"HealthPotion",25)
check(success and amount==25 and player.Inventory.HealthPotion.Value==28,"Exact grant quantity")
player.Inventory.HealthPotion.Value=98
success,_,amount=inventory.Grant(player,"HealthPotion",5)
check(success and amount==1,"Partial grant reports actual quantity")
check(not inventory.CanGrant(player,"HealthPotion",3),"Full reward preflight")
check(not inventory.Sell(player,"IronBlade"),"Locked equipped item cannot sell")
inventory.SellJunk(player)
check(player.Inventory.HealthPotion and player.Inventory.ManaPotion,"Junk sale preserves supplies")
inventory.Grant(player,"EvolutionShard",2)
player.Inventory.EvolutionShard:SetAttribute("Locked",true)
local result=remotes.InventoryRemote.OnServerInvoke(player,"Craft",{ItemId="HealthPotion"})
check(not result.Success and player.Inventory.EvolutionShard.Value==2,"Craft preserves locked ingredients")
player.Inventory.EvolutionShard:SetAttribute("Locked",false)
player.Inventory.HealthPotion:Destroy()
local oldCapacity=items.Capacity
items.Capacity=#player.Inventory:GetChildren()
result=remotes.InventoryRemote.OnServerInvoke(player,"Craft",{ItemId="HealthPotion"})
check(result.Success and player.Inventory.HealthPotion.Value==2 and not player.Inventory.EvolutionShard,"Full inventory craft reuses consumed slot")
items.Capacity=oldCapacity
local power=modules.PowerService
power.Start(powers,saves)
local state=remotes.PowerRemote.OnServerInvoke(player,"GetState")
check(state.Success and #state.Attacks==6,"Six stable spell slots")
local payload={Attacks={"","","","","","FireBolt"},Motion={"PowerDash","Dodge"},Ultimate=""}
result=remotes.PowerRemote.OnServerInvoke(player,"SetLoadout",payload)
check(result.Success and player:GetAttribute("ActiveAttacks")==",,,,,FireBolt","Assign slot six without shifting")
payload.Attacks={"FireBolt","FireBolt"}
check(not remotes.PowerRemote.OnServerInvoke(player,"SetLoadout",payload).Success,"Duplicate spells rejected")
payload.Attacks={"BlackHole"}
check(not remotes.PowerRemote.OnServerInvoke(player,"SetLoadout",payload).Success,"Locked spells rejected")
payload.Attacks={"FireBolt"};payload.Motion={"Dodge","PowerDash"}
check(not remotes.PowerRemote.OnServerInvoke(player,"SetLoadout",payload).Success,"Motion category enforced")
payload.Attacks={"","","","","",""};payload.Motion={"PowerDash","Dodge"}
check(remotes.PowerRemote.OnServerInvoke(player,"SetLoadout",payload).Success,"All combat slots may be cleared")
check(not power.IsActive(player,"FireBolt"),"Cleared spells cannot cast")
local quests={Test={DisplayName="Test",Event="Kill",Goal=1,RewardXP=10,RewardGold=20,RewardItem="HealthPotion",RewardQuantity=3}}
local quest=modules.QuestService
quest.Start(quests,saves,progression,powers,inventory)
remotes.QuestRemote.OnServerInvoke(player,"Start",{QuestId="Test"})
quest.Record(player,"Kill",1)
player.Inventory.HealthPotion.Value=99
check(not remotes.QuestRemote.OnServerInvoke(player,"Claim",{QuestId="Test"}).Success,"Full bag does not consume quest claim")
check(not player.QuestClaims.Test.Value,"Quest remains claimable")
player.Inventory.HealthPotion.Value=1
check(remotes.QuestRemote.OnServerInvoke(player,"Claim",{QuestId="Test"}).Success,"Quest rewards claim after making room")
check(not remotes.QuestRemote.OnServerInvoke(player,"Claim",{QuestId="Test"}).Success,"No duplicate claim")
player.Character=Instance.new("Model")
local humanoid=object(player.Character,"Humanoid","Humanoid");humanoid.Health,humanoid.MaxHealth=100,100
local evolution=modules.EvolutionService
evolution.Start(modules.EvolutionConfig,powers,progression,{MaxMP=100,BaseWalkSpeed=36})
player:SetAttribute("Coins",0)
check(evolution.ForceEvolve(player),"Forced evolution works")
check(player:GetAttribute("Coins")==0,"Forced evolution never makes gold negative")
local before=player:GetAttribute("Evolution")
remotes.EvolutionRemote.OnServerEvent:Fire(player)
check(player:GetAttribute("Evolution")==before,"Normal evolution enforces requirements")
for _,id in ipairs(modules.MeleeConfig.Order) do
 local move=modules.MeleeConfig.Moves[id]
 check((not move.Skill or modules.SkillTreeConfig.Nodes[move.Skill]) and move.RequiredLevel <= powers.MaximumLevel,"Reachable sword move "..id)
end

local progressionService=modules.PlayerProgression
player:SetAttribute("Level",1);player:SetAttribute("XP",0)
progressionService.AddXP(player,100,powers)
check(player:GetAttribute("Level")==2 and player:GetAttribute("XP")==0,"Exact XP threshold levels once")
progressionService.AddXP(player,100000000,powers)
check(player:GetAttribute("Level")==powers.MaximumLevel,"XP respects maximum level")
check(player:GetAttribute("XP")<player:GetAttribute("XPRequired"),"XP cap remains bounded")
loaded.PowerLoadout={Attacks={"","","","","","FireBolt"},Motion={"PowerDash","Dodge"},Ultimate=""}
power.Start(powers,saves)
check(player:GetAttribute("ActiveAttacks")==",,,,,FireBolt","Saved sixth-slot assignment reloads unchanged")
local queued={}
task.delay=function(_,f) table.insert(queued,f) end
local function flush() local calls=queued;queued={};for _,f in ipairs(calls) do f() end end
local vectorMT={}
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMT) end
vectorMT.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMT.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMT.__mul=function(a,b) return vector(a.X*b,a.Y*b,a.Z*b) end
vectorMT.__index=function(v,key)
 if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if key=="Unit" then return vector(v.X/v.Magnitude,v.Y/v.Magnitude,v.Z/v.Magnitude) end
 if key=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
Vector3.new=vector
local clock=100
function workspace:GetServerTimeNow() return clock end
function workspace:Raycast() return nil end
local RaycastParams={new=function() return {} end}
-- Sword module resolves RaycastParams at invocation, supplied via its environment.
local root=object(player.Character,"Part","HumanoidRootPart")
root.Position,root.CFrame,root.AssemblyLinearVelocity=vector(0,0,0),{LookVector=vector(0,0,-1)},vector(0,0,0)
local enemy=Instance.new("Model")
local enemyRoot=object(enemy,"Part","HumanoidRootPart");enemyRoot.Position=vector(0,0,-5)
local skillFolder=object(player,"Folder","Skills")
for _,id in ipairs({"Melee01","Melee02","Melee04"}) do object(skillFolder,"IntValue",id).Value=1 end
player:SetAttribute("EquippedWeapon","IronBlade");player:SetAttribute("Stamina",100)
player:SetAttribute("EvolutionTransforming",false);player:SetAttribute("AdminAllPowersUnlocked",false)
local damageCount=0
local sword=modules.SwordMoveService.Start({Effects={FireAllClients=function() end},Feedback={FireClient=function() end},GetEnemies=function() return {enemy} end,Knockback=function() end,Damage=function() damageCount+=1 end})
player:SetAttribute("Level",1)
sword.Cast(player,"Lunge")
check(player:GetAttribute("Stamina")==100,"Locked sword move costs nothing")
player:SetAttribute("Level",100)
sword.Cast(player,"Unknown")
check(player:GetAttribute("Stamina")==100,"Unknown sword move rejected")
sword.Cast(player,"Lunge")
check(player:GetAttribute("Stamina")==82,"Accepted move charges stamina once")
sword.Cast(player,"Lunge");flush()
check(player:GetAttribute("Stamina")==82 and damageCount==1,"Repeated request cannot duplicate sword hit")
clock+=1
sword.Cast(player,"Lunge")
check(player:GetAttribute("Stamina")==82,"Sword cooldown enforced beyond animation")
clock+=20
player:SetAttribute("Stamina",100)
sword.Cast(player,"Whirlwind");flush()
check(damageCount==4,"Whirlwind delivers exactly three hits")
clock+=20
sword.Cast(player,"Cleave")
local originalCharacter=player.Character
player.Character=Instance.new("Model")
flush()
check(damageCount==4,"Respawn cancels delayed sword damage")
player.Character=originalCharacter
clock+=20
player:SetAttribute("Stamina",0)
sword.Cast(player,"Lunge");flush()
check(damageCount==4,"Insufficient stamina cannot cause damage")
sword.Reset(player)
check(player:GetAttribute("SwordLungeReadyAt")==0,"Admin reset clears sword cooldown display")

local chainConfig=modules.MeleeConfig
check(chainConfig.GetChainRank(0,1)==0,"Chain starts with two targets")
check(chainConfig.GetChainRank(100,1)==0,"Chain XP cannot bypass player level")
check(chainConfig.GetChainRank(0,100)==0,"Player level cannot bypass chain XP")
for rank=1,5 do
 check(chainConfig.GetChainRank(rank*20,rank*15+1)==rank,"Chain rank unlock "..rank)
 check(chainConfig.GetChainRank(rank*20-1,rank*15+1)==rank-1,"Chain XP boundary "..rank)
 check(chainConfig.GetChainRank(rank*20,rank*15)==rank-1,"Chain level boundary "..rank)
end
check(chainConfig.GetChainRank(999999,999)==5,"Chain cap remains seven targets")

-- Execute the real chain service with deterministic physics stubs.
vectorMT.__index=function(v,key)
 if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if key=="Unit" then return vector(v.X/v.Magnitude,v.Y/v.Magnitude,v.Z/v.Magnitude) end
 if key=="Lerp" then return function(a,b,t) return a+(b-a)*t end end
 if key=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
Vector3.zero=vector(0,0,0)
CFrame.lookAt=function(position,target) root.Position=position;return {Position=position,LookVector=(target-position).Unit} end
local owned=false
function root:SetNetworkOwner() owned=true end
function root:SetNetworkOwnershipAuto() owned=false end
local blocked=false
function workspace:Blockcast() return blocked and {} or nil end
local mobs={}
for index=1,8 do
 local mob=object(workspace,"Model","ChainMob"..index)
 object(mob,"Part","HumanoidRootPart").Position=vector(0,0,-index*8)
 local hum=object(mob,"Humanoid","Humanoid");hum.Health=100
 table.insert(mobs,mob)
end
local chainHits=0
local chainService=modules.ChainAttackService.Start({GetEnemies=function() return mobs end,Effects={FireAllClients=function() end},Knockback=function() end,Damage=function() chainHits+=1;return {Amount=1} end})
task.wait=function() clock+=0.05;return 0.05 end
local function beginChain()
 root.Position=vector(0,0,0);root.CFrame={LookVector=vector(0,0,-1)}
 chainService.Begin(player,player.Character,root,humanoid,"IronBlade")
end
player:SetAttribute("ChainMasteryXP",0);player:SetAttribute("Level",1)
humanoid.AutoRotate=true
beginChain()
check(chainHits==6,"Default chain hits two unique targets three times")
check(player:GetAttribute("ChainMasteryXP")==2,"Chain grants one XP per damaged target")
check(not owned and humanoid.AutoRotate and player:GetAttribute("SwordMoveBusyUntil")==0,"Chain restores ownership rotation and busy state")
player:SetAttribute("ChainMasteryXP",100);player:SetAttribute("Level",100)
chainHits=0;beginChain()
check(chainHits==21,"Maximum chain visits seven targets")
blocked=true;chainHits=0;beginChain()
check(chainHits==0 and not owned,"Blocked player volume prevents dash and damage")
blocked=false
local previousWait=task.wait
local originalChainCharacter=player.Character
task.wait=function() player.Character=Instance.new("Model");return 0.05 end
chainHits=0;beginChain()
check(chainHits==0 and not owned,"Respawn during dash cancels chain and restores ownership")
player.Character=originalChainCharacter;task.wait=previousWait
-- A reset before the scheduled coroutine starts must not steal network ownership.
local pending
local oldSpawn=task.spawn
task.spawn=function(f) pending=f end
beginChain();chainService.Cancel(player);pending()
check(not owned and player:GetAttribute("SwordMoveBusyUntil")==0,"Reset before chain coroutine starts leaves ownership intact")
task.spawn=oldSpawn
chainService.Destroy()
local masteryService=modules.MasteryService
masteryService.Start(powers,saves)
check(player.PowerMastery:FindFirstChild("Dodge")~=nil,"Motion mastery is initialized alongside spells")
masteryService.Add(player,"Dodge",powers.Mastery.XPBase)
check(masteryService.GetLevel(player,"Dodge")==1,"Motion mastery levels with earned XP")
player:SetAttribute("Level",1)
check(masteryService.GetLevel(player,"Dodge")==0,"Motion mastery respects player level gate")
player:SetAttribute("Level",6)
check(masteryService.GetLevel(player,"Dodge")==1,"Motion rank opens at its player level threshold")

print(string.format("PASS: %d configuration and server regression checks",count))
'''
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--luau',required=True);args=parser.parse_args()
 chunks=[PRELUDE]
 for name in ['ItemConfig','ProgressionConfig','EvolutionConfig','SkillTreeConfig','MeleeConfig','RealmConfig','EnemyConfig']:
  chunks.append(f'modules.{name} = (function()\n'+(ROOT/f'src/ReplicatedStorage/Shared/{name}.lua').read_text(encoding='utf-8-sig')+'\nend)()\n')
 chunks.append('shared.MeleeConfig = \"MeleeConfig\"\n')
 for name in ['InventoryService','PowerService','QuestService','EvolutionService','PlayerProgression','MasteryService','CrowdControlService','ChainAttackService','SwordMoveService']:
  chunks.append(f'modules.{name} = (function()\n'+(ROOT/f'src/ServerScriptService/Systems/{name}.lua').read_text(encoding='utf-8-sig')+'\nend)()\n')
 chunks.append(CASES)
 with tempfile.TemporaryDirectory(prefix='world-regression-') as tmp:
  runner=Path(tmp)/'regression.luau';runner.write_text('\n'.join(chunks),encoding='utf-8')
  return subprocess.run([args.luau,str(runner)],cwd=ROOT).returncode
if __name__=='__main__':raise SystemExit(main())
