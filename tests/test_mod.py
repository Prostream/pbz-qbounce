"""Run the shipped Lua against a small Unreal API double. This is NOT a game test."""
from pathlib import Path
import math
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.dev-python'))
from lupa.lua54 import LuaRuntime

MOCK = r'''
clock = 0; paused = false; queued = {}; keys = {}; logs = {}; meshes = {}; scans = 0
os.clock = function() return clock end
print = function(s) logs[#logs+1] = s end
function object(id, name)
  local o = {id=id, name=name, valid=true}
  function o:IsValid() return self.valid end
  function o:GetAddress() return self.id end
  function o:GetFullName() return self.name end
  function o:GetWorld() return world end
  function o:K2_GetActorLocation() return self.pos or {X=0,Y=0,Z=0} end
  function o:IsA(c) return self.pawn == true end
  return o
end
world = object(1, 'World')
player = object(2, 'Player'); player.pawn=true
enemy = object(3, 'Enemy'); enemy.pawn=true
prop = object(4, 'Prop')
controller = object(5, 'PC'); controller.Pawn=player
local pawnClass = object(6, 'Pawn')
local meshClass = object(7, 'SkeletalMeshComponent')
local statics = object(8, 'Statics')
function statics:IsGamePaused() return paused end
function newmesh(id, owner, x, y, z, parent)
  local m = object(id, 'Mesh_' .. id)
  m.owner=owner; m.RelativeScale3D={X=x,Y=y,Z=z}; m.parent=parent; m.writes=0
  function m:GetOwner() return self.owner end
  function m:GetAttachParent() return self.parent end
  function m:SetRelativeScale3D(v)
    assert(not self.failWrite, 'test write failure')
    self.RelativeScale3D={X=v.X,Y=v.Y,Z=v.Z}; self.writes=self.writes+1
  end
  meshes[#meshes+1]=m
  return m
end
pm = newmesh(10, player, 1, 1, 1)
em = newmesh(20, enemy, 2, 3, 4)
child = newmesh(21, enemy, 1, 1, 1, em)
sibling = newmesh(22, enemy, 2, 3, 4)
propmesh = newmesh(30, prop, 1, 1, 1)
function StaticFindObject(path)
  if path:find('SkeletalMeshComponent') then return meshClass end
  return pawnClass
end
function FindAllOf() scans=scans+1; return meshes end
package.preload.UEHelpers=function() return {
 GetPlayerController=function() return controller end,
 GetGameplayStatics=function() return statics end
} end
Key={F6=6,F7=7,F8=8,F9=9}
function RegisterKeyBind(k,fn) keys[k]=fn end
function RegisterLoadMapPostHook(fn) mapHook=fn end
function LoopAsync(ms,fn) loop=fn end
function ExecuteInGameThread(fn) queued[#queued+1]=fn end
function drain()
 local q=queued; queued={}; for _,fn in ipairs(q) do fn() end
end
function step(t) clock=t; loop(); drain() end
function press(k) keys[k](); drain() end
'''

class ModTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        # Load UTF-8 source via Python: stock Lua fopen cannot open this Chinese
        # workspace path on Windows. The actual game's install path is ASCII.
        for module in ['bounce', 'config']:
            source = (ROOT / 'mod/Scripts' / (module + '.lua')).read_text(encoding='utf-8')
            self.lua.execute('package.preload["' + module + '"] = function()\n' + source + '\nend')
        self.lua.execute(MOCK)
        # Exercise the original MH reference amplitude even if user defaults change.
        self.lua.execute('require("config").Stretch = 0.5')
        self.lua.execute((ROOT / 'mod/Scripts/main.lua').read_text(encoding='utf-8'))
        self.lua.execute('step(0)')

    def runlua(self, code): self.lua.execute(code)
    def number(self, expr): return self.lua.eval(expr)

    def test_matches_reference_extrema_and_original_scale(self):
        self.runlua('step(0.1125)')
        self.assertAlmostEqual(self.number('pm.RelativeScale3D.Z'), 1.5)
        self.assertAlmostEqual(self.number('pm.RelativeScale3D.X'), .75)
        self.assertAlmostEqual(self.number('em.RelativeScale3D.Z'), 6)
        self.assertAlmostEqual(self.number('em.RelativeScale3D.Y'), 2.25)
        self.runlua('step(0.3375)')
        self.assertAlmostEqual(self.number('pm.RelativeScale3D.Z'), .5)
        self.assertAlmostEqual(self.number('pm.RelativeScale3D.X'), 1.25)

    def test_toggle_restores_nonuniform_bases(self):
        self.runlua('step(0.1125); press(6)')
        self.assertEqual(self.number('em.RelativeScale3D.X'), 2)
        self.assertEqual(self.number('em.RelativeScale3D.Y'), 3)
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)
        self.runlua('step(10)')
        self.assertEqual(self.number('pm.RelativeScale3D.Z'), 1)

    def test_child_not_double_scaled_and_props_not_touched(self):
        self.runlua('step(.1125)')
        self.assertEqual(self.number('child.writes'), 0)
        self.assertEqual(self.number('propmesh.writes'), 0)
        self.assertAlmostEqual(self.number('sibling.RelativeScale3D.Z'), 6)

    def test_no_accumulation_after_rediscovery(self):
        self.runlua('for i=1,500 do step(i*.016) end; press(6)')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)
        self.assertLess(self.number('scans'), 10)

    def test_new_enemy_and_out_of_range_restore(self):
        self.runlua('late=newmesh(40,enemy,1,1,1); step(2.1125)')
        self.assertGreater(self.number('late.writes'), 0)
        self.runlua('enemy.pos={X=9000,Y=0,Z=0}; step(4.2)')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)

    def test_map_switch_restores_survivors(self):
        self.runlua('step(.1125); mapHook()')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)
        self.runlua('world=object(50,"NewWorld"); step(3)')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)

    def test_destroyed_objects_not_written(self):
        self.runlua('em.valid=false; step(.1125)')
        self.assertEqual(self.number('em.writes'), 1)

    def test_pending_work_bounded(self):
        self.runlua('for i=1,200 do loop() end')
        self.assertEqual(self.number('#queued'), 1)

    def test_pause_does_not_advance_phase(self):
        self.runlua('step(.1125); paused=true; step(5); paused=false; step(5)')
        self.assertAlmostEqual(self.number('pm.RelativeScale3D.Z'), 1.5)

    def test_write_failure_disables_and_restores_others(self):
        self.runlua('step(.1125); em.failWrite=true; step(.2)')
        self.assertEqual(self.number('pm.RelativeScale3D.Z'), 1)
        self.runlua('em.failWrite=false; step(.3)')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)

    def test_scope_setting_excludes_player(self):
        self.runlua('require("config").AffectPlayer=false; step(2.1)')
        self.assertEqual(self.number('pm.RelativeScale3D.Z'), 1)

    def test_root_mesh_never_scaled(self):
        self.runlua('enemy.RootComponent=em; step(2.1)')
        self.assertEqual(self.number('em.RelativeScale3D.Z'), 4)

    def test_waveform_independent_of_framerate(self):
        for fps in [30, 60, 144]:
            self.setUp()
            for i in range(fps+1): self.lua.globals().step(i / fps)
            expected = 1 + .5 * math.sin(1 / .45 * 2 * math.pi)
            self.assertAlmostEqual(self.number('pm.RelativeScale3D.Z'), expected)

if __name__ == '__main__': unittest.main(verbosity=2)
