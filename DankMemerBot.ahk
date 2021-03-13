;Dank Memer Bot v1-beta.1
;Made by JoReggel
;Chrome.ahk v1.2, https://github.com/G33kDude/Chrome.ahk
;polyethene, Int to Bin, https://autohotkey.com/board/topic/12355-lite-decimal-to-binary-and-vice-versa-conversion-functions/
;Chrome AHK modification for error "Hangs on while !this.responses[ID]", https://github.com/G33kDude/Chrome.ahk/issues/16

#Include Chrome.ahk/Chrome.ahk

global webpage
global tempwebpage
global url
global apiUrl
global token
global lastSent

global DailyFreq := -86400000 ;24H = 86400000ms
global KeepAwakeFreq := -300000 ;5min
global DepositFreq := -70200 ;70s
global RandDelayFreq := -60800 ;60s
global PostmemesFreq := -60600 ;60s
global HuntFreq := -60400 ;60s
global FishFreq := -60200 ;60s
global BegFreq := -45200 ;45s
global SearchFreq := -30200 ;30s
global HighLowFreq := -20200 ;20s

Start: ;Creation of front end gui
{
	Gui, New, -SysMenu, Dank Memer Bot
	Gui, Margin, 40, 10
	Gui, Add, Text,, Press start to begin
	Gui, Add, Button, gUserInput, Start ;Go to user input page
	Gui, Add, Button, gAbout, About
	Gui, Add, Button, gExit, Exit
	Gui, Show, Center
	return
}

About:
{
	MsgBox, 4096, ABOUT,
(
Dank Memer Bot
Made by JoReggel`n
v1-beta.1`n
https://github.com/JoReggel/DankMemerBot
)
	return
}

Exit:
	ExitApp

GuiClose:
	ExitApp

UserInput: ;Ask user for required data
{
	Gui, Destroy
	;Ask user for channel url, name and token
	InputBox,channelUrl,, Enter text channel URL (Exclude "/" at end of URL),, 500, 125
	inputCheck(channelUrl)
	InputBox,channelName,, Enter text channel name E.g. #Channel-Name,, 500, 125
	inputCheck(channelName)
	InputBox,token,, Enter your token,, 500, 125
	inputCheck(token)

	;Retrieve the channel ID from the channel url
	pos := InStr(channelUrl, "/",, StartingPos := 0) + 1 ;Retrieve the starting char position of the channel id
	channelID := SubStr(channelUrl, pos) ;Retrieve the channel id from the url

	groupName := channelName + " - Google Chrome" ;This is for groupbrowser name
	GroupAdd, GroupBrowsers, %groupName% ;Save the chrome's discord active window name

	if !WinExist("ahk_exe chrome.exe") ;If chrome.exe not running, exit.
	{
		inputExit()
	}

	webpage := Chrome.GetPageByTitle(channelName) ;Assign chrome tab name with the discord channel

	url := channelUrl ;For send message function
	apiUrl := "https://discord.com/api/v8/channels/" . channelID . "/messages" ;For send message function

	GoTo, webCheck ;Data collection finished. Continue to webCheck
	return

	inputCheck(x) ;Exit if user press cancel
	{
		if ErrorLevel
		{
    		inputExit()
		}
		if StrLen(x) == 0
		{
			inputExit()
		}
	}

	inputExit()
	{
		Gui, New, -SysMenu, Dank Memer Bot
		Gui, Margin, 40, 10
		Gui, Add, Text,, No data or Chrome is not running or "Cancel" is pressed.`n`nBot Exiting.
		Gui, Show, Center
		Sleep, 3000
		GoSub, Exit
	}
}

webCheck: ;Check if user selected chrome tab exist
{	
	IfWinNotActive, ahk_group GroupBrowsers
	{
		webExit()
	}
	if (!IsObject(webpage))
	{
		webExit()
	}
	GoTo, Main
	return

	webExit()
	{
		Gui, Destroy
		Gui, New, -SysMenu, Dank Memer Bot
		Gui, Margin, 40, 10
		Gui, Add, Text,, Webpage Not Found. Bot Exiting.
		Gui, Show, Center
		Sleep, 3000
		GoSub, Exit
	}
}

