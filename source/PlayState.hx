package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

typedef QuestionData = {
	var question:String;
	var answer:String;
}

class PlayState extends FlxState
{
	static inline var USE_TELEX:Bool = true;
	static inline var MAX_CHARS:Int = 30;
	static inline var CODE_DD_LOWER:Int = 0x111; 
	static inline var CODE_DD_UPPER:Int = 0x110; 

	static inline var BG_PNG:String = "images/bg_play.png";
	static inline var BTN_SKIP_PNG:String = "images/btn_skip.png";

	static inline var PROGRESS_Y:Float = 205;
	static inline var QUESTION_BOX_X:Float = 420;
	static inline var QUESTION_BOX_Y:Float = 230;
	static inline var QUESTION_BOX_W:Float = 440;
	static inline var QUESTION_BOX_H:Float = 140;
	static inline var INPUT_Y:Float = 485;
	static inline var INPUT_W:Float = 460;
	static inline var INPUT_OFFSET_X:Float = 0;
	static inline var HINT_GAP:Float = 35;       
	static inline var FEEDBACK_Y:Float = 565;     

	static var VOWELS_LOWER:Array<String> = [
		"aáàảãạ", "ăắằẳẵặ", "âấầẩẫậ", "eéèẻẽẹ", "êếềểễệ", "iíìỉĩị",
		"oóòỏõọ", "ôốồổỗộ", "ơớờởỡợ", "uúùủũụ", "ưứừửữự", "yýỳỷỹỵ"
	];
	static var VOWELS_UPPER:Array<String> = [
		"AÁÀẢÃẠ", "ĂẮẰẲẴẶ", "ÂẤẦẨẪẬ", "EÉÈẺẼẸ", "ÊẾỀỂỄỆ", "IÍÌỈĨỊ",
		"OÓÒỎÕỌ", "ÔỐỒỔỖỘ", "ƠỚỜỞỠỢ", "UÚÙỦŨỤ", "ƯỨỪỬỮỰ", "YÝỲỶỸỴ"
	];

	static var vowelOf:Map<Int, Int>;
	static var toneOf:Map<Int, Int>;
	static var lowerOf:Map<Int, Int>;
	static var upperOf:Map<Int, Int>;

	static function initTables():Void
	{
		if (vowelOf != null)
			return;
		vowelOf = new Map();
		toneOf = new Map();
		lowerOf = new Map();
		upperOf = new Map();

		for (v in 0...12)
		{
			for (t in 0...6)
			{
				var l = VOWELS_LOWER[v].charCodeAt(t);
				var u = VOWELS_UPPER[v].charCodeAt(t);
				vowelOf.set(l, v);
				toneOf.set(l, t);
				lowerOf.set(u, l);
				upperOf.set(l, u);
			}
		}
		lowerOf.set(CODE_DD_UPPER, CODE_DD_LOWER);
		upperOf.set(CODE_DD_LOWER, CODE_DD_UPPER);
		for (c in 97...123)
		{
			upperOf.set(c, c - 32);
			lowerOf.set(c - 32, c);
		}
	}

	static inline function toLowerCode(c:Int):Int
		return lowerOf.exists(c) ? lowerOf.get(c) : c;

	static inline function toUpperCode(c:Int):Int
		return upperOf.exists(c) ? upperOf.get(c) : c;

	static inline function compose(v:Int, t:Int):Int
		return VOWELS_LOWER[v].charCodeAt(t);

    //thêm câu hỏi hay bớt tùy ý nhé đăng
	private var questions:Array<QuestionData> = [
		{question: "Câu 1: Trong Tây Tiến, hình ảnh “dốc lên khúc khuỷu, dốc thăm thẳm” góp phần tạo nên vẻ đẹp gì cho bức tranh thiên nhiên?", answer: "HÙNG VĨ"},
		{question: "Câu 2: Những yếu tố như nhịp điệu, âm hưởng, sự phối hợp thanh bằng – trắc trong thơ tạo nên đặc điểm nghệ thuật này.", answer: "NHẠC TÍNH"},
		{question: "Câu 3: Những đường nét, màu sắc, không gian được gợi ra qua ngôn từ thơ ca tạo nên chất nghệ thuật này.", answer: "HỘI HỌA"},
		{question: "Câu 4: “Đêm mơ Hà Nội dáng kiều thơm” thể hiện vẻ đẹp nổi bật nào của người lính Tây Tiến?", answer: "HÀO HOA"},
		{question: "Câu 5: Sự kết hợp giữa vẻ đẹp hào hùng và nỗi đau mất mát trong hình tượng người lính tạo nên chất gì?", answer: "BI TRÁNG"}
	];

