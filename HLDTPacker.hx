import haxe.Json;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

typedef FileMeta = {
	var path:String;
	var size:Int;
}
class HLDTPacker
{
	public static inline var SECRET_KEY:Int = 0x7E;
	public static inline var OUTPUT_FILE:String = "assets.HLDT";
	public static inline var ASSETS_DIR:String = "assets";
	public static function main():Void
	{
		Sys.println("--- BẮT ĐẦU ĐÓNG GÓI TÀI NGUYÊN SAN .HLDT ---");

		if (!FileSystem.exists(ASSETS_DIR))
		{
			Sys.println('Lỗi: Không tìm thấy thư mục $ASSETS_DIR');
			return;
		}

		var fileList:Array<String> = [];
		scanFolder(ASSETS_DIR, fileList);

		var metadata:Array<FileMeta> = [];
		var fileBytesList:Array<Bytes> = [];

		for (filePath in fileList)
		{
			var cleanPath = StringTools.replace(filePath, "\\", "/");
			var rawBytes = File.getBytes(filePath);
			var encryptedBytes = encryptBytes(rawBytes, SECRET_KEY);

			metadata.push({
				path: cleanPath,
				size: encryptedBytes.length
			});
			fileBytesList.push(encryptedBytes);

			Sys.println('Đã đóng gói: $cleanPath (${encryptedBytes.length} bytes)');
		}
		var jsonString = Json.stringify(metadata);
		var jsonBytes = Bytes.ofString(jsonString);
		var encryptedHeader = encryptBytes(jsonBytes, SECRET_KEY);

		var output:FileOutput = File.write(OUTPUT_FILE, true);
		output.writeInt32(encryptedHeader.length);
		output.write(encryptedHeader);

		for (b in fileBytesList)
		{
			output.write(b);
		}

		output.close();
		Sys.println('--> THÀNH CÔNG! File đã được tạo: $OUTPUT_FILE');
	}
	private static function scanFolder(dir:String, outList:Array<String>):Void
	{
		for (item in FileSystem.readDirectory(dir))
		{
			var path = dir + "/" + item;
			if (FileSystem.isDirectory(path))
				scanFolder(path, outList);
			else
				outList.push(path);
		}
	}
	public static function encryptBytes(bytes:Bytes, key:Int):Bytes
	{
		var out = Bytes.alloc(bytes.length);
		for (i in 0...bytes.length)
		{
			out.set(i, bytes.get(i) ^ key);
		}
		return out;
	}
}