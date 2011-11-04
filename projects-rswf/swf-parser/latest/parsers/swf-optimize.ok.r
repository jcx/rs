rebol [
	title: "SWF sprites and movie clip related parse functions"
	purpose: "Functions for parsing sprites and movie clip related tags in SWF files"
]

;tagId: none
set 'swf-tag-optimize func[tagId tagData /local err action st st2][
	;tagId: tag
	reduce either none? action: select parseActions tagId [
		;tagData
		;print ["importing tag:"  tagId]
		form-tag tagId tagData
	][
		setStreamBuffer tagData
		clearOutBuffer
		;print ["IMP>" index? inBuffer length? inBuffer]
		if error? set/any 'err try [
			set/any 'result do bind/copy action 'self
			;probe bind?
		][
			print ajoin ["!!! ERROR while optimizing tag:" select swfTagNames tagId "(" tagId ")"]
			throw err
		]
		result
		;head inBuffer
		;print ["IMP<" index? inBuffer length? head inBuffer]
		;form-tag tagId head inBuffer
	]

]



optimize-detectBmpFillBounds: has[
	shape result fillStyles lineStyles pos st dx dy tmp lineStyle fillStyle0 fillStyle1 hasBitmapFills? p fill
	posX posY t0x t0y s0x s0y r0x r0y t1x t1y s1x s1y r1x r1y bmpFills noCropBitmaps usedFills
] [
	print ["optimize-detectBmpFillBounds" tagId]
	bmpFills: copy []
	noCropBitmaps: copy []
	
	shape: parse-DefineShape
	;print length? shape
	;ask ""
	;print "-=-=-=-"
	fillStyles: shape/4/1
	foreach fill fillStyles [
		if find [64 65 66 67] fill/1 [
			hasBitmapFills?: true
			;append fill [1000000 1000000 -1000000 -1000000]
		]
	]
	;if none? hasBitmapFills? [return none]
	lineStyles: shape/4/2
	lineStyle: fillStyle0: fillStyle1: none
	pos: 0x0
	posX: posY: 0
	fill: fill0posX: fill1posX: fill0posY: fill1posY: none
	fill0minX: fill1minX:
	fill0minY: fill1minY:  100000000
	fill0maxX: fill1maxX:
	fill0maxY: fill1maxY: -100000000
	
	allUsedFills: copy []
	usedFills: copy []
	
	parse shape/4/3 [
		any [
			'style set st block! p: (
				;print ["style:" mold st]
				if all [st/2 st/2 > 0] [append usedFills st/2]
				if all [st/3 st/3 > 0] [append usedFills st/3]
				;ask ""
				if all [fill0posX fill0bmp find [64 65 66 67] fill0bmp/1 not none? st/2] [
					;print ["end fill0-" fill0posX fill0posY]
					repend bmpFills reduce [fill0bmp/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y]
					fill0bmp: none
				]
				if all [fill1posX fill1bmp find [64 65 66 67] fill1bmp/1 not none? st/3] [
					;print ["end fill1-" fill1posX fill1posY]
					repend bmpFills reduce [fill1bmp/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y]
					fill1bmp: none
				]
				;smazat?-> if fill1pos [fill1pos: fill1pos + as-pair dx dy]
				fill0bmp: either fill0: st/2 [fillStyles/(fill0)][none]
				fill1bmp: either fill1: st/3 [fillStyles/(fill1)][none]
				if st/1 [posX: st/1/1 posY: st/1/2]
				;print ["POS:" posX posY]
				either any [
					all [fill0bmp find [64 65 66 67] fill0bmp/1]
					all [fill1bmp find [64 65 66 67] fill1bmp/1]
				][
				;	print ["bmpfill" mold fill0bmp mold fill1bmp]
					;if fill0bmp [print ["????????????????????????" fill0bmp/2/1 fill0bmp/1]]
					;if fill1bmp [print ["????????????????????????" fill1bmp/2/1 fill1bmp/1]]
					either all [
						fill0bmp
						find [64 65 66 67] fill0bmp/1
					][
					;	probe fillStyles
						tmp: fill0bmp/2/2

						t0x: tmp/3/1
						t0y: tmp/3/2
						either tmp/2 [
							r0x: tmp/2/1
							r0y: tmp/2/2
						][
							r0x: r0y: 0	
						]
						either tmp/1 [
							s0x: tmp/1/1
							s0y: tmp/1/2
						][
							s0x: s0y: 0	
						]
						fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
						fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
						fill0minX: fill0minY:  100000000
						fill0maxX: fill0maxY: -100000000
					][
						t0x: t0y: r0x: r0y: s0x: s0y:
						fill0posX: fill0posY: none
					]
					either all [fill1bmp find [64 65 66 67] fill1bmp/1] [
						tmp: fill1bmp/2/2

						t1x: tmp/3/1
						t1y: tmp/3/2
						either tmp/2 [
							r1x: tmp/2/1
							r1y: tmp/2/2
						][
							r1x: r1y: 0	
						]
						either tmp/1 [
							s1x: tmp/1/1
							s1y: tmp/1/2
						][
							s1x: s1y: 1	
						]
						fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
						fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
						fill1minX: fill1minY:  100000000
						fill1maxX: fill1maxY: -100000000
					][
						t1x: t1y: r1x: r1y: s1x: s1y:
						fill1posX: fill1posY: none
					]

					;print ["FILL0:" fill0posX fill0posY t0x t0y s0x s0y r0x r0y]
					;print ["FILL1:" fill1posX fill1posY t1x t1y s1x s1y r1x r1y]
					
					if fill0posX [
						;print ["fill0pos" fill0posX fill0posY]
						fill0minX: min fill0minX fill0posX
						fill0maxX: max fill0maxX fill0posX
						fill0minY: min fill0minY fill0posY
						fill0maxY: max fill0maxY fill0posY
						print ["??" fill0minX fill0minY ]
					]
					if fill1posX [
						fill1minX: min fill1minX fill1posX
						fill1maxX: max fill1maxX fill1posX
						fill1minY: min fill1minY fill1posY
						fill1maxY: max fill1maxY fill1posY
					]
				][
					;print "nobmpfill"
					either tmp: find p 'style [p: tmp][p: tail p]
				]
				
				
				if st/5 [
					usedFills: unique usedFills
					forall usedFills [
					;	print ["aa" mold first usedFills]
						tmp: fillStyles/(first usedFills)
						either find [64 65 66 67] tmp/1 [
							change/only usedFills copy tmp
						][
							clear head usedFills
							break
						]
					]
					usedFills: head usedFills
					append allUsedFills copy/deep usedFills
					clear usedFills
					
					;print ["new fillStyles:" mold st/5/1]
					;ask ""
					;new-style
					fillStyles: st/5/1
					lineStyles: st/5/2
					lineStyle: fillStyle0: fillStyle1: none
					pos: 0x0
					posX: posY: 0
					fill: fill0posX: fill1posX: fill0posY: fill1posY: none
					fill0minX: fill1minX:
					fill0minY: fill1minY:  100000000
					fill0maxX: fill1maxX:
					fill0maxY: fill1maxY: -100000000
				]
			) :p
			| 'line some [
				set dx integer! set dy integer! (
					posX: posX + dx
					posY: posY + dy
					if fill0posX [
						fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
						fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
						;print ["FILL0 pos:" fill0posX fill0posY]
						fill0minX: min fill0minX fill0posX
						fill0maxX: max fill0maxX fill0posX
						fill0minY: min fill0minY fill0posY
						fill0maxY: max fill0maxY fill0posY
					]
					if fill1posX [
						fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
						fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
						fill1minX: min fill1minX fill1posX
						fill1maxX: max fill1maxX fill1posX
						fill1minY: min fill1minY fill1posY
						fill1maxY: max fill1maxY fill1posY
					]
				;	probe fill0bmp

				;	print ["pos:" pos]
					;append result ajoin [pos " "]
				)] ;(append result lf)
			|
			'curve some [
				;set cx integer! set cy integer!
				set dx integer! set dy integer! (
					posX: posX + dx
					posY: posY + dy
					if fill0posX [
						fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
						fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
						fill0minX: min fill0minX fill0posX
						fill0maxX: max fill0maxX fill0posX
						fill0minY: min fill0minY fill0posY
						fill0maxY: max fill0maxY fill0posY
					]
					if fill1posX [
						fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
						fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
						fill1minX: min fill1minX fill1posX
						fill1maxX: max fill1maxX fill1posX
						fill1minY: min fill1minY fill1posY
						fill1maxY: max fill1maxY fill1posY
					]
				)
			]
		]
	]
	if all [fill0posX fill0bmp] [
		;print ["end fill0" fill0posX fill0posY]
		repend bmpFills reduce [fill0bmp/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y]
		
	]
	if all [fill1posX fill1bmp] [
		;print ["end fill1" fill1posX fill1posY]
		repend bmpFills reduce [fill1bmp/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y]
		
	]


	;probe fill0bmp
