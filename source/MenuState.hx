package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;

class MenuState extends FlxState
{
	static inline var BG_PNG:String = "images/background.png";

	static inline var ANIM_PNG:String = "images/day2.png";
	static inline var ANIM_XML:String = "images/day2.xml";
	static inline var ANIM_FPS:Int = 24;

	static inline var PLAY_PNG:String = "images/play.png";
	static inline var INFO_PNG:String = "images/game.png";
	static inline var EXIT_PNG:String = "images/out.png";
	static inline var BTN_MAX_W:Float = 180;
	static inline var BTN_MAX_H:Float = 100;
	static inline var BTN_GAP:Float = 30;
	static inline var BTN_BOTTOM_GAP:Float = 60;

	override public function create():Void
	{
		super.create();

		createBackground();

		var title:FlxText = new FlxText(0, 30, FlxG.width, "ĐOÁN CHỮ");
		title.setFormat(Paths.FONT_GAME, 56, 0xFF000000, CENTER);
		add(title);

		var btnTop:Float = FlxG.height - BTN_BOTTOM_GAP - BTN_MAX_H;
		createAnimation(110, btnTop - 20);
		createButtons(btnTop);
	}

	private function createBackground():Void
	{
		if (!Paths.exists(BG_PNG))
		{
			trace('Không tìm thấy $BG_PNG');
			return;
		}

		var bg:FlxSprite = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image(BG_PNG));
		var s:Float = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
		bg.scale.set(s, s);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);
	}

	private function createButtons(top:Float):Void
	{
		var buttons:Array<ImageButton> = [];
		var btnInfo = makeButton(INFO_PNG, function() FlxG.switchState(InfoState.new));
		if (btnInfo != null) buttons.push(btnInfo);

		var btnPlay = makeButton(PLAY_PNG, function() FlxG.switchState(PlayState.new));
		if (btnPlay != null) buttons.push(btnPlay);

		var btnExit = makeButton(EXIT_PNG, function()
		{
			#if sys
			Sys.exit(0);
			#end
		});
		if (btnExit != null) buttons.push(btnExit);

		if (buttons.length == 0)
			return;

		var totalW:Float = BTN_GAP * (buttons.length - 1);
		for (b in buttons)
			totalW += b.width;

		var x:Float = (FlxG.width - totalW) / 2;
		for (b in buttons)
		{
			b.x = x;
			b.y = top + (BTN_MAX_H - b.height) / 2;
			x += b.width + BTN_GAP;
			add(b);
		}
	}

	private function makeButton(path:String, onClick:Void->Void):ImageButton
	{
		if (!Paths.exists(path))
		{
			trace('Không tìm thấy $path');
			return null;
		}
		return new ImageButton(path, BTN_MAX_W, BTN_MAX_H, onClick);
	}

	private function createAnimation(top:Float, bottom:Float):Void
	{
		if (!Paths.exists(ANIM_PNG))
		{
			trace('Không tìm thấy $ANIM_PNG');
			return;
		}

		var spr:FlxSprite = new FlxSprite();
		var xmlData = Paths.text(ANIM_XML);

		if (xmlData != null)
		{
			var frames = FlxAtlasFrames.fromSparrow(Paths.image(ANIM_PNG), xmlData);
			spr.frames = frames;
			spr.animation.add("loop", [for (i in 0...frames.frames.length) i], ANIM_FPS, true);
			spr.animation.play("loop");
		}
		else
		{
			spr.loadGraphic(Paths.image(ANIM_PNG));
		}

		var s:Float = Math.min((FlxG.width - 100) / spr.frameWidth, (bottom - top) / spr.frameHeight);
		spr.scale.set(s, s);
		spr.updateHitbox();
		spr.antialiasing = true;
		spr.x = (FlxG.width - spr.width) / 2;
		spr.y = top + ((bottom - top) - spr.height) / 2;
		add(spr);
	}
}
class ImageButton extends FlxSprite
{
	var onClick:Void->Void;
	var baseScale:Float = 1;

	public function new(path:String, maxW:Float, maxH:Float, onClick:Void->Void)
	{
		super();
		this.onClick = onClick;

		loadGraphic(Paths.image(path));
		baseScale = Math.min(maxW / frameWidth, maxH / frameHeight);
		scale.set(baseScale, baseScale);
		updateHitbox();
		antialiasing = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var over:Bool = FlxG.mouse.overlaps(this);
		var s:Float = baseScale;

		if (over)
			s = FlxG.mouse.pressed ? baseScale * 0.95 : baseScale * 1.08;

		scale.set(s, s);

		if (over && FlxG.mouse.justReleased && onClick != null)
		{
			FlxG.sound.play(Paths.sound("click"));
			onClick();
		}
	}
}