Main: ;Main program cycle
{
	WinActivate, ahk_exe chrome.exe
	Msgbox, Switch to discord chrome tab if you haven't done so.
	webpage.Evaluate("alert('IMPORTANT!\n\You can do whatever you want now but do not close this chrome tab until you close the bot.\n\Sometimes the bot will hang. Just exit and start the bot again.\n\Click OK to continue.');")

	if (!WinExist("Dank Memer Bot"))
	{
		Gui, New, -SysMenu, Dank Memer Bot
		Gui, Margin, 40, 10
		Gui, Add, Text,, Bot Running...
		Gui, Add, Button, gExit, Exit
		Gui, Show, Center
	}

	Queue := []

	Gosub, Daily
	Gosub, KeepAwake
	Gosub, Deposit
	Gosub, Postmemes
	
	SetTimer, Hunt, %HuntFreq% ;Ensure this event will run again in case its removed by QueueManager at first run
	SetTimer, Fish, %FishFreq% ;Ensure this event will run again in case its removed by QueueManager at first run
	
	Gosub, Hunt
	Gosub, Fish
	Gosub, Beg
	Gosub, Search
	Gosub, HighLow

	Loop ;This is the FIFO queue manager where it executes all the function
	{
		Sleep, 1000 ;queue manager only executes every 1 seconds
		if (WinExist("ahk_exe chrome.exe") || WinExist("ahk_exe msedge.exe")) ;Check if chrome.exe is active
		{
			;Check if discord chrome tab is active. Only certain function can run when it is active.
			IfWinActive, ahk_group GroupBrowsers
			{
				runEvent()
			}
			IfWinNotActive, ahk_group GroupBrowsers ;When the function to run cannot do it without active window, it will be removed
			{
				Loop, % Queue.MaxIndex()
				{
					if (Queue[1] == "runFish" || Queue[1] == "runHunt")
					{
						Queue.RemoveAt(1)
					}
					else
					{
						break
					}
				}
			}
		
			Queue[1]()
			Queue.RemoveAt(1)
		}
		else
		{
			GoTo, webCheck
		}
	}

	return
}
;----------------------------------------
;This is where function can be defined to push to the queue manager. It is only the function name in queue. The actual function is next section.
Daily:
{
	Queue.Push("runDaily")
	return
}

KeepAwake:
{
	Queue.Push("runKeepAwake")
	return
}

Deposit:
{
	Queue.Push("runDeposit")
	return
}

RandDelay:
{
	Queue.Push("runRandDelay")
	return
}

Postmemes:
{
	Queue.Push("runPostmemes")
	return
}

Hunt:
{
	Queue.Push("runHunt")
	return
}

Fish:
{
	Queue.Push("runFish")
	return
}

Beg:
{
	Queue.Push("runBeg")
	return
}

Search:
{
	Queue.Push("runSearch")
	return
}

HighLow:
{
	Queue.Push("runHighLow")
	return
}
;----------------------------------------
;This is all the actual function
runDaily()
{
	SendMsg("pls daily")
	SetTimer, Daily, %DailyFreq%
	return
}

runKeepAwake()
{
	MouseMove, 0, 0, 0, R
	SetTimer, KeepAwake, %KeepAwakeFreq%
	return
}

runDeposit()
{
	SendMsg("pls deposit max")
	SetTimer, Deposit, %DepositFreq%
	return
}

runRandDelay()
{
	Random, x, 5000, 15000
	Sleep,  x
	SetTimer, RandDelay, %RandDelayFreq%
	return
}

runPostmemes()
{
	memesArray := ["f","r","i","c","k"]
	Random, x, 1, memesArray.MaxIndex()
	SendMsg("pls postmemes")
	standby("What type of meme do you want to post?", 3000)
	SendMsg(memesArray[x])
	SetTimer, Postmemes, %PostmemesFreq%
	return
}

runHunt()
{
	SendMsg("pls hunt")
	standby("@aviate", 3000)
	ans := FishHuntCheck(chatID(1), chatMsg(chatID(1), "outerText"), "Holy fricking ship")
	if (ans != "")
	{
		SendInput, %ans% {Enter}
	}
	SetTimer, Hunt, %HuntFreq%
	return
}

runFish()
{
	SendMsg("pls fish")
	standby("@aviate", 3000)
	ans := FishHuntCheck(chatID(1), chatMsg(chatID(1), "outerText"), "ahhhhh")
	if (ans != "")
	{
		SendInput, %ans% {Enter}
	}
	SetTimer, Fish, %FishFreq%
	return
}

runBeg()
{
	SendMsg("pls beg")
	SetTimer, Beg, %BegFreq%
	return
}

runSearch()
{
	SendMsg("pls search")
	standby("Where do you want to search?", 3000)
	SendMsg(SearchSelector(chatID(1)))
	SetTimer, Search, %SearchFreq%
	return
}

runHighLow()
{
	SendMsg("pls highlow")
	Sleep, 2000
	SendMsg("low")
	SetTimer, HighLow, %HighLowFreq%
	return
}
;----------------------------------------
;These are function called by the above functions
runEvent()
{
	Loop, 7
	{
		id := chatID(A_Index)
		if (InStr(chatMsg(id, "outerText"), "EVENT TIME") > 0)
		{
			id := chatID(A_Index - 1)
			
			base = document.querySelector("#%id% > div.contents-2mQqc9 > div > code").outerText

			ans := jsEval(base)
			
			if (ans != "" && ans != lastSent)
			{
				lastSent := ans
				SendInput, %ans% {Enter}
			}
		}
	}
	return
}

FishHuntCheck(id, content, searchStr) ;To type the required sentences when during hunt/fish
{
	if (InStr(content, searchStr, true) > 0)
	{	
		base = document.querySelector("#%id% > div.contents-2mQqc9 > div > code").outerText ;>>>"id" is var
		
		return jsEval(base) ;>>>Returning the sentence that is required to be typed
	}
	
	return
}

