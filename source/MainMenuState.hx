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
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;
	
	var scoreText:FlxText;
	
	private static var curDifficulty:Int = 1;
	private static var curWeek:Int = 0;
	
	var intendedScore:Int = 0;	
	var lerpScore:Int = 0;	
	
	var difficultySelectors:FlxGroup;
	var sprDifficultyGroup:FlxTypedGroup<FlxSprite>;
	var upArrow:FlxSprite;
	var downArrow:FlxSprite;	

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	
	var optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'options'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		var curtain:FlxSprite = new FlxSprite (0,0).loadGraphic(Paths.image('Menu_Curtain_Main','heart'));
		add(curtain);
		
		scoreText = new FlxText(6, 6, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("Crewniverse", 17, FlxColor.WHITE, LEFT);		
		add(scoreText);		
		
		var logoSpinel:FlxSprite = new FlxSprite (380, 179).loadGraphic(Paths.image('logoSpinel', 'heart'));
		add(logoSpinel);
		
		var heartDiff:FlxSprite = new FlxSprite (8, 598).loadGraphic(Paths.image('spinel/diffH','heart'));
		add(heartDiff);			
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		
		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		upArrow = new FlxSprite(48, 629);
		upArrow.frames = Paths.getSparrowAtlas('spinel/diff_arrows','heart');
		upArrow.animation.addByPrefix('idle', "Up Arrow Idle");
		upArrow.animation.addByPrefix('press', "Up Arrow Select");
		upArrow.animation.play('idle');
		upArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(upArrow);
		
		sprDifficultyGroup = new FlxTypedGroup<FlxSprite>();
		add(sprDifficultyGroup);

		
		for (i in 0...CoolUtil.difficultyStuff.length) {
			var sprDifficulty:FlxSprite = new FlxSprite().loadGraphic(Paths.image('diffs/' + CoolUtil.difficultyStuff[i][0].toLowerCase()));
			sprDifficulty.x = 28;
			sprDifficulty.ID = i;
			sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
			sprDifficultyGroup.add(sprDifficulty);
		}
		changeDifficulty();		
		
		difficultySelectors.add(sprDifficultyGroup);

		downArrow = new FlxSprite(48, 680);
		downArrow.frames = Paths.getSparrowAtlas('spinel/diff_arrows','heart');
		downArrow.animation.addByPrefix('idle', 'Down Arrow Idle');
		downArrow.animation.addByPrefix('press', "Down Arrow Select", 24, false);
		downArrow.animation.play('idle');
		downArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(downArrow);	

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(900, 0 + (i * 50));
			menuItem.frames = Paths.getSparrowAtlas('SpinyButtons','heart');
			menuItem.animation.addByPrefix('idle', optionShit[i] + " nothing", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " star", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;			
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
			switch(i) {
			    case 0: //story_mode
				    menuItem.x = 508;
					menuItem.y = 526;
					
				case 1: //freeplay
				    menuItem.x = 269;
					menuItem.y = 550;
					
				case 2: //credits
				    menuItem.x = 555;
					menuItem.y = 630;
					
				case 3: //options
				    menuItem.x = 797;
					menuItem.y = 545;
				 
			}			
		}

		FlxG.camera.follow(camFollowPos, null, 0);

		//var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		//versionShit.scrollFactor.set();
		//versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);
		//var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		//versionShit.scrollFactor.set();
		//versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		Achievements.loadAchievements();
		var leDate = Date.now();
		if (!Achievements.achievementsUnlocked[achievementID][1] && leDate.getDay() == 5 && leDate.getHours() >= 18) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
			Achievements.achievementsUnlocked[achievementID][1] = true;
			giveAchievement();
			ClientPrefs.saveSettings();
		}

		super.create();
	}

	// Unlocks "Freaky on a Friday Night" achievement
	var achievementID:Int = 0;
	function giveAchievement() {
		add(new AchievementObject(achievementID, camAchievement));
		FlxG.sound.play(Paths.sound('confirmGarden', 'heart'), 0.7);
		trace('Giving achievement ' + achievementID);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
	
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "SCORE: " + lerpScore;
		
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!movedBack)
		{
			if (controls.UI_DOWN)
				downArrow.animation.play('press')
			else
				downArrow.animation.play('idle');

			if (controls.UI_UP)
				upArrow.animation.play('press');
			else
				upArrow.animation.play('idle');

			if (controls.UI_DOWN_P)
				changeDifficulty(1);
			if (controls.UI_UP_P)
				changeDifficulty(-1);
		}		
		
		if (!selectedSomethin)
		{
			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollGarden', 'heart'));
				changeItem(-1);
			}

			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollGarden', 'heart'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmGarden', 'heart'));

					//if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

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
									    var diffic = CoolUtil.difficultyStuff[curDifficulty][1];
			                            if(diffic == null) diffic = '';
										
										PlayState.storyPlaylist = ['Friends', 'Flowers', 'Friendship', 'Betrayed', 'Postbetrayed']; 
										PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
					                    PlayState.isStoryMode = true; 
					                    PlayState.storyDifficulty = curDifficulty; 
					                    LoadingState.loadAndSwitchState(new PlayState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									//case 'awards':
										//MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new OptionsState());
								}
							});
						}
					});
				}
				

			}
		}

		super.update(elapsed);

	}
	
	var movedBack:Bool = false;

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
			}
		});
	}
	
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyStuff.length-1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length)
			curDifficulty = 0;

		sprDifficultyGroup.forEach(function(spr:FlxSprite) {
			spr.visible = false;
			if(curDifficulty == spr.ID) {
				spr.visible = true;
				spr.alpha = 0;
				spr.y = upArrow.y - 10;
				FlxTween.tween(spr, {y: upArrow.y + 25, alpha: 1}, 0.07);
			}
		});
		
		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.getWeekNumber(curWeek), curDifficulty);
		#end		
	}
}
