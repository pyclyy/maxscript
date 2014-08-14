-- variables
	global NewRCmenu=""
	global sep=0
	global menuStr = "\n " as stringstream
	global handlerStr = "\n " as stringstream
	global srcObj, trgObj
	global srcArr=#()
	global trgArr=#()
	global arr=srcArr
	global cpCopyMode=2
	global cpMode=""

 	struct cpData (obj,mLevel,mProp,saProp)
	global cpSrcProps = cpData	\
		obj:undefined	\
		mLevel:undefined	\
		mProp:undefined	\
		saProp:undefined
	global cpTrgProps =	cpData	\
		obj:undefined	\
		mLevel:undefined	\
		mProp:undefined	\
		saProp:undefined

/*

-- set up structures to hold data
*/

	
--=====================================================================================
-- Utility funstions
--=====================================================================================

fn fileToString file=
	(
	str=stringstream ""
	strFile = openFile file
	while not eof strFile do
		(
		format "%\n" (readline strFile) to:str
		)
	return str as string
	)

fn flt_objects obj = (obj != undefined) -- objects filter 

fn flt_isNotMultiMat obj =
	(
	if obj.material != undefined then
		obj.material != Multimaterial
	else false
	)

fn flt_isNotSameObj obj = obj!=SrcObj


--=====================================================================================
-- Help/Options stuff functions
--=====================================================================================


fn helpBox =
	(
	rollout roHelp "Help" width:312 height:312
		(
		groupBox grp1 "Overview" pos:[8,8] width:296 height:136
		label lbl1 "This script is designed to quickly and easily copy properties from one object to another using the familiar right-click menu tree structure.
You can copy any property to any other property as just the value, a copy of the controller, or an instance of controller.
If the values are incompatible, nothing will happen.
" pos:[16,24] width:280 height:112

		groupBox grp2 "Usage" pos:[8,148] width:296 height:136
		label lbl2 " - Quickly match disparate properties such as UVW width and Plane width
Copy common properties accross different objects, such as SuperSpary/PCloud or Cylinder/Cones
Create a 'soft instance' by copying all properties from one object to another, except the ones you want to be different
Easily instance rotation paramaters from a transform to a Gizmo's Transform
" pos:[16,164] width:280 height:112

		-- declarations

		-- Interface
	
		-- Functions

		-- Handlers
	
	
		)	
	if pmHelpFloater != undefined then closerolloutfloater pmHelpFloater
		pmHelpFloater = newRolloutFloater "Property Matcher Help" 325 500
	addRollout roHelp pmHelpFloater
	)

fn optionsBox =
	(
	rollout roOpts "Options" width:168 height:312
		(
		radiobuttons rdo1 "Copy property..." pos:[8,8] width:110 height:62 labels:#("Copy value only", "Copy controller", "Instance controller")
		radiobuttons rdo2 "Copy method..." pos:[8,80] width:57 height:46 labels:#("By modifier index","By modifier name") columns:1
--		checkbox chk1 "Auto-assign controllers" pos:[16,80] width:136 height:16

		-- declarations

		-- Interface
	
		-- Functions

		-- Handlers
	
	
		)
	if pmOptFloater != undefined then closerolloutfloater pmOptFloater
		pmOptFloater = newRolloutFloater "Property Matcher Options" 188 200 
	addRollout roOpts pmOptFloater
	)



--=====================================================================================
-- Sub Menu handler code
--=====================================================================================



fn doStack level mProp saProp=
	(
	--messageBox (obj as string +" | "+ prop1 as string +" | "+ prop2 as string)

	-- work out the node from the data...
		format "level: %\n" level
		format "mProp: %\n" mProp
		format "saProp: %\n" saProp
/*
		local srcNode
		local srcNodePropValue
		local srcNodePropController





		if level>0 then
			(
			srcNode=				srcObj.modifiers[level]
			srcNodePropValue=		execute("$"+srcObj.name+".modifiers["+level as string+"]."+mProp as string)
			srcNodePropController=	execute("$"+srcObj.name+".modifiers["+level as string+"]."+mProp as string+".controller")

			--srcProp=srcNode[mProp]
			)
		else
			srcNode=srcObj.baseObject[mProp as name]

		format ">% % %\n" srcNode srcNodePropValue srcNodePropValue.controller --srcNodePropController
*/

	if cpMode=="src" then
		(
		cpSrcProps.mLevel=level
		cpSrcProps.mProp=mProp
		cpSrcProps.saProp=saProp
		)
	else if cpMode=="trg" then
		(
		cpTrgProps.mLevel=level
		cpTrgProps.mProp=mProp
		cpTrgProps.saProp=saProp
		)
	)


