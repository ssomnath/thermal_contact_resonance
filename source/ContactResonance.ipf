#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "UIUC"
	Submenu "Lorentz"
		"Contact Resonance Sweep", CRSweepDriver()
	End
End

Function CRSweepDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F CRSweepPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:CRSweep
	
	Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	Variable/G gSweepWidth= mastervariables[%SweepWidth][%Value]/1000;
	Variable/G gDriveFreq = mastervariables[%DriveFrequency][%Value]/1000;
		
	Variable dCOffset = NumVarOrDefault(":gDCOffset",0)
	Variable/G gDCOffset= dCOffset
	
	Variable showTable = NumVarOrDefault(":gshowTable",0)
	Variable/G gshowTable= showTable	
	
	Variable Vstart = NumVarOrDefault(":gVstart",1)
	Variable/G gVstart= Vstart
	
	Variable Vend = NumVarOrDefault(":gVend",1.1)
	Variable/G gVend= Vend
	
	Variable dVolts = NumVarOrDefault(":gVStep",0.1)
	
	Variable/G gVStep= dVolts
	
	Variable/G gNumVoltSteps =  1 + floor(((gVend - gVstart)/gVstep));
	
	Variable/G gProgress= 0
	
	Variable/G gAbortTunes = 0
	
	String pathname = StrVarOrDefault(":gPathName","C:Users:somnath2:Desktop:");
	String/G gPathName = pathname
	
	String basename = StrVarOrDefault(":gBaseName","Sample");
	String/G gBaseName = basename
	
	String/G gPrevBaseName = basename
	
	String/G gTimeLeft = "";
	
	Variable sweepIndex = NumVarOrDefault(":gSweepIndex",1)
	Variable/G gSweepIndex = sweepIndex
		
	// Create the control panel.
	Execute "CRSweepPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End


Window CRSweepPanel(): Panel

	String dfSave = GetDataFolder(1)
	SetDataFolder root:Packages:CRSweep
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 820,460) as "Contact Resonance Sweeps"
	SetDrawLayer UserBack
		
	
	SetVariable sv_StartV,pos={16,16},size={112,18},title="DC initial (V)", limits={0,10,1}
	SetVariable sv_StartV,value= root:packages:CRSweep:gVstart,live= 1
	
	ValDisplay vd_CurrVoltage,pos={149,18},size={35,20},mode=0, live=1
	ValDisplay vd_CurrVoltage, value=root:Packages:CRSweep:gDCOffset
	
	SetVariable sv_EndV,pos={210,16},size={105,20},title="Final (V)", limits={0.1,10,1}
	SetVariable sv_EndV, value=root:Packages:CRSweep:gVend
	
	SetVariable sv_VdcStep,pos={187,55},size={129,18},title="DC step (V)", limits={0.001,9,0.01}
	SetVariable sv_VdcStep,value= root:packages:CRSweep:gVStep,live= 1
	
	SetVariable sv_driveFreq,pos={16,55},size={155,18},title="Drive Freq (kHz)", limits={1,999,1}
	SetVariable sv_driveFreq,value= root:packages:CRSweep:gDriveFreq,live= 1, proc=updateDriveFreq;
				
	SetVariable sv_SweepWidth,pos={16,97},size={165,18},title="Sweep Width (kHz)", limits={1,inf,1}
	SetVariable sv_SweepWidth,live= 1,value=root:Packages:CRSweep:gSweepWidth,proc=updateSweepWidth;
	
	SetVariable TuneTimeSetVar_3,pos={196,97},size={120,18},title="Time (sec)", limits={0,inf,1}, proc=setMyTuneTime
	SetVariable TuneTimeSetVar_3, value=root:packages:MFP3D:Main:Variables:ThermalVariablesWave[%TuneTime][%Value]
		
	SetVariable sv_PathName,pos={16,133},size={300,25},title="File Path"
	SetVariable sv_PathName, value=root:Packages:CRSweep:gPathName	
	
	SetVariable sv_ImageBaseName,pos={16,168},size={203,25},title="Base Name"
	SetVariable sv_ImageBaseName, value=root:Packages:CRSweep:gBaseName, proc=updateBaseName
	
	SetVariable sv_suffix,pos={227,168},size={88,18},title="Suffix", limits={1,inf,1}
	SetVariable sv_suffix,value= root:packages:CRSweep:gSweepIndex,live= 1	
	
	ValDisplay vd_Progress,pos={16,203},size={300,20},title="Progress", mode=0, live=1
	ValDisplay vd_Progress,limits={0,100,0},barmisc={0,40},highColor= (0,43520,65280)
	ValDisplay vd_Progress, value=root:Packages:CRSweep:GProgress
		
	SetVariable vd_timeLeft,pos={167,203},size={65,20},disable=2, title=" ";
	SetVariable vd_timeLeft,value=root:Packages:CRSweep:gTimeLeft,live= 1
	
	Button but_StartRamp,pos={37,236},size={114,25},title="Start", proc=startTunes	
	
	Button but_stop,pos={187,236},size={114,25},title="Stop", proc=StopSweeps
	
	SetDataFolder dfSave
		
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 143,295, "\Z13Suhas Somnath, UIUC 2014"
End	


