#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "UIUC"
	Submenu "Lorentz"
		"Contact Resonance Sweep", CRSweepDriver()
	End
End

Function CRSweepDriver()
	
	// If the panel is already created, just bring it to the front.
	//DoWindow/F CRSweepPanel
	//if (V_Flag != 0)
	//	return 0
	//endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:CRSweep
		
	Variable sweepWidth = NumVarOrDefault(":gSweepWidth",10)
	Variable/G gSweepWidth= sweepWidth; // kHz
	
	Variable tuneDuration = NumVarOrDefault(":gTuneDuration",3)
	Variable/G gTuneDuration= tuneDuration
	
	Variable showTable = NumVarOrDefault(":gshowTable",1)
	Variable/G gshowTable= showTable
	
	Variable/G gAbortTunes = 0
	
	Make/O/N=0 freqWave
		
	// Create the control panel.
	//Execute "LorentzRampPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End

function myTest()

	Make/O/N=8 freqWave;
	freqWave[0] = 100.1;
	freqWave[1] = 107;
	freqWave[2] = 213;
	freqWave[3] = 490;
	freqWave[4] = 509.65;
	freqWave[5] = 603.5;
	freqWave[6] = 679.5;
	freqWave[7] = 988;
	
	Make/O/N=8 ampWave;
	ampWave[0] = 1.1;
	ampWave[1] = 1;
	ampWave[2] = 23;
	ampWave[3] = 40;
	ampWave[4] = 59.65;
	ampWave[5] = 6.5;
	ampWave[6] = 69.5;
	ampWave[7] = 9;
	
	Make/O/N=8 dumber;
	dumber[0] = 1.1;
	dumber[1] = 1;
	dumber[2] = 23;
	dumber[3] = 40;
	dumber[4] = 509.65;
	dumber[5] = 603.5;
	dumber[6] = 679.5;
	dumber[7] = 988;
	
	//Concatenate/O {freqWave,ampWave},root:packages:myWave;
	Concatenate/O {root:packages:myWave,dumber},root:packages:myWave;
end

function startMyTunes()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gTuneDuration, gSweepWidth
	
	Make/O/N=8 freqWave;
	freqWave[0] = 100.1;
	freqWave[1] = 107;
	freqWave[2] = 213;
	freqWave[3] = 490;
	freqWave[4] = 509.65;
	freqWave[5] = 603.5;
	freqWave[6] = 679.5;
	freqWave[7] = 988;
	//Wave freqWave
	
	Variable/G gIterStartTick= 0
	Variable/G gIteration = 0
	Variable/G gProgress= 0
	Variable/G gNumTunes = DimSize(freqWave,0);
	
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
	Redimension/N=(numPts,gNumTunes*2) TuneWave
	
	SetDataFolder dfSave
	
	// set window size, etc here:
	Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	Wave thermalwave = root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	
	mastervariables[18][0] = gSweepWidth*1000; // sweep width (Hz)
	thermalwave[43][0] = gTuneDuration; // Tune time (sec)

	// Starting background process here:
	ARBackground("bgTuneIterations",100,"")
end



Function bgTuneIterations()

	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:CRSweep
	NVAR gAbortTunes, gIterStartTick, gIteration, gTuneDuration
	Wave freqWave
		
	if(gAbortTunes)
		// safety precautions before exit
		SetDataFolder dfSave
		return 1;
	endif
	
	// Case 1: Begining of iteration - Must begin tune
	if(gIterStartTick == 0)
			
		// set freq here:
		Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
		mastervariables[17][0] = freqWave[gIteration] * 1000; // freq (Hz)
			
		CantTuneFunc("DoTuneOnce_3")
		
		gIterStartTick = ticks
		SetDataFolder dfSave
		//print("very first")
		return 0;
	endif
	
	// Tune is running / has run at this stage
	
	NVAR gNumTunes, gProgress, gShowTable
	Wave TuneWave;
	
	if(ticks >= (gIterStartTick+(round(gTuneDuration)* 60)))
		
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
		gProgress = min(100,floor((gIteration/gNumTunes)*100))
		// reset timer
		gIterStartTick = 0;
		
		// stop BG if all tunes are complete
		if(gIteration == gNumTunes)
			// clean up here and exit BG
			if(gShowTable)
				Edit/K=1 TuneWave
			endif
			SetDataFolder dfSave
			return 1;
		endif

	endif
	
	// Case 3: Tune is still running OR new tune will start
	SetDataFolder dfSave
	return 0;

End