	private var currentIndex:Int = 0;
	private var wrongCount:Int = 0; 

	private var txtProgress:FlxText;
	private var txtQuestion:FlxText;
	private var txtInput:FlxText;
	private var txtFeedback:FlxText;
	private var btnSkip:FlxButton;

	private var buf:Array<Int> = [];
	private var caretTimer:Float = 0;

	private var textInputHandler:String->Void;
	private var keyDownHandler:KeyCode->KeyModifier->Void;
	private var oldVolUp:Array<flixel.input.keyboard.FlxKey>;
	private var oldVolDown:Array<flixel.input.keyboard.FlxKey>;
	private var oldMute:Array<flixel.input.keyboard.FlxKey>;

	override public function create():Void
	{
		super.create();
		initTables();

		createBackground();

		oldVolUp = FlxG.sound.volumeUpKeys;
		oldVolDown = FlxG.sound.volumeDownKeys;
		oldMute = FlxG.sound.muteKeys;
		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		txtProgress = new FlxText(0, PROGRESS_Y, FlxG.width, "");
		txtProgress.setFormat(Paths.FONT_GAME, 18, 0xFF5A4630, CENTER);
		add(txtProgress);

		txtQuestion = new FlxText(QUESTION_BOX_X, QUESTION_BOX_Y, QUESTION_BOX_W, "");
		txtQuestion.setFormat(Paths.FONT_GAME, 30, 0xFF2B1D0E, CENTER);
		add(txtQuestion);

		var inputX:Float = (FlxG.width - INPUT_W) / 2 + INPUT_OFFSET_X;

		txtInput = new FlxText(inputX, INPUT_Y, INPUT_W, "");
		txtInput.setFormat(Paths.FONT_GAME, 24, 0xFF1E4D2B, CENTER);
		add(txtInput);

		var txtHint:FlxText = new FlxText(inputX, INPUT_Y + HINT_GAP, INPUT_W, "ẤN ENTER ĐỂ TIẾP TỤC");
		txtHint.setFormat(Paths.FONT_GAME, 13, 0xFF5A4630, CENTER);
		add(txtHint);

		txtFeedback = new FlxText(inputX, FEEDBACK_Y, INPUT_W, "");
		txtFeedback.setFormat(Paths.FONT_GAME, 18, 0xFFB00020, CENTER, OUTLINE, 0xFFFFFFFF);
		add(txtFeedback);

		var btnBack:FlxButton = new FlxButton(20, 20, "", function()
		{
			FlxG.sound.play(Paths.sound("click"));
			FlxG.switchState(MenuState.new);
		});
		btnBack.makeGraphic(70, 70, 0x00000000);
		add(btnBack);
		btnSkip = new FlxButton(0, 0, "", onSkipQuestion);
		if (Paths.exists(BTN_SKIP_PNG))
		{
			btnSkip.loadGraphic(Paths.image(BTN_SKIP_PNG));
			btnSkip.setGraphicSize(100, 0); 
			btnSkip.updateHitbox();
		}
		else
		{
			btnSkip.makeGraphic(110, 35, 0xFF8B0000);
			btnSkip.label.text = "ĐÁP ÁN";
			btnSkip.label.setFormat(Paths.FONT_GAME, 12, 0xFFFFFF, CENTER);
		}
		btnSkip.x = FlxG.width - btnSkip.width - 25;
		btnSkip.y = 25;
		btnSkip.visible = false;
		add(btnSkip);

		textInputHandler = onTextInput;
		keyDownHandler = onKeyDown;
		enableInput();
		FlxG.signals.focusGained.add(enableInput);

		loadQuestion(0);
	}
	private function createBackground():Void
	{
		if (!Paths.exists(BG_PNG))
		{
			var fallback:FlxSprite = new FlxSprite(0, 0);
			fallback.makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A2E);
			add(fallback);
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
	private function enableInput():Void
	{
		if (FlxG.stage == null || FlxG.stage.window == null)
			return;

		var win = FlxG.stage.window;
		win.textInputEnabled = true;

		win.onTextInput.remove(textInputHandler);
		win.onKeyDown.remove(keyDownHandler);
		win.onTextInput.add(textInputHandler);
		win.onKeyDown.add(keyDownHandler);
	}

	override public function closeSubState():Void
	{
		super.closeSubState();
		enableInput();
	}
    private function onTextInput(text:String):Void
	{
		if (subState != null)
			return;

		for (i in 0...text.length)
		{
			var c = toLowerCode(text.charCodeAt(i));
			if (c < 32)
				continue;
			if (buf.length >= MAX_CHARS && !(USE_TELEX && c < 128))
				continue;
			typeChar(c);
		}
		txtFeedback.text = "";
		updateInputDisplay();
	}

	private function onKeyDown(code:KeyCode, mod:KeyModifier):Void
	{
		if (subState != null)
			return;

		if (code == KeyCode.BACKSPACE)
		{
			if (buf.length > 0)
				buf.pop();
			txtFeedback.text = "";
			updateInputDisplay();
		}
		else if (code == KeyCode.RETURN || code == KeyCode.NUMPAD_ENTER)
		{
			FlxG.sound.play(Paths.sound("select")); 
			checkAnswer();
		}
	}

	private function typeChar(c:Int):Void
	{
		if (USE_TELEX && c < 128 && applyTelex(c))
			return;
		if (buf.length < MAX_CHARS)
			buf.push(c);
	}
	private function wordStart():Int
	{
		var i = buf.length;
		while (i > 0 && buf[i - 1] != 32)
			i--;
		return i;
	}

	private function isVowelAt(i:Int, ws:Int):Bool
	{
		var v = vowelOf.get(buf[i]);
		if (v == null)
			return false;
		if (v == 9 && i > ws && buf[i - 1] == 113)
			return false;
		if (v == 5 && i > ws && buf[i - 1] == 103 && i + 1 < buf.length && vowelOf.exists(buf[i + 1]))
			return false;
		return true;
	}

	private function lastVowel(ws:Int):Int
	{
		var i = buf.length - 1;
		while (i >= ws)
		{
			if (isVowelAt(i, ws))
				return i;
			i--;
		}
		return -1;
	}

	private function vowelGroup(ws:Int):Array<Int>
	{
		var group:Array<Int> = [];
		var i = buf.length - 1;
		while (i >= ws)
		{
			if (isVowelAt(i, ws))
				group.unshift(i);
			else if (group.length > 0)
				break;
			i--;
		}
		return group;
	}

	private function pickTonePos(group:Array<Int>):Int
	{
		var k = group.length - 1;
		while (k >= 0)
		{
			var v = vowelOf.get(buf[group[k]]);
			if (v == 1 || v == 2 || v == 4 || v == 7 || v == 8 || v == 10)
				return group[k];
			k--;
		}
		var n = group.length;
		if (n == 1)
			return group[0];
		if (n >= 3)
			return group[1];
		if (group[1] < buf.length - 1)
			return group[1];
		var a = vowelOf.get(buf[group[0]]);
		var b = vowelOf.get(buf[group[1]]);
		if ((a == 6 && (b == 0 || b == 3)) || (a == 9 && b == 11))
			return group[1];
		return group[0];
	}

	private function setTone(i:Int, t:Int):Void
	{
		buf[i] = compose(vowelOf.get(buf[i]), t);
	}

	private function applyTelex(c:Int):Bool
	{
		var ws = wordStart();
		var len = buf.length;

		if (c == 100)
		{
			if (len > ws && buf[len - 1] == 100)
			{
				buf[len - 1] = CODE_DD_LOWER;
				return true;
			}
			return false;
		}

		if (c == 97 || c == 101 || c == 111)
		{
			var target = (c == 97) ? 0 : (c == 101 ? 3 : 6);
			var newV = (c == 97) ? 2 : (c == 101 ? 4 : 7);
			var idx = lastVowel(ws);
			if (idx >= 0 && vowelOf.get(buf[idx]) == target)
			{
				buf[idx] = compose(newV, toneOf.get(buf[idx]));
				return true;
			}
			return false;
		}

		if (c == 119)
		{
			var idx = lastVowel(ws);
			if (idx < 0)
			{
				buf.push(compose(10, 0));
				return true;
			}
			var v = vowelOf.get(buf[idx]);
			var t = toneOf.get(buf[idx]);
			if (v == 0)
			{
				buf[idx] = compose(1, t);
				return true;
			}
			if (v == 9)
			{
				buf[idx] = compose(10, t);
				return true;
			}
			if (v == 6 || v == 7)
			{
				buf[idx] = compose(8, t);
				if (idx - 1 >= ws && isVowelAt(idx - 1, ws) && vowelOf.get(buf[idx - 1]) == 9)
					buf[idx - 1] = compose(10, toneOf.get(buf[idx - 1]));
				return true;
			}
			return false;
		}

		var tone = -1;
		switch (c)
		{
			case 115: tone = 1;
			case 102: tone = 2;
			case 114: tone = 3;
			case 120: tone = 4;
			case 106: tone = 5;
			case 122: tone = 0;
		}
		if (tone >= 0)
		{
			var group = vowelGroup(ws);
			if (group.length == 0)
				return false;

			var cur = 0;
			for (i in group)
			{
				var t = toneOf.get(buf[i]);
				if (t > 0)
					cur = t;
				setTone(i, 0);
			}
			if (tone == 0)
				return cur != 0;
			if (cur == tone)
				return false;

			setTone(pickTonePos(group), tone);
			return true;
		}

		return false;
	}
	private function bufferToDisplay():String
	{
		var sb = new StringBuf();
		for (c in buf)
			sb.addChar(toUpperCode(c));
		return sb.toString();
	}

	private function normalize(codes:Array<Int>):String
	{
		var sb = new StringBuf();
		var wordTone = 0;
		var lastSpace = true;
		for (c in codes)
		{
			if (c == 32)
			{
				if (!lastSpace)
				{
					sb.add(Std.string(wordTone));
					sb.addChar(32);
				}
				wordTone = 0;
				lastSpace = true;
				continue;
			}
			lastSpace = false;
			var v = vowelOf.get(c);
			if (v != null)
			{
				var t = toneOf.get(c);
				if (t > 0)
					wordTone = t;
				sb.addChar(compose(v, 0));
			}
			else
				sb.addChar(c);
		}
		if (!lastSpace)
			sb.add(Std.string(wordTone));
		return sb.toString();
	}

	private function stringToCodes(s:String):Array<Int>
	{
		var out:Array<Int> = [];
		for (i in 0...s.length)
			out.push(toLowerCode(s.charCodeAt(i)));
		return out;
	}

	private function loadQuestion(index:Int):Void
	{
		currentIndex = index;
		buf = [];
		wrongCount = 0;
		if (btnSkip != null)
			btnSkip.visible = false;

		txtFeedback.text = "";
		txtProgress.text = 'CÂU HỎI ${currentIndex + 1} / ${questions.length}';
		txtQuestion.text = questions[currentIndex].question;

		txtQuestion.y = QUESTION_BOX_Y + (QUESTION_BOX_H - txtQuestion.height) / 2;
		updateInputDisplay();
	}

	private function updateInputDisplay():Void
	{
		var caret = (caretTimer < 0.5) ? "_" : " ";
		if (buf.length == 0)
			txtInput.text = "> " + caret;
		else
			txtInput.text = "> " + bufferToDisplay() + caret;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.stage != null && FlxG.stage.window != null && !FlxG.stage.window.textInputEnabled)
			enableInput();

		caretTimer += elapsed;
		if (caretTimer >= 1.0)
			caretTimer = 0;
		updateInputDisplay();
	}

