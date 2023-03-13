package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import haxe.Json;

using StringTools;

typedef TitleData2 =
{

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = 'demo'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	public static var enterPress:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var menuXpos:Array<Dynamic> = [];
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		//'credits',
		//#if !switch 'donate', #end
		'options',
		#if MODS_ALLOWED 'mods', #end
		'awards',
		'credits'
	];

	var magenta:FlxSprite;
	var logoBl:FlxSprite;
	var bfBop:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var titleJSON:TitleData2;
	var debugStuff = CoolUtil.coolTextFile(Paths.txt('debugStuff'));

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();
		Achievements.loadCustomAchievments();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		//Conductor.changeBPM(titleJSON.bpm);
		Conductor.changeBPM(117);
		if (debugStuff[0] == "false")
		{
			optionShit = [
				'story_mode',
				'freeplay',
				//'credits',
				//#if !switch 'donate', #end
				'options',
				'awards',
				'credits'
			];
		
		}

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-120).loadGraphic(Paths.image('BG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 2.175));
		bg.height = 2100;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		logoBl = new FlxSprite(20, -1500);
		logoBl.frames = Paths.getSparrowAtlas('titlestuff/logoneo');
		logoBl.scrollFactor.set(0, 1.6);
		logoBl.alpha = 1;
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.animation.addByPrefix('bump', 'bump', 24, false);
		logoBl.animation.play('bump');
		logoBl.scale.x = 0.7;
		logoBl.scale.y = 0.7;
		logoBl.updateHitbox();

		bfBop = new FlxSprite(0, -720);
		bfBop.frames = Paths.getSparrowAtlas('titlestuff/bfmenubop');
		bfBop.scrollFactor.set(0, 1);
		bfBop.alpha = 0.8;
		bfBop.antialiasing = false;
		bfBop.animation.addByPrefix('bop', 'BF foot bop', 24, false);
		bfBop.animation.play('bop');
		bfBop.scale.x = 0.7;
		bfBop.scale.y = 0.7;
		bfBop.updateHitbox();
		bfBop.screenCenter(X);

		add(bfBop);
		add(logoBl);

		var menuIcons:FlxSprite = new FlxSprite(0, 200).loadGraphic(Paths.image('mainmenu/menu icons'));
		menuIcons.scale.set(0.9, 0.9);
		menuIcons.scrollFactor.set(0, 0.8);
		menuIcons.screenCenter(X);
		menuIcons.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuIcons);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		if (!enterPress)
		{
			titleThing(false);
			camFollowPos.y = -600;
		} else {
			camFollowPos.y = 200;
			camFollow.y = 200;
		}

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		//add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1.3;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			/*
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(80, (i * 140)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			trace('menuguh');
			trace(optionShit[i]);
			menuItem.loadGraphic(Paths.image('mainmenu/' + optionShit[i]));
			//menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			//menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			//menuItem.animation.play('idle');
			menuItem.ID = i;
			//menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			//if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, 1);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			//menuItem.updateHitbox();
			*/
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			offset = 0;
			var menuItem:FlxSprite = new FlxSprite(-60, 200 + offset);
			menuItem.scale.x = 1;
			menuItem.scale.y = 0.8;
			menuItem.loadGraphic(Paths.image('mainmenu/' + optionShit[i]));
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0, 1);
			menuItem.antialiasing = false;

			var flipped = false;

			switch (optionShit[i])
			{
				case "story_mode":
					//menuItem.x = 0;
				case "freeplay":
					menuItem.x -= (43 * menuItem.scale.x);
					menuItem.y += (109 * menuItem.scale.y);
				case "options":
					menuItem.x -= (82 * menuItem.scale.x);
					menuItem.y += (208 * menuItem.scale.y);
				case "mods":
					menuItem.x += 300;
					menuItem.y += 300;
				case "awards":
					menuItem.x += 950;
					flipped = true;
				case "credits":
					menuItem.x += 950;
					menuItem.x += (43 * menuItem.scale.x);
					menuItem.y += (109 * menuItem.scale.y);
					flipped = true;
			}

			//menuXpos.insert(1, [menuItem.x, menuItem.x + 30]);
			//menuXpos.insert(1, [123, 234]);
			if (!flipped)
				menuXpos[i] = [menuItem.x, menuItem.x + 30, menuItem.x];
			else
				menuXpos[i] = [menuItem.x, menuItem.x - 30, menuItem.x];
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Modified Mogus Engine" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));


		menuItems.forEach(function(spr:FlxSprite)
		{

			var slurpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

			if (curSelected == spr.ID)
				menuXpos[spr.ID][2] = FlxMath.lerp(spr.x, menuXpos[spr.ID][1], slurpVal);
			else
				menuXpos[spr.ID][2] = FlxMath.lerp(spr.x, menuXpos[spr.ID][0], slurpVal);
				
			spr.x = menuXpos[spr.ID][2];
				
		});

		if (!selectedSomethin)
		{

			if (enterPress == true)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(-1);
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(1);
				}
			}

			if (controls.BACK)
			{
				//selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				titleThing(false);
			}

			if (controls.ACCEPT)
			{
				if (enterPress == true)
				{
					
					if (optionShit[curSelected] == 'donate')
					{
						CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
					}
					else
					{
						selectedSomethin = true;
						FlxG.sound.play(Paths.sound('confirmMenu'));

						if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

						menuItems.forEach(function(spr:FlxSprite)
						{
							if (curSelected != spr.ID)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									} 
								});
							}
							else
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									var daChoice:String = optionShit[curSelected];

									switch (daChoice)
									{
										case 'story_mode':
											MusicBeatState.switchState(new StoryMenuState());
										case 'freeplay':
											MusicBeatState.switchState(new FreeplaySelect());
											//MusicBeatState.switchState(new FreeplayState());
										case 'play':
											MusicBeatState.switchState(new FreeplaySelect());
										#if MODS_ALLOWED
										case 'mods':
											MusicBeatState.switchState(new ModsMenuState());
										#end
										case 'awards':
											MusicBeatState.switchState(new AchievementsMenuState());
										case 'credits':
											MusicBeatState.switchState(new CreditsState());
										case 'options':
											LoadingState.loadAndSwitchState(new options.OptionsState());
									}
								});
							}
						});
					}
				}
				else
				{
					titleThing(true);
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				if (debugStuff[0] == "true")
				{
					selectedSomethin = true;
					MusicBeatState.switchState(new MasterEditorMenu());
				}
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			//spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;


		menuItems.forEach(function(spr:FlxSprite)
		{
			//spr.animation.play('idle');
			//spr.scale.x = 0.7;
			//spr.scale.y = 0.7;
			spr.updateHitbox();
			//spr.x = menuXpos[spr.ID][0];
			spr.alpha = 0.8;


			if (spr.ID == curSelected)
			{
				//spr.animation.play('selected');
				//spr.x = menuXpos[spr.ID][1];
				spr.alpha = 1;
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}

				//camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}

		});
	}

	function titleThing(wha:Bool)
	{
		if (wha == false)
		{
			enterPress = false;
			camFollow.y = -600;
		}
		else
		{
			enterPress = true;
			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				camFollow.y = 200;
			});
		}

	}

	private var coolStep:Int = 0;

	override function beatHit()
	{
		super.beatHit();
		coolStep++;
		//trace('step' + coolStep);
		if (bfBop != null)
			bfBop.animation.play('bop', true);
		if (coolStep % 2 == 1)
		{
			logoBl.animation.play('bump');
		}
	}

}
