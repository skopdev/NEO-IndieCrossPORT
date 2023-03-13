package;

import openfl.utils.Function;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import haxe.Json;

using StringTools;

typedef FPSection =
{
	charSprite:String,
	charOfsX:Float,
	charOfsY:Float,
	bgSprite:String,
	bgOfsX:Float,
	bgOfsY:Float,
	weekList:Array<String>
}

class FreeplaySelect extends MusicBeatState
{

    var curSelect:Int = 0;
    var menuItems:Array<String>;
    var menuObjs:FlxTypedGroup<FlxSprite>;
    var menuBgObjs:FlxTypedGroup<FlxSprite>;

    var camFollow:FlxObject;
	var camFollowPos:FlxObject;

    override function create()
    {

        menuItems = CoolUtil.coolTextFile(Paths.txt('fpSectionList'));

        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBGBlue'), 90);
		bg.scrollFactor.set(0.3, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.575));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

        camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

        menuBgObjs = new FlxTypedGroup<FlxSprite>();
        add(menuBgObjs);

        menuObjs = new FlxTypedGroup<FlxSprite>();
        add(menuObjs);

        FlxG.camera.follow(camFollowPos, null, 1);

        for (i in 0...menuItems.length)
        {
            trace('before');
            var sectionJSON:FPSection;
            sectionJSON = Json.parse(Paths.getTextFromFile('data/fp_' + menuItems[i] + '.json'));

            var menuObj:FlxSprite;
            //menuObj = new FlxSprite().loadGraphic(Paths.image('freeplaymenu/' + menuItems[i]));
            menuObj = new FlxSprite().loadGraphic(Paths.image('freeplaymenu/' + sectionJSON.charSprite), false, 0, 50);
            menuObj.scrollFactor.set(1, 0);
            menuObj.x = (i*1500) + sectionJSON.charOfsX;
            menuObj.ID = i;
            //menuObj.screenCenter(X);
            menuObj.screenCenter(Y);
            menuObj.y+=sectionJSON.charOfsY;
            menuObjs.add(menuObj);

            var menuBgObj:FlxSprite;
            //menuObj = new FlxSprite().loadGraphic(Paths.image('freeplaymenu/' + menuItems[i]));
            menuBgObj = new FlxSprite().loadGraphic(Paths.image('freeplaystages/' + sectionJSON.bgSprite), false, 0, 50);
            menuBgObj.scrollFactor.set(0, 0);
            menuBgObj.x = -100 + sectionJSON.bgOfsX;
            menuBgObj.ID = i;
            //menuObj.screenCenter(X);
            menuBgObj.y = -200 + sectionJSON.bgOfsY;

            if (i != 0)
                menuBgObj.alpha = 0;
            menuBgObjs.add(menuBgObj);
        }

    }

    override function update(elapsed:Float)
    {
        
        super.update(elapsed);

        if(controls.UI_RIGHT_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelect += 1;
            trace(curSelect);
        }
        if(controls.UI_LEFT_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelect -= 1;
            trace(curSelect);
        }

        if(curSelect > menuItems.length - 1)
        {
            curSelect = 0;
            trace(curSelect);
        }
        if(curSelect < 0)
        {
            curSelect = menuItems.length - 1;
            trace(curSelect);
        }

        menuObjs.forEach(function(spr:FlxSprite)
        {
            
            if (spr.ID == curSelect)
            {
                spr.visible = true;
                var add:Float = 0;
                camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
            } else {
                //spr.visible = false;
            }

        });

        var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

        menuBgObjs.forEach(function(spr:FlxSprite)
        {
                
            if (spr.ID <= curSelect)
            {
                spr.visible = true;
                var add:Float = 0;
		        spr.alpha = (FlxMath.lerp(spr.alpha, 1, lerpVal));
            } else {
		        spr.alpha = (FlxMath.lerp(spr.alpha, 0, lerpVal));
            }

            spr.x = (FlxMath.lerp(spr.x, (spr.ID - curSelect - 1) * 200, lerpVal));
    
        });

        
        if(controls.ACCEPT)
        {
            trace('accept');
            FlxG.sound.play(Paths.sound('confirmMenu'));
            FreeplayState.curCatagory = menuItems[curSelect];
            MusicBeatState.switchState(new FreeplayState());
        }

        if(controls.BACK)
        {
            trace('back');
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
        }

        var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

    }

}