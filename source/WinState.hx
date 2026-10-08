package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class WinState extends FlxState
{
	override public function create():Void
	{
		super.create();

		var loaded:Bool = createBackground();
		var btnRetry:FlxButton = new FlxButton(390, 395, loaded ? "" : "CHƠI LẠI", function()
		{
			FlxG.sound.play(Paths.sound("click"));
			FlxG.switchState(PlayState.new);
		});

		if (loaded)
		{
			btnRetry.makeGraphic(210, 55, 0x00000000); 
		}
		else
		{
			btnRetry.setSize(210, 55);
		}
		add(btnRetry);

		var btnMenu:FlxButton = new FlxButton(660, 395, loaded ? "" : "MENU CHÍNH", function()
		{
			FlxG.sound.play(Paths.sound("click"));
			FlxG.switchState(MenuState.new);
		});

		if (loaded)
		{
			btnMenu.makeGraphic(230, 55, 0x00000000);
		}
		else
		{
			btnMenu.setSize(230, 55);
		}
		add(btnMenu);
	}

	private function createBackground():Bool
	{
		var graphic:FlxGraphic = Paths.image("bg_win");
		if (graphic == null) graphic = Paths.image("images/bg_win");
		if (graphic == null) graphic = Paths.image("assets/images/bg_win.png");
		if (graphic == null || graphic.bitmap == null)
		{
			trace('[WinState ERROR] Không tìm thấy bg_win trong assets.HLDT!');

			var fallback:FlxSprite = new FlxSprite(0, 0);
			fallback.makeGraphic(FlxG.width, FlxG.height, 0xFF333344);
			add(fallback);
			var txtWarn:FlxText = new FlxText(0, 180, FlxG.width, "BẠN ĐÃ THẮNG!\n(Chưa nạp được ảnh bg_win.png)", 28);
			txtWarn.setFormat(null, 28, 0xFFFFFF, CENTER);
			add(txtWarn);

			return false; 
		}
		var bg:FlxSprite = new FlxSprite(0, 0);
		bg.loadGraphic(graphic);

		if (bg.frameWidth > 0 && bg.frameHeight > 0)
		{
			var scale:Float = Math.max(FlxG.width / bg.frameWidth, FlxG.height / bg.frameHeight);
			bg.scale.set(scale, scale);
			bg.updateHitbox();
			bg.screenCenter();
		}
		bg.antialiasing = true;
		add(bg);

		return true;
	}
}