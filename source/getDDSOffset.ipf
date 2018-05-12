Function GetDDSOffset()
	//used to return what our offset should be depending on mode 
	
	Variable offsetVal = 0
	if (GV("hasblueDrive") && GV("blueDriveOn"))
		offsetVal = GV("blueDriveOffset")
	elseif (GV("ImagingMode") == cPFMMode)
		OffsetVal = Nan	//we don't set it, we let someone else set it.
		
		
		// Start modification by Suhas //
		String dfSave = GetDataFolder(1)
		if(Datafolderexists("root:packages:CRSweep")==0)
			NewDataFolder/O/S root:packages:CRSweep
		endif
		SetDataFolder root:Packages:CRSweep
		OffsetVal = NumVarOrDefault(":gDCOffset",0)
		
		// Error check to make sure that DCoffset + amp < 10
		Wave mastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
		OffsetVal = min(10-mastervariables[16][0],OffsetVal);
		//ffsetVal = min(max allowable DC offset, currently desired offset)
		
		Variable/G gDCOffset= OffsetVal; // kHz
		SetDataFolder dfSave
		// end of modification by Suhas
		
	Endif
	
	return(OffsetVal)
End //GetDDSOffset