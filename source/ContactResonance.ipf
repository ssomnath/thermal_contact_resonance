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
		
	Variable sweepWidth = NumVarOrDefault(":gSweepWidth",10)
	Variable/G gSweepWidth= sweepWidth; // kHz
	
	Variable tuneDuration = NumVarOrDefault(":gTuneDuration",3)
	Variable/G gTuneDuration= tuneDuration // sec
	
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
	
	Make/O/N=0 freqWave
	
	String pathname = StrVarOrDefault(":gPathName","C:Users:somnath2:Desktop:");
	String/G gPathName = pathname
	
	String basename = StrVarOrDefault(":gBaseName","Sample");
	String/G gBaseName = basename
		
	// Create the control panel.
	Execute "CRSweepPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End


Window CRSweepPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 820,460) as "Contact Resonance Sweeps"
	SetDrawLayer UserBack
		
	
	SetVariable sv_StartV,pos={16,16},size={112,18},title="DC initial (V)", limits={0,10,1}
	SetVariable sv_StartV,value= root:packages:CRSweep:gVstart,live= 1
	
	SetVariable sv_EndV,pos={205,16},size={112,20},title="DC Final (V)", limits={0.1,10,1}
	SetVariable sv_EndV, value=root:Packages:CRSweep:gVend
	
	SetVariable sv_VdcStep,pos={16,55},size={112,18},title="DC step (V)", limits={0.1,10,.01}
	SetVariable sv_VdcStep,value= root:packages:CRSweep:gVStep,live= 1
	
	ValDisplay sv_steps,pos={205,55},size={112,18},title="Num steps"
	ValDisplay sv_steps,value= root:packages:CRSweep:gNumVoltSteps,live= 1
	
	SetVariable sv_SweepWidth,pos={16,97},size={150,18},title="Sweep Width (kHz)", limits={1,inf,1}
	SetVariable sv_SweepWidth,value= root:packages:CRSweep:gSweepWidth,live= 1
	
	SetVariable sv_delay,pos={196,97},size={120,18},title="Time (sec)", limits={0,inf,1}
	SetVariable sv_delay, value=root:Packages:CRSweep:gTuneDuration
	
	SetVariable sv_PathName,pos={16,133},size={300,25},title="File Path"
	SetVariable sv_PathName, value=root:Packages:CRSweep:gPathName	
	
	SetVariable sv_ImageBaseName,pos={16,168},size={300,25},title="Base Name"
	SetVariable sv_ImageBaseName, value=root:Packages:CRSweep:gBaseName	
	
	ValDisplay vd_Progress,pos={16,203},size={300,20},title="Progress", mode=0, live=1
	ValDisplay vd_Progress,limits={0,100,0},barmisc={0,40},highColor= (0,43520,65280)
	ValDisplay vd_Progress, value=root:Packages:CRSweep:GProgress
	
	Button but_StartRamp,pos={37,236},size={114,25},title="Start", proc=startTunes	
	
	Button but_stop,pos={187,236},size={114,25},title="Stop", proc=StopSweeps
			
	//Checkbox chk_ShowData, pos = {708, 51}, size={10,10}, title="Show Data", proc=ShowDataChkFun2
	//Checkbox chk_ShowData, live=1, value=root:Packages:CRSweep:gshowTable
		
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 143,295, "\Z13Suhas Somnath, UIUC 2014"
End	

Function StopSweeps(ctrlname) : ButtonControl
	String ctrlname
	
	String dfSave = GetDataFolder(1)
		
	SetDataFolder root:Packages:CRSweep
	NVAR gAbortTunes
	
	// stop background function here.
	gAbortTunes = 1

	ModifyControl but_StartRamp, disable=0, title="Start"
	
	SetDataFolder dfSave
	
End

