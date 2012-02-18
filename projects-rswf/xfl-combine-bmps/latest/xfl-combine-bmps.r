REBOL [
	Title: "Xfl-combine-bmps"
	Date: 9-Feb-2012/19:13:06+1:00
	Author: "David 'Oldes' Oliva"
	require: [
		rs-project 'xfl-core
		rs-project 'rectangle-pack
	]
	usage: [
		;xfl-combine-bmps %/d/test/XFL/merge-one/   %/d/test/XFL/merge-one-result/
		;xfl-combine-bmps %/d/test/XFL/merge-multi/ %/d/test/XFL/merge-multi-result/
		xfl-combine-bmps %/d/test/XFL/combine-bmps/ %/d/test/XFL/combine-bmps-result/
	]
	preprocess: true
]

unless value? 'useSquareOnlyBitmaps? [useSquareOnlyBitmaps?: false]

with ctx-XFL [
	verbose: 1
	#include %rules_combine.r
	
	get-comp-size: func[data /local maxpair maxi][
		maxpair:  0x0
		foreach [size id] data [
			maxpair: max maxpair size
		]
		
		
		;maxi: max maxpair/x maxpair/y
		;print ["MAXI:" maxi]
		maxpair/x: to-integer round-to-pow2 maxpair/x
		maxpair/y: to-integer round-to-pow2 maxpair/y
		;print ["MAXPAIR:" maxpair] ;ask "[ENTER]"
		maxpair
	]

	get-best-pow2-result: func[images /local result minArea minResult][
		minArea: 9999999999
		minResult: none
		repeat i 4 [
			result: either useSquareOnlyBitmaps? [
				pow2-box-pack/method images i
			][
				pow2-rectangle-pack/method images i
			]
			if verbose > 1 [print ["possible result size:" result/1 "for method:" i]]
			if any [
				none? minResult
				result/2/3 < minArea
			][
				minArea:   result/2/3
				minResult: result
			]
			
		]
		if verbose > 1 [print ["POW2-RESULT:" mold minResult]]
		minResult
	]



	combine-files: func[files size into /local tmp png? *wand2 *pixel][
		if verbose > 0 [print ["COMBINE to size:" size "INTO:" mold to-local-file into]]
		with ctx-imagick [
			start
					*pixel: NewPixelWand
					PixelSetAlpha *pixel 0
					MagickNewImage *wand size/x size/y *pixel
					*wand2: NewMagickWand
					
					foreach [pos size file] files [
						if verbose > 1 [print [tab pos size file]]
						
						if block? file [parse file [to file! set file 1 skip]]
					
						unless all [
							not zero? MagickReadImage *wand2 utf8/encode to-local-file file
							tmp:  make image! size
							not zero? MagickExportImagePixels *wand2 0 0 size/x size/y "RGBO" 1 address? tmp
							not zero? MagickImportImagePixels *wand pos/x pos/y size/x size/y "RGBO" 1 address? tmp
						][
							errmsg: reform [
								Exception/Severity "="
								ptr-to-string tmp:  MagickGetException *wand2 Exception
							]
							MagickRelinquishMemory tmp
							if *wand2 [
								ClearMagickWand   *wand2
								DestroyMagickWand *wand2
								*wand2: none
							]               
							if *pixel [
								ClearPixelWand    *pixel
								DestroyPixelWand  *pixel
								*pixel: none
							]
							end
							make error! errmsg
						]
						ClearMagickWand   *wand2
					]
				not zero? MagickWriteImages *wand to-local-file into
				if *wand2 [
					ClearMagickWand   *wand2
					DestroyMagickWand *wand2
					*wand2: none
				]               
				if *pixel [
					ClearPixelWand    *pixel
					DestroyPixelWand  *pixel
					*pixel: none
				]
			end
		]
	]               
			
	combine-edges-bb: func[x y w h  a b c d /local xw yh x1 y1 x2 y2][
		xt1: 0
		xt2: w
		yt1: 0
		yt2: h
		
		x1: to-integer 20 * round/to ((xt1  * a) + (yt1  * c) + x) 0.05
		y1: to-integer 20 * round/to ((xt1  * b) + (yt1  * d) + y) 0.05
		
		x2: to-integer 20 * round/to ((xt2  * a) + (yt1  * c) + x) 0.05
		y2: to-integer 20 * round/to ((xt2  * b) + (yt1  * d) + y) 0.05
		
		x3: to-integer 20 * round/to ((xt2 * a) + (yt2 * c) + x) 0.05
		y3: to-integer 20 * round/to ((xt2 * b) + (yt2 * d) + y) 0.05
		
		x4: to-integer 20 * round/to ((xt1 * a) + (yt2 * c) + x) 0.05
		y4: to-integer 20 * round/to ((xt1 * b) + (yt2 * d) + y) 0.05
		rejoin [
			"!" x2 " " y2 "S2|" x3 " " y3
			"!" x3 " " y3   "|" x4 " " y4
			"!" x4 " " y4   "|" x1 " " y1
			"!" x1 " " y1   "|" x2 " " y2
		]
	]       

	combine-BitmapFill: func[node /local v atts matrix nx ny][
		atts: node/2
		if all [
			block? atts
			imgspec: select images-to-replace atts/("bitmapPath")
		][
			atts/("bitmapPath"): rejoin ["combined_" imgspec/3]
			if none? node/3 [
				node/3: to-DOM {<matrix><Matrix tx="0" ty="0"/></matrix>}
			]
			matrix: get-node reduce [node] %BitmapFill/matrix/Matrix
			
			;writeSBPair reduce [
			;   round (pos/1 + ((size/5 * sc/1) + (size/6 * ro/2)))
			;   round (pos/2 + ((size/6 * sc/2) + (size/5 * ro/1))) ;- 30 ;((pos/2 / sc/2) * 20)
			;]
			
			either v: select matrix/2 "a" [a: to-decimal v][ a: 1]
			either v: select matrix/2 "d" [d: to-decimal v][ d: 1]
			either v: select matrix/2 "b" [b: to-decimal v][ b: 0 ]
			either v: select matrix/2 "c" [c: to-decimal v][ c: 0 ]
		
			nx: imgspec/1/x
			ny: imgspec/1/y
			unless find matrix/2 "tx" [repend matrix/2 ["tx" 0]]
			unless find matrix/2 "ty" [repend matrix/2 ["ty" 0]]
			matrix/2/("tx"): (to-decimal matrix/2/("tx")) - (((nx * a) + (ny * c)) / 20) 
			matrix/2/("ty"): (to-decimal matrix/2/("ty")) - (((nx * b) + (ny * d)) / 20)
		]
	]
	combine-DOMBitmapInstance: func[node /local atts imgspec tx ty w h v a b c d dom matrix][
		atts: node/2
		if all [
			block? atts
			imgspec: select images-to-replace atts/("libraryItemName")
		][
			if verbose > 0 [print ["REPLACING:" atts/("libraryItemName")]]
			if verbose > 1 [probe imgspec]
			if none? node/3 [
				node/3: to-DOM {<matrix><Matrix tx="0" ty="0"/></matrix>}
			]
			matrix: get-node reduce [node] %DOMBitmapInstance/matrix/Matrix

			unless find matrix/2 "tx" [repend matrix/2 ["tx" 0]]
			unless find matrix/2 "ty" [repend matrix/2 ["ty" 0]]
			
			tx: to-decimal matrix/2/("tx")
			ty: to-decimal matrix/2/("ty")
			
			w: imgspec/2/x
			h: imgspec/2/y
			
			either v: select matrix/2 "a" [matrix/2/("a"): 20 * a: to-decimal v][ a: 1 insert matrix/2 ["a" "20"]]
			either v: select matrix/2 "d" [matrix/2/("d"): 20 * d: to-decimal v][ d: 1 insert matrix/2 ["d" "20"]]
			either v: select matrix/2 "b" [matrix/2/("b"): 20 * b: to-decimal v][ b: 0 ]
			either v: select matrix/2 "c" [matrix/2/("c"): 20 * c: to-decimal v][ c: 0 ]

			;matrix/2/("tx"): tx - imgspec/1/x
			;matrix/2/("ty"): ty - imgspec/1/y
			nx: imgspec/1/x
			ny: imgspec/1/y
			matrix/2/("tx"): tx - ((nx * a) + (ny * c))
			matrix/2/("ty"): ty - ((nx * b) + (ny * d)) 
			dom: to-DOM [
	{       <DOMGroup>
			  <members>
				<DOMShape>
				  <fills>
					<FillStyle index="1">
					  <BitmapFill bitmapPath="combined_} imgspec/3 {" bitmapIsClipped="false">
}                       form-xml reduce [get-node reduce [node] %DOMBitmapInstance/matrix ]{
					  </BitmapFill>
					</FillStyle>
				  </fills>
				  <edges>
					<Edge fillStyle1="1" edges="} combine-edges-bb tx ty w h a b c d {"/>
				  </edges>
				</DOMShape>
			  </members>
			</DOMGroup>
	}]
			clear node
			insert node dom/1
		]
	]
	set 'xfl-combine-bmps func[src trg][
		if verbose > 0 [
			print "^/=================================================="
			print   "=== COMBINE BMPs in XFL =========================="
			print  ["=== source:" src]
			print  ["=== target:" trg lf lf]
		]
		
		init/into-dir src trg

		ctx-iMagick/init-routines
		
		images-to-combine: copy []
		images-to-replace: copy []
		
		mediaItems: Media-content: get-node-content xmldom %DOMDocument/media
		if mediaItems [
			foreach item mediaItems [
				if item/1 = "DOMBitmapItem" [
					item-file: copy any [
						select item/2 "sourceExternalFilepath"
						join "./LIBRARY/" item/2/("href")
					]
					name: item/2/("name")
					if parse name ["_MERGE_" copy groupName to "/" to end][
						unless images: select images-to-combine groupName [
							append/only append images-to-combine groupName images: copy []
						]
						if imgFile: export-media-item/overwrite/into-file item/2 (
							rejoin [%./LIBRARY/ to-file (enbase/base checksum/secure item/2/("name") 16) %.png]
						) [
							repend/only append images get-image-size imgFile [name imgFile]
							new-line images true
						]
					]
				]
			]
		]
		
		foreach [group images] images-to-combine [
			new-line/skip images true 2

			
			new-line/skip images true 2
			if verbose > 1 [probe reduce [group images]]
			
			set [size result] get-best-pow2-result images
			
			if verbose > 0 [print  ["FINAL POW2 SIZE :" size "for:" group]] 
					
			combine-files result/1 size combinedImg: rejoin [xfl-target-dir %Library/combined_ encode-filename/as-utf8 group %.png]
			foreach [p1 p2 file] result/1 [
				repend/only append images-to-replace file/1 [p1 p2 group]
				attempt [delete file/2]
			]
			import-media-img/dom/smoothing combinedImg true
			
			mediaItems
		]
		
		;probe images-to-replace
		
		while [not tail? mediaItems] [
			item: mediaItems/1
			;probe item/2
			mediaItems: either find images-to-replace item/2/("name") [
				;print "----------------------" 
				remove mediaItems
			][  next   mediaItems ]
		]
		mediaItems: head mediaItems

		files-to-parse: either block? files-to-parse [
			clear head files-to-parse
		][  copy [] ]
		
		parse-xfl/act xmldom 'DOMDocument-combine
		
		files-to-parse: head files-to-parse
		while [not tail? files-to-parse] [
			file: files-to-parse/1
			files-to-parse: next files-to-parse
			recycle
			current-symbol: either file? file [
				current-symbol: form last split-path file 
				copy/part current-symbol find/last current-symbol "."
			][  copy/part file find/last file "." ]
			if verbose > 0 [print ["UPDATING:" mold to-file file]]

			either file? file [
				dom: to-DOM as-string read/binary file
				new-file: file
			][
				dom: to-DOM as-string read/binary xfl-source-dir/LIBRARY/(encode-filename file)
				new-file: join xfl-target-dir ["LIBRARY/" encode-filename file]
			]
			parse-xfl/act dom 'DOMSymbolItem-combine
			write new-file form-xml dom
		]

		write xfl-target-dir/DOMDocument.xml form-xml xmldom
		if verbose > 0 [print "^/--------------------------------------------------^/"]
		images-to-combine
	]
	
	
]