fn doTrans p r s par=
	(
	trgObj = pickObject filter:flt_isNotSameObj rubberBand:srcObj.pos

	-- position
		if p==1 then srcObj.pos=trgObj.pos

	-- rotation
		if r==1 then
			(
			-- rotate without messing with position
			in coordsys (transmatrix srcObj.transform.pos) 
		    srcObj.rotation = trgObj.rotation as EulerAngles
			)
	-- scale
		if s==1 then srcObj.scale=trgObj.scale

	-- parent
		if par==1 then srcObj.parent=trgObj

	)


fn doMat obj prop =
	(
	)

--=====================================================================================
-- Sub Menu functions
--=====================================================================================


fn buildStackLevelMenu obj level=
	(
	local mStr=""
	if superclassof obj == modifier then mStr= obj.name as string
	else mStr = obj as string
	
	format "	subMenu \"%\"\n		(\n" mStr to:menuStr
	-- All
		local mEnable= (getPropNames obj).count>0
		-- menu items
			format "		menuItem mi_Stack%_All \"All\" enabled:% \n" level mEnable to:menuStr
			format "		menuItem mi_Stack%_AllExcept \"All Except...\" enabled:% \n" level mEnable to:menuStr
			format "		separator sep%\n" (sep+=1) to:menuStr
			
		-- handlers
			format "	on mi_Stack%_ALL picked do doStack % #all #null\n" level level to:handlerStr
			format "	on mi_Stack%_ALLExcept picked do doStack % #allExcept #null\n" level level to:handlerStr


	-- Individual properties of modifier/baseObject
		local propArr=getPropNames obj
		for m = 1 to propArr.count do
			(
		-- straight properties
			if classof (getProperty obj propArr[m]) != SubAnim then
				(
			-- menu items
				format "		menuItem mi_Stack%_% \"%\"\n" level m (propArr[m] as string) to:menuStr
			-- handlers
				format "	on mi_Stack%_% picked do doStack % % #null\n" level m level propArr[m] to:handlerStr
				)
		-- subanims
			else
				(
				format "		subMenu \"%...\"\n			(\n" (propArr[m] as string) to:menuStr
				-- All

					-- menu items
						format "		menuItem mi_Stack%_%_%_All \"All\"\n" level m (p as string) to:menuStr
						format "		separator sep%\n" (sep+=1) to:menuStr
						
					-- handlers
						format "	on mi_Stack%_%_%_ALL picked do doStack % % #all\n" level m (p as string) level propArr[m] to:handlerStr
			
				
				-- individual properties
					for p in (getSubAnimNames obj[propArr[m]]) do
						(
					-- menu items
						format "			menuItem mi_Stack%_%_% \"%\"\n" level m (p as string) (p as string) to:menuStr
						--format "menuItem cunt \"cunt\"\n" to:menuStr
					-- handlers
						format "		on mi_Stack%_%_% picked do doStack % % %\n" level m (p as string) level propArr[m] p to:handlerStr
/*
*/
						)
					format "\n			)\n" to:menuStr
				)
			
			)

	format "\n		)\n" to:menuStr
	)




fn buildTransMenu obj =
	(
	------------------------------------------------------------
	-- Transforms
	------------------------------------------------------------
		-- menu
			format "subMenu \"Transform...\"\n	(\n" to:menuStr
			-- ...and Parent
				format "subMenu \"...and Parent...\"\n	(\n" to:menuStr
					format "	menuItem mi_TransParPRS \"All\"\n" mStr to:menuStr
					format "	separator sep%\n" (sep+=1) to:menuStr
					format "	menuItem mi_TransParPR \"Pos, Rot\"\n" mStr to:menuStr
					format "	separator sep%\n" (sep+=1) to:menuStr
					format "	menuItem mi_TransParP \"Position\"\n" mStr to:menuStr
					format "	menuItem mi_TransParR \"Rotation\"\n" mStr to:menuStr
					format "	menuItem mi_TransParS \"Scale\"\n" mStr to:menuStr
	
				format "\n	)\n" to:menuStr
	
			-- Transforms
				format "	separator sep%\n" (sep+=1) to:menuStr
	
				format "	menuItem mi_TransPRS \"All\"\n" mStr to:menuStr
				format "	separator sep%\n" (sep+=1) to:menuStr
				format "	menuItem mi_TransPR \"Pos, Rot\"\n" mStr to:menuStr
				format "	separator sep%\n" (sep+=1) to:menuStr
				format "	menuItem mi_TransP \"Position\"\n" mStr to:menuStr
				format "	menuItem mi_TransR \"Rotation\"\n" mStr to:menuStr
				format "	menuItem mi_TransS \"Scale\"\n" mStr to:menuStr
			format "\n	)\n" to:menuStr
	

		-- handlers
			local transHandlers = fileToString "transHandlers.ms"
			format "%\n" transHandlers to:menuStr
/*
*/
	)


