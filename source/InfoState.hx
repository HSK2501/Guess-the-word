package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.ui.FlxButton;

class InfoState extends FlxState
{
	static inline var BACK_BOTTOM_GAP:Float = 120;
	static var BG_CANDIDATES:Array<String> = [
		"assets/images/credit_2.png",
		"images/credit_2.png",
		"assets/credit_2.png"
	];

	override public function create():Void
	{
		super.create();

		createBackground();
		createBackButton();
	}

	private function createBackground():Void
	{
		var found:String = null;
		for (path in BG_CANDIDATES)
		{
			if (Paths.exists(path))
			{
				found = path;
				break;
			}
		}

		if (found == null)
		{
			trace("KHÔNG tìm thấy credit_2.png, đã thử: " + BG_CANDIDATES.join(", "));
			var fallback:FlxSprite = new FlxSprite(0, 0);
			fallback.makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A2E);
			add(fallback);
			return;
		}

		trace("Load nền từ: " + found);

		var bg:FlxSprite = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image(found));
		var s:Float = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
		bg.scale.set(s, s);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);
	}

	private function createBackButton():Void
	{
		var btnBack:FlxButton = new FlxButton(0, FlxG.height - BACK_BOTTOM_GAP, "QUAY LẠI", function()
		{
			FlxG.sound.play(Paths.sound("click"));
			FlxG.switchState(MenuState.new);
		});
		btnBack.makeGraphic(200, 50, 0xFF333333);
		btnBack.label.setFormat(Paths.FONT_GAME, 20, 0xFFFFFF, CENTER);
		btnBack.label.fieldWidth = btnBack.width;
		btnBack.x = (FlxG.width - btnBack.width) / 2;
		add(btnBack);
	}
}