SearchSelector(id) ;>>>Selecting the best option out of the given 3 when doing search
{
	;>>>Initializing variables and arrays. places array is arranged from the worse odds at 1st index to best odds at last index
	;places := ["car","discord","sink","dog","pocket","tree","bus","laundromat","attic","grass","couch","shoe","pantry","mailbox","bushes","glovebox","uber","dresser","coat","air"]
	places := ["santa claus","christmas tree","christmas card","advent calendar","mistletoe","vacuum","fridge"]
	point := 1
	count := 3
	Loop, 3 ;Looping 3 times since we know there is 3 options and the html code is nth-child 3,4,5.
	{
		base = document.querySelector("#%id% > div.contents-2mQqc9 > div > code:nth-child( %count% )").outerText ;>>>"id" & "count" is var
		
		option := jsEval(base) ;>>> Retrieve the option text
		
		;>>>It runs the string through the array and see it matches at which places array index
		Loop, % places.MaxIndex()
		{
			if (option == places[A_Index])
			{
				if (A_Index > point)
				{
					point := A_Index ;>>>Override as the highest point if the current index is higher than previous index
				}
				break
			}
		}
		count++
	}

	;>>>If no matches is found for all 3 strings, then use first index answer
	return places[point]
}

chatID(indexPos) ;>>>Retrieve the chat ID, 1 is the latest
{
	base = document.querySelector("#app-mount > div.app-1q1i1E > div > div.layers-3iHuyZ.layers-3q14ss > div > div > div > div > div.chat-3bRxxu > div > main > div.messagesWrapper-1sRNjr.group-spacing-16 > div > div > div")
	
	baseLen := base . .childNodes.length ;>>>adding ".childNodes.length"

	chatMsgID = %base% .childNodes[ %baseLen% - %indexPos% - 1 ].id ;>>>Adding ".childNodes[X].length" with X being "baseLen"

	return jsEval(chatMsgID)
}

chatMsg(id, type) ;>>>Returns the texts in the message
{
	base = document.querySelector("#%id% > div.contents-2mQqc9 > div").%type% ;>>>"id", "type" is var
	
	return jsEval(base)
}

chatIdGen() ;>>>snowflake generator
{
	time := A_NowUTC
	EnvSub, time, 19700101000000, s ;>>>Current time in unix seconds
	time := (time * 1000) - 1420070400000 ;>>>Convert to milliseconds and deduct from discord's epoch ms
	binArray := StrSplit(toBin(time)) ;Convert time to binary and then assign each char to an array
	if (binArray.MaxIndex() < 42) ;>>>Idea is to push all the value to the right to increase binary length
	{
		Loop
		{
			newpos := binArray.Push("x")
			Loop
			{
				binArray[newpos] := binArray[newpos - 1]
				newpos--
			} Until newpos == 1
			binArray[1] := 0
		} Until binArray.MaxIndex() == 42
	}
	if (binArray.MaxIndex() > 42) ;>>>Idea is to remove the front 0 to shorten the binary length
	{
		newpos := binArray.MaxIndex() - 42
		Loop, % newpos
		{
			binArray.RemoveAt(1)
		}
	}
	Loop, % binArray.MaxIndex() ;>>>Modified binary is in array so we are changing to string
	{
		binary2 := binary2 . binArray[A_Index]
	}
	
	binary2 := binary2 . "0000000000000000000000" ;>>>combining all required binary values
	
	return toInt(binary2) ;>>>return the snowflake value
}

SendMsg(msgStr) ;>>>Send message command
{
	serial := chatIdGen()
	js =
	(
		fetch("%apiUrl%", {
			"headers": {
			"accept": "*/*",
			"accept-language": "en-US",
			"authorization": "%token%",
			"content-type": "application/json",
			"sec-fetch-dest": "empty",
			"sec-fetch-mode": "cors",
			"sec-fetch-site": "same-origin",
		},
		"referrer": "%url%",
		"referrerPolicy": "strict-origin-when-cross-origin",
		"body": "{\"content\":\"%msgStr%\",\"nonce\":\"%serial%\",\"tts\":false}",
		"method": "POST",
		"mode": "cors"
		});
	)

	jsEval(js)
	
	return
}

toBin(i, s = 0, c = 0)
{
	l := StrLen(i := Abs(i + u := i < 0))
	Loop, % Abs(s) + !s * l << 2
		b := u ^ 1 & i // (1 << c++) . b
	Return, b
}

toInt(b, s = 0, c = 0) {
	Loop, % l := StrLen(b) - c
		i += SubStr(b, ++c, 1) * 1 << l - c
	Return, i - s * (1 << l)
}

standby(str, limit)
{
	sleep, 100
	start := A_TickCount
	Loop
	{
		if (A_TickCount - start >= limit)
		{
			break
		}
		if (InStr(chatMsg(chatID(1), "outerText"), str) > 0)
		{
			break
		}
	}
	return
}

jsEval(str)
{
	try
	{
		x := webpage.Evaluate(str).value
	}
	return x
}