Function updateBaseName(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			
			String dfSave = GetDataFolder(1)
			SetDataFolder root:Packages:CRSweep
			SVAR gBaseName, gPrevBaseName
			NVAR gSweepIndex
			
			if(cmpstr(gBaseName, gPrevBaseName))
				gPrevBaseName = gBaseName;
				gSweepIndex = 1;
			endif
	
			SetDataFolder dfSave;
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function updateSweepWidth(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
						
			Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
			mastervariables[%SweepWidth][%Value] = sva.dval*1000; // sweep width (Hz)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function updateDriveFreq(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
						
			Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
			mastervariables[%DriveFrequency][%Value] = sva.dval*1000; // sweep width (Hz)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function setMyTuneTime(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval + " S"

			TuneSetVarFunc("TuneTimeSetVar_3",dval,sval,"ThermalVariablesWave[%TuneTime][%Value]")		//takes care of all of the SetVars on the Tune panel

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
	
		//String ctrlName
	//Variable varNum
	//String varStr			//this contains any letters as clues for range changes
	//String varName
end

Function StopSweeps(ctrlname) : ButtonControl
	String ctrlname
	
	td_wv("lockin.DCOffset",0);
	
	String dfSave = GetDataFolder(1)
		
	SetDataFolder root:Packages:CRSweep
	NVAR gAbortTunes, gDCOffset, gSweepIndex
	
	// stop background function here.
	gDCOffset = 0;
	gAbortTunes = 1
	gSweepIndex = gSweepIndex+1;

	ModifyControl but_StartRamp, disable=0, title="Start"
	
	SetDataFolder dfSave
	
End

function startTunes(ctrlname) : ButtonControl
	String ctrlName;
	
	// Load PFM Mode and lock crosspoint:
	ContactResonanceXPTLock()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gProgress
	SVAR gTimeLeft
	gTimeLeft = ""
	
	
	// Use these waves if you want to swep multiple eigenmodes
	//Make/O/N=1 freqWave;
	//freqWave[0] = 138.5;
	//freqWave[1] = 186;
	//freqWave[2] = 639;<----
	//freqWave[3] = 680;
	//freqWave[4] = 828.2;//<----
	//freqWave[5] = 265;//<----
	//freqWave[6] = 680.8;
	//freqWave[7] = 990.5;
	
	//Make/O/N=1 widthWave;
	//widthWave[0] = 10;
	//widthWave[1] = 10;
	//widthWave[2] = 30;
	//widthWave[3] = 30;
	//widthWave[4] = 30;
	//widthWave[5] = 30;
	//widthWave[6] = 30;
	//widthWave[7] = 10;
	//Wave freqWave
	
	Variable/G gIterStartTick= 0
	Variable/G gIteration = 0
	gProgress= 0
	Variable/G gNumTunes = 1//DimSize(freqWave,0);
	
	Variable/G gVoltIteration = 0;
	NVAR gVend, gVstart, gVstep, gNumVoltSteps;
	gNumVoltSteps =  1 + floor(((gVend - gVstart)/gVstep));
	
	Make/O/N=0 TuneWave
	
	SetDataFolder dfSave
	
	// set window size here:
	//Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	//mastervariables[18][0] = widthWave[gIteration] *1000; // sweep width (Hz)
	//mastervariables[%SweepWidth][%Value] = widthWave[gIteration] *1000; // sweep width (Hz)
	
	//FMapSetVarFunc(InfoStruct)
		
	ModifyControl but_startRamp, disable=2, title="Running.."

	// Starting background process here:
	ARBackground("bgTuneIterations",100,"")
end



Function bgTuneIterations()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gAbortTunes, gIterStartTick, gIteration
	NVAR gVstart, gVstep, gVoltIteration, gNumVoltSteps, gDCOffset;
	
	//Wave freqWave,widthWave
	
	Wave thermalWave = root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	Variable tuneDuration = thermalWave[%TuneTime][%Value];
			
	if(gAbortTunes)
		// safety precautions before exit
		td_wv("lockin.DCOffset",0);
		ModifyControl but_startRamp, disable=0, title="Start"
		gAbortTunes = 0;
		SetDataFolder dfSave
		return 1;
	endif
	
	// Case 1: Begining of iteration - Must begin tune
	if(gIterStartTick == 0)
				
		// set drive freq and sweep width here:
		//Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
		//mastervariables[17][0] = freqWave[gIteration] * 1000; // freq (Hz)
		
		// Cannot set using td_wv since it will be reset in GetDDSOffset() in Thermal.ipf
		// td_wv("lockin.DCOffset",gVstart + gVoltIteration*gVStep);
		// Use global variable to modify GetDDSOffset()
		gDCOffset = gVstart + gVoltIteration*gVStep;
		GetDDSOffset()
		
		// I am noticing that the GetDDSOffset() is called when we want to do a tune, not before or after. 				
		CantTuneFunc("DoTuneOnce_3")
		
		//print "DC offset was set to " + num2str(td_rv("lockin.DCOffset"));
		
		gIterStartTick = ticks
		SetDataFolder dfSave
		//print("very first")
		return 0;
	endif
	
	// Tune is running / has run at this stage
	
	NVAR gNumTunes, gProgress, gShowTable
	SVAR gTimeLeft
	Wave TuneWave;
	
	if(ticks >= (gIterStartTick+(round(tuneDuration+0.5)* 60)))
		
		// Case 2: Completed tune
		
		// save values
		Wave freq = root:Packages:MFP3D:Tune:Frequency
		Wave amp = root:Packages:MFP3D:Tune:Amp
		
		if(gIteration == 0)
			Concatenate/O {freq,amp},TuneWave;
		else
			Concatenate/O {TuneWave,freq,amp},tempWave;
			killWaves TuneWave; rename tempWave, TuneWave;
		endif
		
		
		// update globals
		gIteration = gIteration+1;
		
		Variable numItersPending = (gNumTunes*gNumVoltSteps) - (gIteration + gVoltIteration*gNumTunes);
		numItersPending = round(numItersPending*(tuneDuration+0.5));
		gTimeLeft = num2str(floor(numItersPending/60)) + " m " + num2str(mod(numItersPending,60)) + " s"
		
		Variable tmep = (gIteration + gVoltIteration*gNumTunes)/(gNumTunes*gNumVoltSteps);
		gProgress = min(100,floor(tmep*100));
		
		// reset timer
		gIterStartTick = 0;
		
		SetDataFolder root:packages:CRSweep
		NVAR gDCOffset, gSweepIndex
		
		// switch to next Vtot if all tunes are complete
		if(gIteration == gNumTunes)
		
			//if(gShowTable)
				//print GetDataFolder(1)
				//Wave TuneWave
				//Edit/K=1 TuneWave
			//endif
			
			// write table to file:
			writeDataToDisk(gVstart + gVoltIteration*gVStep)
		
			// update indices
			gVoltIteration = gVoltIteration +1;
			gIteration = 0;
			
			// clean up here and exit BG
			
			if(gVoltIteration == gNumVoltSteps)
				gSweepIndex = gSweepIndex+1;
				//print "ending background function now"
				gDCOffset = 0;
				td_wv("lockin.DCOffset",0);
				SetDataFolder dfSave
				ModifyControl but_startRamp, disable=0, title="Start"
				
				// withdraw the cantilever to prevent damage:
				//SimpleEngageMe("SimpleEngageButton")
				
				return 1;
				
			endif
			
		endif

	endif
	
	// Case 3: Tune is still running OR new tune will start
	SetDataFolder dfSave
	return 0;

End

function writeDataToDisk(Vtot)
	Variable Vtot
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:CRSweep
	
	SVAR gBaseName, gPathName
	NVAR gSweepIndex
		
	Wave TuneWave
	
	//1. Get the correct path and file name of the file
	
			//Flags:
		// /C:	The folder specified by "path" is created if it does not already exist.
		// /O	Overwrites the symbolic path if it exists.
		// /Q	Suppresses printing path information in the history
		// /Z	Doesn't generate an error if the folder does not exist.
	String temp = gBaseName + "_" + num2str(gSweepIndex);
	NewPath/O/Q/C Path1, gPathName+ temp + ":"

	String basefilename = temp + "_V_" + num2str(Vtot) + ".txt";
	
	//2. write to file
		// O - overwrite ok, J - tab limted
	Save /O/J/P=Path1 TuneWave as (basefilename)

	Redimension /N=(0) TuneWave
	
	SetDataFolder dfSave
	
end

Function ContactResonanceXPTLock()

	XPTPopupFunc("LoadXPTPopup",8,"PFMMeter")
	WireXpt4("BNCOut0Popup","DDS")
	XPTBoxFunc("XPTLock10Box_0",1)
	
	WireXpt4("ChipPopup","Ground")
	XPTBoxFunc("XPTLock14Box_0",1)	
	
	WireXpt4("ShakePopup","Ground")
	XPTBoxFunc("XPTLock15Box_0",1)	
		
	XptButtonFunc("WriteXPT")
	XPTButtonFunc("ResetCrosspoint")
	 // seems to annul all the changes made so far if I used td_WS

End

Function WireXpt4(whichpopup,channel)
	String whichpopup, channel
	
	execute("XPTPopupFunc(\"" + whichpopup + "\",WhichListItem(\""+ channel +"\",Root:Packages:MFP3D:XPT:XPTInputList,\";\",0,0)+1,\""+ channel +"\")")

End