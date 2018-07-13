;PROYECTO FINAL 
;Materia: Lenguajes de Interfaz
;Equipo: 
;  -Ceja Gómez Hector
;  -Garcia Olivas Juan Pablo
;  -Meza Leon Quetzally


Include Irvine32.inc
INCLUDE macros.inc
TamBuf = 1000

mOpcion MACRO opcion
	mov edx, OFFSET opcion 	; Mostrar La Opcion 
	call WRITESTRING
ENDM

.data
opc1 BYTE '1) Crear Archivo' , 13,10 
opc2 BYTE '2) Leer Archivo' , 13,10
opc3 BYTE '3) Modificar Archivo' , 13,10
opc4 BYTE '4) Salir' , 13,10,0
cadTitulo BYTE "Proyecto Final",0

;-----------Variables Para Leer Por Consola------
bufer BYTE TamBuf DUP(?) 
buferAppend BYTE TamBuf DUP(?)    ; Buffer donde se guardara lo que se actualize
bufSizeAppend DWORD ($-buferAppend)
manejadorArchivo  HANDLE ? 
bytesLeidos	DWORD ?

leyenda db "PROYECTO FINAL", 0
MsjCreacion      BYTE "Archivo creado con exito.", 0dh,0ah
			     BYTE "Haga clic en Aceptar para continuar...", 0

MsjLectura       BYTE "Archivo leído con exito.", 0dh,0ah
			     BYTE "Haga clic en Aceptar para continuar...", 0

MsjActualizacion BYTE "Archivo modificado con exito.", 0dh,0ah
				 BYTE "Haga clic en Aceptar para continuar...", 0

nombreArchivo BYTE 80 DUP(0)
controladorArchivo HANDLE ?
cantCaracteres DWORD ?
bytesEscritos    DWORD ? 

cad1 BYTE "No se puede crear el archivo",0dh,0ah,0
cad2 BYTE "Bytes escritos en el archivo:",0 
cad3 BYTE "Escriba hasta 100 caracteres y oprima "     
	 BYTE "[Intro]: ",0dh,0ah,0 
cad4 BYTE "No se puede Abrir el Archivo", 13, 10,0
cad5 BYTE "Escriba nombre del archivo:",13,10,0 


.code
main PROC
	INVOKE SetConsoleTitle, ADDR cadTitulo
	CALL MostrarMenu
	call TomarOpcion

	exit
main ENDP

;--------------------Procedimiento para  Mostrar Menu--------------------------------------------
MostrarMenu PROC
	mWrite "Seleccione la opcion que desee: "
	call crlf
	mOpcion opc1

	
MostrarMenu ENDP