fn buildMatMenu obj =
	(
	------------------------------------------------------------
	-- Material
	------------------------------------------------------------

	if obj.material!=undefined then
		(
		format "subMenu \"Groups...\"\n	(\n" to:menuStr
	
			format "	menuItem mi_MatGroupAll \"All\"" to:menuStr
			format "	menuItem mi_MatGroupAllExcept \"All Except...\"" to:menuStr
			format "	separator sep%\n" (sep+=1) to:menuStr
			local matArr =#("Ambient","Diffuse","Specular / Glossiness","Shader","Opacity","Bump","Self Illumination","Reflection")
			for n = 1 to matArr.count do
				(
				format "	menuItem mi_Mat% \"%\"\n" n matArr[n] to:menuStr
				)
		format "\n	)\n" to:menuStr

		format "subMenu \"Individual...\"\n	(\n" to:menuStr
	
		-- Individual properties
			local propArr=sort(getPropNames obj.material)
			format "	menuItem mi_MatIndAll \"All\"" to:menuStr
			format "	menuItem mi_MatIndAllExcept \"All Except...\"" to:menuStr
			format "	separator sep%\n" (sep+=1) to:menuStr
			for m = 1 to propArr.count do
				(
				-- menu items
					format "		menuItem mi_MatInd% \"%\"\n" m (propArr[m] as string) to:menuStr
	
				-- handlers
					--format "	on mi_mi_MatInd% picked do doMat % %\n" m level propArr[m] to:handlerStr
				)

		format "\n	)\n" to:menuStr
		)
	)


--=====================================================================================
-- Main Menu
--=====================================================================================
fn buildMainMenu obj =
	(
	-- reset all vars
		sep=0
		menuStr= "" as stringstream
	
	-- set up title
		local titleStr
		local cpCopyModeStr

		if cpCopyMode==0 then cpCopyModeStr="value only"
		else if cpCopyMode==1 then cpCopyModeStr="copy controller"
		else if cpCopyMode==2 then cpCopyModeStr="instance instroller"
		
		if cpMode=="src" then titleStr="REPLACE ("+cpCopyModeStr+") ..."
		else titleStr="WITH ("+cpCopyModeStr+") ..."


	-- start menu strucure

	format "rcmenu cpRCMenu (\n" to:menuStr
		(
			format "menuItem mi_Title \"%\" enabled:false\n" titleStr to:menuStr
			format "separator sep%\n" (sep+=1) to:menuStr
	
	
		------------------------------------------------------------
		-- Build Menus
		------------------------------------------------------------
		-- stack
			-- reset handlerStr
				handlerStr = stringstream ""
			-- menus
				format "subMenu \"Stack values...\"\n	(\n" to:menuStr
					-- mods
						for n = 1 to obj.modifiers.count do
							(
							buildStackLevelMenu obj.modifiers[n] n
							)
						format "	separator sep%\n" (sep+=1) to:menuStr
					-- base object
						buildStackLevelMenu obj.baseObject 0
				format "\n	)\n" to:menuStr
				
			-- insert handler menu string
				format "%\n" (handlerStr as string) to:menuStr

		-- transform

			buildTransMenu obj

			
			
		-- material
		/*
			if NOT flt_isNotMultiMat obj then
				(
			
				format "	menuItem mi_Mat \"Material...\" enabled:false\n" to:menuStr
		
				format "subMenu \"Material...\" filter:flt_isNotMultiMat %\n	(\n" obj to:menuStr
					buildMatMenu obj
				format "\n	)\n" to:menuStr
				)
		*/

		------------------------------------------------------------
		-- Help and options
		------------------------------------------------------------
	
		-- menu
			format "separator sep%\n" (sep+=1) to:menuStr
			format "menuItem mi_options \"Options...\"\n" to:menuStr
	
		-- Handlers
			format "on mi_Options picked do optionsBox()\n" to:menuStr


		-- menu
			format "separator sep%\n" (sep+=1) to:menuStr
			format "menuItem mi_Help \"Help...\"\n" to:menuStr
	
		-- Handlers
			format "on mi_Help picked do helpBox()\n" to:menuStr


	
		)
	format "\n)" to:menuStr


	close menuStr
	execute(menuStr as string)
	)


--=====================================================================================
-- Main function
--=====================================================================================