print ["bmpFills" mold bmpFills]


;	bmpFills: copy []
;	foreach fill fillStyles [
;		if find [64 65 66 67] fill/1 [
;			repend bmpFills probe reduce [fill/2/1 fill/2/2/3  fill/3 fill/4 fill/5 fill/6]
;		]
;	]

	usedFills: unique usedFills
	forall usedFills [
		tmp: fillStyles/(first usedFills)
		either find [64 65 66 67] tmp/1 [
			change/only usedFills copy tmp
		][
			clear head usedFills
			break
		]
	]
	usedFills: head usedFills
	append allUsedFills copy/deep usedFills
	clear usedFills
					
	;print ["usedFills:" length? allUsedFills tab mold allUsedFills]
	;ask ""
	reduce [
		bmpFills
		allUsedFills
		shape/1
	]
]


optimize-updateShape: has [id][
	probe id: carryUI16 ;shapeID
	writeRect readRect ;shape bounds
	
	if tagId >= 67 [
		writeRect readRect ;edgeBounds
		carryBytes 1    ;flags: 6*reserved,usesNonScalingStrokes,usesScalingStrokes
	]
	alignBuffers
	loop carryCount [
		optimizeFILLSTYLE 
	]
	alignBuffers
	optimizeLINESTYLEARRAY
	alignBuffers
	
	optimize-shapeRecord id (alignBuffers carryUB 4) carryUB 4
	alignBuffers
	;insert tail outBuffer copy inBuffer
	head outBuffer
]

