## Summary

There might be other ways to do this, however most of them use more expensive events like OnTick or OnPayerUpdate or OnZombieUpdate

```lua
function IsoObject:AttachAnim(ObjectName, AnimName, NumFrames, frameIncrease, OffsetX, OffsetY, Looping, FinishHoldFrameIndex, DeleteWhenFinished, zBias, TintMod) end
```

In PZ 41.78 you can easily add an animation effect to an IsoGameCharacter which will play by itself.  
Drawbacks: this seems like legacy code and next parts don't work
- DeleteWhenFinished, doesn't remove the attached anim
- zBias and FinishHoldFrameIndex seem to be unused
- transmitUpdatedSpriteToServer will not transmit this attached anim
- there should be support for following character direction, but that might require 3d items

There might be a way to make transmitUpdatedSpriteToServer work, but the frameIncrease will not be synced.

## Create the animation

The animation images should follow this name convention "part a" + "`_`" + "part b " + "`_`" + "frame number".  
Example: Fire_01_0, Fire_01_1, Fire_01_2, Fire_01_3

You can find more information about this in creating tiles and image pack files. You do not need a .tiles file for them.

## Add the animation

```lua
function IsoObject:AttachAnim(ObjectName, AnimName, NumFrames, frameIncrease, OffsetX, OffsetY, Looping, FinishHoldFrameIndex, DeleteWhenFinished, zBias, TintMod) end
```
ObjectName: Used for sprite selection  
AnimName: Used for sprite selection  
NumFrames: number of frames for the animation to load  
frameIncrease: speed to change animation  
OffsetX: adjust sprite position in relation to character  
OffsetY: adjust sprite position in relation to character  
Looping: false stops the animation after 1 cycle, leave last frame visible  
FinishHoldFrameIndex: unused ???  
DeleteWhenFinished: not functional ???  
zBias: not used ???  
TintMod: ColorInfo object  

Example: `getPlayer():AttachAnim("Fire", "01", 4, IsoFireManager.FireAnimDelay, -16, -78, true, 0, false, 0.7, IsoFireManager.FireTintMod)`  
Example: `getPlayer():AttachAnim("myPrefix", "default", 16, 0.1, -8, 100, true, 0, false, 0, ColorInfo.new(1.0, 1.0, 1.0, 1.0))`  
This will load the sprites from `myPrefix_default_0` to `myPrefix_default_15`

## Remove the animation

```lua
    local anims = character:getAttachedAnimSprite()
    if anims ~= nil then
        for i = anims:size() - 1, 0, -1 do
            if anims:get(i):getName() == "myprefixdefault" then
                anims:remove(anims:get(i))
            end
        end
    end
```
In our tests the animation (sprite instance) had this name, `myprefixdefault` without the `_` separator.

You can also remove all anims with `character:RemoveAttachedAnims()`

This animation effect is not persistent between reloads, meaning that it is removed by default when exiting.

## Future Plans

It is expected this will be improved in future versions. There was a blog about new effects and a debug UI.