	private function checkAnswer():Void
	{
		var cleanBuf:Array<Int> = buf.copy();
		while (cleanBuf.length > 0 && cleanBuf[0] == 32)
			cleanBuf.shift();
		while (cleanBuf.length > 0 && cleanBuf[cleanBuf.length - 1] == 32)
			cleanBuf.pop();

		var user = normalize(cleanBuf);
		var correct = normalize(stringToCodes(questions[currentIndex].answer));

		if (user == correct)
		{
			wrongCount = 0;
			if (btnSkip != null)
				btnSkip.visible = false;

			currentIndex++;

			if (currentIndex >= questions.length)
			{
				FlxG.switchState(WinState.new);
			}
			else
			{
				openSubState(new CongratsSubState(function() loadQuestion(currentIndex)));
			}
		}
		else
		{
			wrongCount++;
			txtFeedback.text = "SAI RỒI! THỬ LẠI XEM.";
			if (wrongCount >= 5 && btnSkip != null)
			{
				btnSkip.visible = true;
			}
		}
	}

	private function onSkipQuestion():Void
	{
		FlxG.sound.play(Paths.sound("click"));

		if (btnSkip != null)
			btnSkip.visible = false;

		buf = stringToCodes(questions[currentIndex].answer);
		updateInputDisplay();

		new FlxTimer().start(1.2, function(timer:FlxTimer)
		{
			wrongCount = 0;
			currentIndex++;

			if (currentIndex >= questions.length)
			{
				FlxG.switchState(WinState.new);
			}
			else
			{
				loadQuestion(currentIndex);
			}
		});
	}

	override public function destroy():Void
	{
		FlxG.signals.focusGained.remove(enableInput);

		if (FlxG.stage != null && FlxG.stage.window != null)
		{
			var win = FlxG.stage.window;
			win.onTextInput.remove(textInputHandler);
			win.onKeyDown.remove(keyDownHandler);
		}
		FlxG.sound.volumeUpKeys = oldVolUp;
		FlxG.sound.volumeDownKeys = oldVolDown;
		FlxG.sound.muteKeys = oldMute;
		super.destroy();
	}
}