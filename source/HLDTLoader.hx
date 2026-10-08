package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import haxe.Json;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;

typedef FileMeta = {
	var path:String;
	var size:Int;
}

class HLDTLoader
{
	public static inline var SECRET_KEY:Int = 0x7E;

	private static var fileMap:Map<String, Bytes> = new Map();
	private static var soundCache:Map<String, Sound> = new Map();
	private static var graphicCache:Map<String, FlxGraphic> = new Map();
	private static var fontCache:Map<String, String> = new Map();

	public static function init(pakPath:String = "assets.HLDT"):Void
	{
		if (!FileSystem.exists(pakPath))
		{
			trace('[HLDTLoader] Không tìm thấy $pakPath (Sẽ dùng assets thư mục thường nếu có)');
			return;
		}

		try
		{
			var input:FileInput = File.read(pakPath, true);
			var headerLen:Int = input.readInt32();
			var encHeader:Bytes = input.read(headerLen);
			var decHeader:Bytes = decryptBytes(encHeader, SECRET_KEY);
			var metadata:Array<FileMeta> = Json.parse(decHeader.toString());
			for (meta in metadata)
			{
				var encData:Bytes = input.read(meta.size);
				var decData:Bytes = decryptBytes(encData, SECRET_KEY);

				var normPath = normalizePath(meta.path);
				fileMap.set(normPath, decData);

				for (variant in getVariants(normPath))
				{
					fileMap.set(variant, decData);
				}

				cacheAsset(normPath, decData);
			}

			input.close();
			trace('[HLDTLoader] Nạp thành công ${metadata.length} tài nguyên từ $pakPath!');
		}
		catch (e:Dynamic)
		{
			trace('[HLDTLoader] Lỗi khi nạp gói HLDT: ' + e);
		}
	}

	public static function normalizePath(path:String):String
	{
		return StringTools.replace(path, "\\", "/");
	}

	public static function getVariants(path:String):Array<String>
	{
		var clean = normalizePath(path);
		var list:Array<String> = [clean];
		if (StringTools.startsWith(clean, "assets/"))
			list.push(clean.substr(7));
		else
			list.push("assets/" + clean);
		return list;
	}

	private static function cacheAsset(path:String, bytes:Bytes):Void
	{
		var variants = getVariants(path);

		if (StringTools.endsWith(path, ".png") || StringTools.endsWith(path, ".jpg"))
		{
			var bmp:BitmapData = BitmapData.fromBytes(bytes);
			if (bmp != null)
			{
				var graphic = FlxGraphic.fromBitmapData(bmp, false, path);
				graphic.persist = true;

				if (StringTools.endsWith(path, ".png") || StringTools.endsWith(path, ".jpg"))
		{
			var bmp:BitmapData = BitmapData.fromBytes(bytes);
			if (bmp != null)
			{
				var graphic = FlxGraphic.fromBitmapData(bmp, false, path);
				graphic.persist = true;
				graphic.destroyOnNoUse = false;

				for (v in variants)
				{
					graphicCache.set(v, graphic);
					FlxG.bitmap.addGraphic(graphic);
				}
			}
		}

				for (v in variants)
				{
					graphicCache.set(v, graphic);
					FlxG.bitmap.addGraphic(graphic);
				}
			}
		}
		else if (StringTools.endsWith(path, ".ogg") || StringTools.endsWith(path, ".wav"))
		{
			var audioBuffer = AudioBuffer.fromBytes(bytes);
			if (audioBuffer != null)
			{
				var sound = Sound.fromAudioBuffer(audioBuffer);
				for (v in variants)
				{
					soundCache.set(v, sound);
					Assets.cache.setSound(v, sound);
				}
			}
		}
		else if (StringTools.endsWith(path, ".ttf") || StringTools.endsWith(path, ".otf"))
		{
			try
			{
				var font = Font.fromBytes(bytes);
				if (font != null)
				{
					Font.registerFont(font);
					for (v in variants)
					{
						fontCache.set(v, font.fontName);
					}
				}
			}
			catch (e:Dynamic)
			{
				trace('[HLDTLoader] Lỗi nạp font $path: ' + e);
			}
		}
	}

	public static function exists(path:String):Bool
	{
		for (v in getVariants(path))
		{
			if (graphicCache.exists(v) || soundCache.exists(v) || fileMap.exists(v))
				return true;
		}
		return Assets.exists(path);
	}

	public static function hasSound(path:String):Bool
	{
		for (v in getVariants(path))
			if (soundCache.exists(v)) return true;
		return false;
	}

	public static function getSound(path:String):Sound
	{
		for (v in getVariants(path))
			if (soundCache.exists(v)) return soundCache.get(v);
		return null;
	}

	public static function hasGraphic(path:String):Bool
	{
		for (v in getVariants(path))
			if (graphicCache.exists(v)) return true;
		return false;
	}

public static function getGraphic(path:String):FlxGraphic
	{
		for (v in getVariants(path))
		{
			if (FlxG.bitmap.get(v) != null)
			{
				var graph:FlxGraphic = FlxG.bitmap.get(v);
				if (graph != null && graph.bitmap != null)
				{
					return graph;
				}
				else
				{
					FlxG.bitmap.removeByKey(v);
				}
			}
			var bytes:Bytes = getBytes(v);
			if (bytes != null)
			{
				try
				{
					var bmp:BitmapData = BitmapData.fromBytes(bytes);
					if (bmp != null)
					{
						var graph:FlxGraphic = FlxGraphic.fromBitmapData(bmp, false, v);
						graph.persist = true;
						graph.destroyOnNoUse = false;
						return graph;
					}
				}
				catch (e:Dynamic)
				{
					trace('[HLDTLoader] Lỗi tạo BitmapData từ $v: ' + e);
				}
			}
		}
		return null;
	}

	public static function getFontName(path:String):String
	{
		for (v in getVariants(path))
			if (fontCache.exists(v)) return fontCache.get(v);
		return null;
	}

	public static function getBytes(path:String):Bytes
	{
		for (v in getVariants(path))
			if (fileMap.exists(v)) return fileMap.get(v);
		return null;
	}

	public static function getText(path:String):String
	{
		var b = getBytes(path);
		if (b != null) return b.toString();
		if (Assets.exists(path)) return Assets.getText(path);
		return null;
	}

	private static function decryptBytes(bytes:Bytes, key:Int):Bytes
	{
		var out = Bytes.alloc(bytes.length);
		for (i in 0...bytes.length)
			out.set(i, bytes.get(i) ^ key);
		return out;
	}
}