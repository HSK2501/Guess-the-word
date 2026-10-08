package;

import MenuState.ImageButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;

class CongratsSubState extends FlxSubState
{
	static inline var CONGRATS_PNG:String = "images/good.png";
	static inline var NEXT_PNG:String = "images/conti.png";

	static inline var NEXT_MAX_W:Float = 300;
	static inline var NEXT_MAX_H:Float = 120;
	static inline var NEXT_BOTTOM_GAP:Float = 80;

	var onContinue:Void->Void;
	var inputDelay:Float = 0.5;

	public function new(onContinue:Void->Void)
	{
		super(0xAA000000);
		this.onContinue = onContinue;
	}

	override public function create():Void
	{
		super.create();
		createCongrats();
		createNextButton();
	}

	private function createCongrats():Void
	{
		if (!Paths.exists(CONGRATS_PNG))
		{
			trace('Không tìm thấy $CONGRATS_PNG');
			var t:FlxText = new FlxText(0, FlxG.height / 2 - 40, FlxG.width, "CHÚC MỪNG!");
			t.setFormat(Paths.FONT_GAME, 56, 0xFFFFFFFF, CENTER);
			add(t);
			return;
		}

		var congrats:FlxSprite = new FlxSprite();
		congrats.loadGraphic(Paths.image(CONGRATS_PNG));
		var s:Float = Math.max(FlxG.width / congrats.frameWidth, FlxG.height / congrats.frameHeight);
		congrats.scale.set(s, s);
		congrats.updateHitbox();
		congrats.screenCenter();
		congrats.antialiasing = true;
		congrats.alpha = 0;
		add(congrats);
		FlxTween.tween(congrats, {alpha: 1}, 0.3);
	}

	private function createNextButton():Void
	{
		if (!Paths.exists(NEXT_PNG))
		{
			trace('Không tìm thấy $NEXT_PNG');
			var t:FlxText = new FlxText(0, FlxG.height - NEXT_BOTTOM_GAP - 30, FlxG.width, "NHẤN SPACE ĐỂ TIẾP TỤC");
			t.setFormat(Paths.FONT_GAME, 24, 0xFFFFFFFF, CENTER);
			add(t);
			return;
		}

		var btn:ImageButton = new ImageButton(NEXT_PNG, NEXT_MAX_W, NEXT_MAX_H, goNext);
		btn.x = (FlxG.width - btn.width) / 2;
		btn.y = FlxG.height - NEXT_BOTTOM_GAP - btn.height;
		add(btn);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (inputDelay > 0)
		{
			inputDelay -= elapsed;
			return;
		}

		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
		{
			goNext();
		}
	}

	private function goNext():Void
	{
		FlxG.sound.play(Paths.sound("select"));
		close();
		if (onContinue != null)
			onContinue();
	}
}