;-----------------Procedimiento para Hacer Comparacion del Menu-------------------
TomarOpcion PROC

	call READINT	; Toma el valor elegido por el usuario

	cmp eax, 1d	;Salta si opto por la opcion 1
	JE select1   

	cmp eax, 2d		; Salta a Opc2 si opto por la opcion 2
	JE select2

	cmp eax, 3d		; Salta a Opc3 si opto por la opcion 3
	JE select3

	cmp eax, 4d		; Salta a Opc4 si opto por la opcion 4
	JE select4
	JMP fFinal

	;----En caso de Seleccionar la Opcion 1-------------------------------------------
	select1:
		mWrite "Escriba el nombre del archivo: "
		MOV edx,OFFSET nombreArchivo       ;mover a edx el nombre que tendra el Archivo
		MOV ecx, SIZEOF nombreArchivo
		call crlf
		
		Call readString
		CALL CreateOutputFile 				;Crear Archivo guarda el manejador en EAX
		MOV   controladorArchivo,eax 		;Asignamos el Handler a controladorArchivo
		
 		CMP eax, INVALID_HANDLE_VALUE 	;Compara si ¿se encontró un error? 
 		JNE controlador_ok  				;El controlador fue correcto 	y salta
		MOV	edx,OFFSET cad1  			;Muestra mensaje de error y lo muestra en pantalla
 		CALL WriteString 				
 		JMP sFinal

 		controlador_ok:
			MOV   edx, OFFSET cad3  	; "Mensaje Escriba hasta maximo 100 caracteres" 
			CALL  WriteString 
			MOV	  ecx,TamBuf  			; Recibe el tamañ de bufer en una cadena como entrada 
			MOV   edx,OFFSET bufer 	
			CALL  ReadString 			;Lee los caracteres por consola
			MOV   cantCaracteres,eax  	;Cuenta los caracteres introducidos

			; Escribe el búfer en el archivo de salida. 
			MOV   eax,controladorArchivo  
			MOV   controladorArchivo,eax  

			MOV   edx,OFFSET bufer 
			MOV   ecx,cantCaracteres 
			CALL  WriteToFile 
			MOV   bytesEscritos,eax  ; guarda el valor de retorno 
			CALL  CloseFile
			; Muestra el valor de retorno. 
			MOV   edx,OFFSET cad2  ; "Bytes escritos" 
			CALL  WriteString 
			MOV   eax, bytesEscritos
			;call WriteWindowsMsg 
			CALL  WriteDec 
			CALL  Crlf

			mov ebx,OFFSET leyenda
			mov edx,OFFSET MsjCreacion
			call MsgBox
			JMP sFinal


		select2:

		mWrite "Escriba el nombre del archivo a leer: "
		MOV edx,OFFSET nombreArchivo       ;mover a edx el nombre que tendra el Archivo
		MOV ecx, SIZEOF nombreArchivo
		Call readString
		call  AbrirArchivo
		mov   manejadorArchivo,eax
		MOV controladorArchivo, eax
		; Comprueba errores. 
			CMP   eax,INVALID_HANDLE_VALUE  ; Hace una comparacion si existio un error
			JNE   leer_ok  					; Salta si todo salio bien
			mov edx, OFFSET cad4			;No se puede abrir el archivo
			call WriteString
			JMP sFinal  					; y termina  

			leer_ok:
			; Lee el archivo y lo coloca en un búfer.
			mov   edx,OFFSET bufer 
			mov   ecx,100							; solo mostrar hasta el 100cimo caracter
			
			call ReadFromFile
			JNC   comprobar_tamanio_bufer			; ¿error al leer? 
			;mWrite "Error al leer el archivo"		; sí: muestra mensaje de error 
			call  WriteWindowsMsg
			JMP   sFinal 

			comprobar_tamanio_bufer:
			push eax 
				cmp   eax,TamBuf					; ¿el búfer es lo bastante grande? 
				jb    tam_buf_ok					; sí 
				;mWrite <"Error: Bufer demasiado chico para el archivo",0dh,0ah> 
				jmp   sFinal						; y termina

				tam_buf_ok: 
					mov   bufer[eax],0  ; inserta terminador nulo mWrite "Tamaño del archivo: " 
					;call  WriteDec  ; muestra el tamaño del archivo 
					call  Crlf
					; Muestra el búfer. 
					;mWrite <"Bufer:",0dh,0ah,0dh,0ah> 
					mov edx,OFFSET bufer  ; muestra el búfer 
					call  WriteString 
					call Crlf
			pop eax
			
			mov ebx,OFFSET leyenda
			mov edx,OFFSET MsjLectura
			call MsgBox

			jmp sFinal


		select3: ;Modificar archivo
			mWrite "Escriba el nombre del archivo a leer: "
			MOV edx,OFFSET nombreArchivo       ;mover a edx el nombre que tendra el Archivo
			MOV ecx, SIZEOF nombreArchivo
			Call readString
			call modificacionArchivo
			mov controladorArchivo, eax
			MOV controladorArchivo, eax  
			cmp eax, INVALID_HANDLE_VALUE
			JNE ingresarTexto
			mov edx, OFFSET cad4			   ;error
			call WriteString
			jmp fFinal


			ingresarTexto:
				mov edx, OFFSET cad3
				call WriteString
				mov  edx,OFFSET buferAppend ; apunta al búfer 
				mov  ecx,100				; especifica el máximo de caracteres 
				call ReadString				; recibe la cadena de entrada
				mov   buferAppend[eax],0	; inserta terminador nulo

    		
				INVOKE SetFilePointer,
		 		controladorArchivo,0,0,FILE_END

				; Append text to the file
				INVOKE WriteFile,
					controladorArchivo, ADDR buferAppend, bufSizeAppend,
					ADDR bytesEscritos, 0

				INVOKE CloseHandle, controladorArchivo
				
				mov ebx,OFFSET leyenda
				mov edx,OFFSET MsjActualizacion
				call MsgBox
				jmp sFinal

				

		select4: 
			exit

		volver:
			call MostrarMenu
			call TomarOpcion

		sFinal: ;Cierra el controlador del Archivo
			mov   eax,controladorArchivo 
			call  CloseFile

			mWrite  "Presione 1 para volver al menu: "
			call READINT	; Toma el valor elegido por el usuario
			cmp eax, 1d		
			JE volver

		fFinal:

		

	ret
TomarOpcion ENDP

;--------------------Procedimiento para crear el archivo-------------------------
CrearArchivo PROC
	INVOKE CreateFile,
	  edx, GENERIC_WRITE, DO_NOT_SHARE, NULL,
	  CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	ret
CrearArchivo ENDP
;-----------------------------------------------------------------------------------
AbrirArchivo PROC 
; Abre un archivo existente en modo de entrada. 
; Recibe: EDX apunta al nombre del archivo. 
; Devuelve: Si el archivo se abrió con éxito, EAX 
; contiene un manejador de archivo válido. En caso contrario, 
; EAX es igual a INVALID_HANDLE_VALUE. 
;---------------------------------------------------------------------------------
 INVOKE CreateFile,   
 	edx, GENERIC_READ, DO_NOT_SHARE, NULL,   
 	OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0 
 	ret 
 AbrirArchivo ENDP
;---------------------------------------------------------------------------------

;---------------Procedimiento para añadir texto y actualizar-----------------------
modificacionArchivo PROC
 INVOKE CreateFile,
 ADDR nombreArchivo, GENERIC_WRITE, DO_NOT_SHARE, NULL,
	  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
 ret
modificacionArchivo ENDP
 ;-------------------------------------------------------------------------------
END main