---------------------------------------------------------------------------------------------------
-- global declarations
---------------------------------------------------------------------------------------------------

rollout ro1 "Options" width:232 height:336
(
	---------------------------------------------------------------------------------------------------
	-- declarations
	---------------------------------------------------------------------------------------------------

	local obj, objClass
	local compHeight, compWidth
	local data


	---------------------------------------------------------------------------------------------------
	-- Interface
	---------------------------------------------------------------------------------------------------

	GroupBox grp3ds "3dsmax" pos:[8,8] width:216 height:40
	button btnObj "Pick Object..." pos:[16,24] width:200 height:16

	GroupBox grpAE "After Effects" pos:[8,56] width:216 height:80
	dropdownList ddCompPreset "" pos:[16,80] width:140 height:21 items:#("Custom Output Size...", "Current Settings...", "PAL (720 x 576)", "PAL (1024 x 756)")
	dropdownList ddAEVersion "" pos:[156,80] width:60 height:21 items:#("Version", "6.5", "6.0", "5.5", "5.0")
	spinner spnCompWidth "Width: " pos:[32,108] width:80 height:16 range:[0,9999,720] type:#integer scale:1
	spinner spnCompHeight "Height: " pos:[136,108] width:80 height:16 range:[0,9999,576] type:#integer scale:1

	GroupBox grpExport "Properties" pos:[8,144] width:216 height:72
	checkbox chkPos "Position" pos:[16,160] width:96 height:16 checked:true
	checkbox chkRot "Rotation" pos:[16,176] width:96 height:16 checked:true
	checkbox chkScale "Scale" pos:[16,192] width:96 height:16
	checkbox chkCam "Camera properties" pos:[112,160] width:104 height:16 checked:true enabled:false
	checkbox chkLight "Light properties" pos:[112,176] width:104 height:16 checked:true enabled:false

	GroupBox grpAnimRange "Animation Range" pos:[8,224] width:216 height:72
	dropdownList ddAnimRange "" pos:[16,240] width:200 height:21 items:#("Custom...", "Current...", "Single frame...")
	spinner spnAnimFrom "From: " pos:[32,268] width:80 height:16 range:[0,9999,0] type:#integer scale:1
	spinner spnAnimTo "To: " pos:[144,268] width:70 height:16 range:[0,9999,100] type:#integer scale:1

	button btnExport "Export..." pos:[8,304] width:216 height:24

	---------------------------------------------------------------------------------------------------
	-- Functions
	---------------------------------------------------------------------------------------------------


	---------------------------------------------------------------------------------------------------
	-- Handlers
	---------------------------------------------------------------------------------------------------

-- 3dsmax

	on btnObj pressed do
	(
		obj=pickObject message:"Pick an object, light or camera..."
		btnObj.text=obj.name
		objClass=superclassof obj

		chkLight.enabled= 	objClass==light
		chkCam.enabled=	objClass==camera
	)


-- After Effects

	on ddCompPreset selected item do
	(
		local xy=#()
		xy=case ddCompPreset.selection of
		(
			1:	#(spnCompWidth.value,spnCompHeight.value)
			2:	#(renderwidth,renderheight)
			3:	#(720,576)
			4:	#(1024,576)
		)
		spnCompWidth.value=xy[1]
		spnCompHeight.value=xy[2]
	)

	on spnCompWidth changed val do ddCompPreset.selection=1
	on spnCompHeight changed val do ddCompPreset.selection=1


-- Animation range

	on ddAnimRange selected sel do
	(
		local animRange=#()
		animRange=case ddAnimRange.selection of
		(
			1:	#(spnAnimFrom.value,spnAnimTo.value)
			2:	#(animationrange.start,animationrange.end)
			3:	#(sliderTime,sliderTime)
		)
		spnAnimFrom.value=animRange[1]
		spnAnimTo.value=animRange[2]
	)

	on spnAnimFrom changed val do
	(
		ddAnimRange.selection=1
		if spnAnimFrom.value >= spnAnimTo.value then spnAnimTo.value = spnAnimFrom.value
	)

	on spnAnimTo changed val do
	(
		ddAnimRange.selection=1
		if spnAnimTo.value <= spnAnimFrom.value then spnAnimFrom.value = spnAnimTo.value
	)

-- Export

	on btnExport pressed do
	(
		local posData, rotXData, rotYData, rotZData, scaleData, camData, lightData, data=""
-- data		

		posData="\nPosition\n	Frame	X pixels	Y pixels	Z pixels\n"
		rotXData="\nRotation\n	Frame	degrees\n"
		rotYData="\nX Rotation\n	Frame	degrees\n"
		rotZData="\nY Rotation\n	Frame	degrees\n"
		scaleData="\nScale\n	Frame	X percent	Y percent	Z percent\n"
		camData="\nPoint of Interest\n	Frame	X pixels	Y pixels	Z pixels\n"
		lightData=""

		if isvalidnode obj then
		(
			for t = spnAnimFrom.value to spnAnimTo.value do
			(
				at time t
				(
					in coordsys #world
					(
					-- position
						if chkPos.checked then
						(
							px=obj.pos.x
							py=obj.pos.y
							pz=obj.pos.z
							posData+="	"+t as string+"	"+(px+(spnCompWidth.value/2)) as string+"	"+(-pz) as string+"	"+(py+(spnCompHeight.value/2)) as string+"\n"
						)

					-- rotation
						if chkRot.checked AND (classof obj)!=Targetcamera then
						(
							rot=obj.rotation as eulerangles
							rx=rot.x
							ry=rot.y
							rz=rot.z
							rotXData+="	"+t as string+"	"+(rx+90) as string+"\n"
							rotYData+="	"+t as string+"	"+(-rz) as string+"\n"
							rotZData+="	"+t as string+"	"+(ry) as string+"\n"
						)

					-- scale
						if chkScale.checked then
						(
						)
		
					-- camera data
						if chkCam.checked AND (classof obj)==Targetcamera then
						(
							px=obj.target.pos.x
							py=obj.target.pos.y
							pz=obj.target.pos.z
							camData+="	"+t as string+"	"+(px) as string+"	"+(-pz) as string+"	"+(py) as string+"\n"
						)
		
					-- light data
				)
			)
		)


-- final data gathering
	data+=posData + rotXData + rotYData + rotZData + scaleData + camData + lightData


format "\n\n
Adobe After Effects 6.0 Keyframe Data				
				
	Units Per Second	%		
	Source Width	%		
	Source Height	%		
	Source Pixel Aspect Ratio	1		
	Comp Pixel Aspect Ratio	1		
				
%
End of Keyframe Data\n\n" framerate spnCompWidth.value spnCompHeight.value data
		)
	)
)

if AEFloater != undefined then closerolloutfloater AEFloater
	AEFloater = newRolloutFloater "My Floater" 244 366 250 100
addRollout ro1 AEFloater