fn copyProps =
	(
	disableSceneRedraw() 

	/*
	cpSrcProps
		cpData
			Obj:$PolyMesh:Teapot01 @ [5.859783,-10.845510,0.000000]
			mLevel:1
			mProp:#all
			saProp:#Null

	cpTrgProps
		cpData
			Obj:$Editable_Mesh:Torus01 @ [48.056408,-15.089800,0.000000]
			mLevel:2
			mProp:#all
			saProp:#Null

	*/


/*
getPropertyController <value> <string_or_name> 
setPropertyController 

getProperty <obj> <property_name> 
setProperty <obj> <property_name> <value> 

*/

-- get stack level
	local srcProp
	case of 
		( 
		(cpSrcProps.mLevel == 0):	srcProp = cpSrcProps.obj.baseObject
		(cpSrcProps.mLevel > 0):	srcProp = cpSrcProps.obj.modifiers[cpSrcProps.mLevel]
		default: messageBox "Couldn't get stack level"
		) 

	local trgProp
	case of 
		( 
		(cpTrgProps.mLevel == 0):	trgProp = cpTrgProps.obj.baseObject
		(cpTrgProps.mLevel > 0):	trgProp = cpTrgProps.obj.modifiers[cpTrgProps.mLevel]
		default: messageBox "Couldn't get stack level"
		) 

	--messagebox (exprformaxobject srcProp as string+"\n"+exprformaxobject trgProp as string)
	--messagebox (srcProp as string+"\n"+trgProp as string)

/*
	local srcNodePropValue=		execute("$"+srcObj.name+".modifiers["+level as string+"]."+mProp as string)
	local srcNodePropController=	execute("$"+srcObj.name+".modifiers["+level as string+"]."+mProp as string+".controller")
*/
	
-- if mProp is set to #all
	-- get the list of properties to iterate through...
		local propArr = getPropNames srcProp

	-- start iterating and matching
		for prop in propArr do
			(
			if (classof (getProperty srcProp prop)!=subAnim) then
				(
				local saInfo = getNumSubs
				try (
					local propVal = getProperty trgProp prop
					setProperty srcProp prop propVal
					format "mProp SUCCESS:  % >>> % >>> % >>> %\n" srcProp prop propVal saInfo
					)
				catch(
					format "mProp FAIL:     % >>> % >>> % >>> %\n" srcProp prop propVal saInfo
					)
				)
			else
				(
				try (
					local propCtrl = getPropertyController trgProp prop
					setPropertyController srcProp prop (copy propCtrl)
					format "saProp SUCCESS: % >>> % >>> %\n" trgProp prop propCtrl
					)
				catch(
					format "saProp FAIL:    % >>> % >>> %\n" trgProp prop propCtrl
					)
				)

		)
	enableSceneRedraw()
	redrawViews()
	forceCompleteRedraw()
	)

--=====================================================================================
-- Go!
--=====================================================================================


-- source mode
	-- pick source object
		cpMode="src"

		srcObj=$
		if srcObj == undefined then srcObj=pickObject()

		cpSrcProps.obj=srcObj
		
	-- build menu
		buildMainMenu srcObj
		registerRightClickMenu cpRCMenu
		popUpMenu cpRCMenu --pos:[0,0]

--		format "FINISHED\n"

-- target mode
	-- pick target object
		cpMode="trg"
		trgObj=pickObject rubberband:srcObj.pos
		cpTrgProps.obj=trgObj
		buildMainMenu trgObj
		registerRightClickMenu cpRCMenu

	-- build menu
		popUpMenu cpRCMenu

format "%\n" cpSrcProps
format "%\n" cpTrgProps

-- do it
	copyProps()


/*
show cpSrcProps.obj.modifiers[cpSrcProps.mLevel]
  .axis : integer
  .flip : boolean
  .slice : integer
  .weld (Weld_Seam) : integer
  .threshold : float
  .mirror : transform
false
cpSrcProps.obj.modifiers[cpSrcProps.mLevel].threshold.controller=boolean_float()
Controller:Boolean_Controller
Controller:Bezier_Float
for p in cpSrcProps.obj.modifiers[cpSrcProps.mLevel] do format "%\n" p
pArr = getPropNames cpSrcProps.obj.modifiers[cpSrcProps.mLevel]
#(#axis, #flip, #slice, #weld, #threshold, #MIrror)
#(#axis, #flip, #slice, #weld, #threshold, #MIrror)
for p in pArr do format "%\n" cpSrcProps.obj.modifiers[cpSrcProps.mLevel][p]

for p = 1 to pArr.count do
	(
	format "%\n" cpSrcProps.obj.modifiers[cpSrcProps.mLevel][pArr[p]]
	)

classof cpSrcProps.obj.modifiers[cpSrcProps.mLevel].gizmo

getProperty cpSrcProps.obj.modifiers[cpSrcProps.mLevel] cpSrcProps.mProp
1.0

cpSrcProps.mProp= #threshold
#threshold
#flip
*/