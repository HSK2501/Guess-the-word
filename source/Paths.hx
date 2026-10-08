package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;

class Paths
{
	public static inline var FONT_GAME:String = "Arial";

	public static function exists(key:String):Bool
	{
		return HLDTLoader.exists(key) || Assets.exists(key);
	}

	public static function image(key:String):FlxGraphic
	{
		var graph:FlxGraphic = HLDTLoader.getGraphic(key);
		if (graph != null && graph.bitmap != null)
			return graph;
		if (Assets.exists(key))
		{
			graph = FlxG.bitmap.add(key, false, key);
			if (graph != null)
			{
				graph.persist = true;
				graph.destroyOnNoUse = false;
				return graph;
			}
		}

		trace('[Paths] KHÔNG THỂ NẠP ẢNH: ' + key);
		return null;
	}

	public static function text(key:String):String
	{
		return HLDTLoader.getText(key);
	}

	public static function sound(key:String):Dynamic
	{
		var candidates:Array<String> = [
			'assets/sounds/$key.ogg',
			'sounds/$key.ogg',
			'assets/$key.ogg',
			'$key.ogg',
			key
		];

		for (path in candidates)
		{
			if (HLDTLoader.hasSound(path))
				return HLDTLoader.getSound(path);
			if (Assets.exists(path))
				return path;
		}

		return key;
	}
}