optimize-shapeRecord: func[id numFillBits numLineBits /local states nBits tmp][
		alignBuffers	
		comment {
		if tmp: select data/usedFills id [
			print "aaaaaaaa"
		]	
		probe data
		ask ""
		writeBit false
		writeUB 3 5
		writeSBPair [-1040 -1480] ;-1040 -1480 880 1400
		writeUB 1 numFillBits
		
		writeBit true
		writeBit true ;straightEdge
		writeUB (nBits: to integer! log-2 tmp: (880 - -1040)) 4
		nBits: nBits + 2
		writeBit false
		writeBit false ;horiz
		writeSB tmp nBits
		
		writeBit true
		writeBit true ;straightEdge
		writeUB (nBits: to integer! log-2 tmp: (1400 - -1480)) 4
		nBits: nBits + 2
		writeBit false
		writeBit true ;vert
		writeSB tmp nBits
		
		writeBit true
		writeBit true ;straightEdge
		writeUB (nBits: to integer! log-2 abs tmp: (-1040 - 880)) 4
		nBits: nBits + 2
		writeBit false
		writeBit false ;horiz
		writeSB tmp nBits
		
		writeBit true
		writeBit true ;straightEdge
		writeUB (nBits: to integer! log-2 abs tmp: (-1480 - 1400)) 4
		nBits: nBits + 2
		writeBit false
		writeBit true ;vert
		writeSB tmp nBits
		
		writeBit false
		writeUB 0 5
		return true
		
		}
		
		until [
			either carryBitLogic [ ;edge?
		;		print "edge"
				either carryBitLogic [;straightEdge?
					;print "line - "
					nBits: 2 + carryUB 4 ;original nBits - result may be different!
					;comment {
					either carryBitLogic [
						;GeneralLine
						carrySB nBits ;deltaX
						carrySB nBits ;deltaY
					][
						carryBitLogic
						carrySB nBits
					]
				][
					;print "curve - "
					nBits: 2 + carryUB 4
					carrySB nBits ;controlDeltaX
					carrySB nBits ;Y
					carrySB nBits ;anchorDeltaX
					carrySB nBits ;Y
				]
				false
			][
				states: carryUB 5
				either states = 0 [
					;EndShapeRecord
					alignBuffers
					;outBuffer: skip head outBuffer 2
					;writeRect reduce [minX - 100 maxX + 100 minY - 100 maxY + 100]
					;outByteAlign
					;probe head outBuffer
					true ;end
				][
					;StyleChangeRecord
					if 0 < (states and 1 ) [
				;		prin "Move "
						carrySBPair
					]      ;move
					if 0 < (states and 2 ) [ carryUB numFillBits] ;fillStyle0
					if 0 < (states and 4 ) [ carryUB numFillBits] ;fillStyle1
					if 0 < (states and 8 ) [ carryUB numLineBits] ;lineStyle
					if 0 < (states and 16) [
					;print "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
						alignBuffers
						loop carryCount [
							optimizeFILLSTYLE 
						]
						alignBuffers
						optimizeLINESTYLEARRAY
						numFillBits: carryUB 4 ;Number of fill index bits for new styles
						numLineBits: carryUB 4 ;...line...
					] ;NewStyles

					false ;continue
				]		
			]
		]
]

carryMATRIX: does [
	alignBuffers
	if carryBitLogic [;scale
		carryPair
	]
	if carryBitLogic [;rotate
		carryPair
	]
	carrySBPair 
	alignBuffers
]

updateBmpMATRIX: func[id /local size pos sc ro][
	print ["updateBmpMATRIX" id mold data]
	either any [
		none? size: select data/crops id
	;	all [size/1 = 0 size/2 = 0]
	][
		carryMATRIX
	][
		alignBuffers
		either carryBitLogic [;scale
			writePair sc: readPair
		][	sc: 0x0 ]
		either carryBitLogic [;rotate
			writePair ro: readPair
		][	ro: 0x0 ]
		pos: readSBPair

		
		writeSBPair reduce [
			round (pos/1 + ((size/5 * sc/1) + (size/6 * ro/2)))
			round (pos/2 + ((size/6 * sc/2) + (size/5 * ro/1))) ;- 30 ;((pos/2 / sc/2) * 20)
		]
		alignBuffers
	]
]

optimizeFILLSTYLE: has[type][
	alignBuffers
	
	writeUI8 type: readUI8 ;FillStyleType
	;print ["optimizeFILLSTYLE..." type tagId]
	case [
		type = 0 [
			;solid fill
			case [
				find [46 84] tagId [
					carryBytes 8 ;morph RGBAs
				]
				tagId >= 32 [carryBytes 4] ;RGBA
				true [carryBytes 3] ;RGB
			]
		]
		any [
			type = 16 ;linear gradient fill
			type = 18 ;radial gradient fill
			type = 19 ;focal gradient fill (swf8)
		][
			;gradient
			either find [46 84] tagId [
				;morph
				carryMATRIX
				carryMATRIX
				;MORPHGRADIENT:
				loop carryUI8 [
					carryBytes 10 ;Start ratio,Start color,End ratio,End color
				]
			][	;shape
				;print "./......................."
				carryMATRIX
				;GRADIENT:
				carryBits 4 ;SpreadMode + InterpolationMode
				loop carryUB 4 [
					;GRADRECORD
					carryBytes either tagId >= 32 [5][4] ;ratio + color
				]
				if all [type = 19 tagId = 83] [carryBytes 2] ;FocalPoint
			]
		]
		type >= 64 [
			;bitmap
			reduce either find [46 84] tagId [
				;morph
				writeUI16 id: readUI16
				updateBmpMATRIX id
				updateBmpMATRIX id
			][	;shape
				writeUI16 id: readUI16
				updateBmpMATRIX id
			]
		]
	]
]

optimizeLINESTYLEARRAY: has[LineStyles joinStyle hasFill?][
	;print "linestylearray"
	alignBuffers
	loop carryCount [ ;LineStyleCount
		alignBuffers
		;print ["linestyle" tagId]
		case [
			;DefineMorphShape
			tagId = 46 [
				carryBytes 12 ;StartWidth, EndWidth, RGBA + RGBA
			]
			;DefineShape4
			any [tagId = 67 tagId = 83][
				carryBytes 2   ;Width
				carryBits  2              ;f_start_cap_style
				joinStyle: carryUB 2     ;f_join_style
				hasFill?:  carryBitLogic ;f_has_fill
				carryBits 11 ;f_no_hscale,f_no_vscale,f_pixel_hinting,5*reserved,f_no_close,2*f_end_cap_style

				if joinStyle = 2 [carryBytes 2] ;miterLimit
				either hasFill? [optimizeFILLSTYLE][carryBytes 4]
			]
			;DefineMorphShape2
			tagId = 84 [
				carryBytes 4 ;StartWidth, EndWidth
				carryBits 2              ;f_start_cap_style
				joinStyle: carryUB 2     ;f_join_style
				hasFill?:  carryBitLogic ;f_has_fill
				carryBits 11 ;f_no_hscale,f_no_vscale,f_pixel_hinting,5*reserved,f_no_close,2*f_end_cap_style
				
				if joinStyle = 2 [carryBytes 2] ;miterLimit
				either hasFill? [optimizeFILLSTYLE][carryBytes 8]
			]
			true [
				carryBytes either tagId = 32 [6][5]
			]
		];case
	]
]