function startTunes(ctrlname) : ButtonControl
	String ctrlName;

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gTuneDuration, gSweepWidth, gProgress
	
	Make/O/N=3 freqWave;
	freqWave[0] = 100.1;
	freqWave[1] = 107;
	freqWave[2] = 213;
	//freqWave[3] = 490;
	//freqWave[4] = 509.65;
	//freqWave[5] = 603.5;
	//freqWave[6] = 679.5;
	//freqWave[7] = 988;
	//Wave freqWave
	
	Variable/G gIterStartTick= 0
	Variable/G gIteration = 0
	gProgress= 0
	Variable/G gNumTunes = DimSize(freqWave,0);
	
	Variable/G gVoltIteration = 0;
	NVAR gVend, gVstart, gVstep, gNumVoltSteps;
	gNumVoltSteps =  1 + floor(((gVend - gVstart)/gVstep));
	
	
	Variable numPts
	if(gTuneDuration == 1)
		gTuneDuration = 0.96
		numPts = 480;
	elseif(gTuneDuration == 2)
		gTuneDuration = 1.984
		numPts = 992;
	elseif(gTuneDuration == 3)
		gTuneDuration = 2.944
		numPts = 1472;
	elseif(gTuneDuration == 4)
		gTuneDuration = 3.968
		numPts = 1984;
	elseif(gTuneDuration == 20)
		gTuneDuration = 19.968
		numPts = 9984;
	else
		gTuneDuration = 2.944
		numPts = 992;
	endif
		
	Make/O/N=0 TuneWave
	//Redimension/N=(numPts,gNumTunes*2) TuneWave
	
	SetDataFolder dfSave
	
	// set window size, etc here:
	Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	Wave thermalwave = root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	
	mastervariables[18][0] = gSweepWidth*1000; // sweep width (Hz)
	thermalwave[43][0] = gTuneDuration; // Tune time (sec)

	ModifyControl but_startRamp, disable=2, title="Running.."

	// Starting background process here:
	ARBackground("bgTuneIterations",100,"")
end



Function bgTuneIterations()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gAbortTunes, gIterStartTick, gIteration, gTuneDuration
	NVAR gVstart, gVstep, gVoltIteration, gNumVoltSteps;
	
	Wave freqWave
		
	if(gAbortTunes)
		// safety precautions before exit
		td_wv("lockin.DCOffset",0);
		ModifyControl but_startRamp, disable=0, title="Start"
		SetDataFolder dfSave
		return 1;
	endif
	
	// Case 1: Begining of iteration - Must begin tune
	if(gIterStartTick == 0)
				
		// set freq:
		Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
		mastervariables[17][0] = freqWave[gIteration] * 1000; // freq (Hz)
		
		// set voltage next AGAIN because it always gets reset by above commands
		td_wv("lockin.DCOffset",gVstart + gVoltIteration*gVStep);
					
		CantTuneFunc("DoTuneOnce_3")
		
		gIterStartTick = ticks
		SetDataFolder dfSave
		//print("very first")
		return 0;
	endif
	
	// Tune is running / has run at this stage
	
	NVAR gNumTunes, gProgress, gShowTable
	Wave TuneWave;
	
	if(ticks >= (gIterStartTick+(round(gTuneDuration+0.5)* 60)))
		
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
		
		Variable tmep = (gIteration + gVoltIteration*gNumTunes)/(gNumTunes*gNumVoltSteps);
		gProgress = min(100,floor(tmep*100));
		
		// reset timer
		gIterStartTick = 0;
		
		SetDataFolder root:packages:CRSweep
		
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
				
				ModifyControl but_startRamp, disable=0, title="Start"
				td_wv("lockin.DCOffset",0);
				SetDataFolder dfSave
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
		
	Wave TuneWave
	
	//1. Get the correct path and file name of the file
	
			//Flags:
		// /C:	The folder specified by "path" is created if it does not already exist.
		// /O	Overwrites the symbolic path if it exists.
		// /Q	Suppresses printing path information in the history
		// /Z	Doesn't generate an error if the folder does not exist.
	NewPath/O/Q/C Path1, gPathName+ gBaseName + ":"

	String basefilename = gBaseName + "_V_" + num2str(Vtot) + ".txt";
	
	//2. write to file
		// O - overwrite ok, J - tab limted
	Save /O/J/P=Path1 TuneWave as (basefilename)

	Redimension /N=(0) TuneWave
	
	SetDataFolder dfSave
	
end
