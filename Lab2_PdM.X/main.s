;*******************************************************************************
; Universidad del Valle de Guatemala
; IE20203 Programación de Microcontroladores
; Autor: Byron Barrientos
; Compilador: PIC-AS (v2.36), MPLAB X IDE (v.600)
; Proyecto: TMR0_y_Botones
; Hardware: PIC16F887
; Creado: 01/08/2022
; Última Modificación: 08/08/2022
;*******************************************************************************

PROCESSOR 16F887
#include <xc.inc>
;*******************************************************************************
;Palabra de configuración
;***************************************************************************
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO 
                                ;oscillator: I/O function on RA6/OSC2/CLKOUT
				;pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF             ; Watchdog Timer Enable bit (WDT enabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR 
                                ;pin function is digital input, MCLR internally
				;tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code
                                ;protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code
                                ;protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit 
                                ;(Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
                                ;(Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin
                                ;has digital I/O, HV on MCLR must be used for 
				;programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out 
                                ;Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
                                ;(Write protection off)

;*******************************************************************************
;Variables
;*******************************************************************************
PSECT udata_shr
 FLAG:                 ; Lleva el control de los antirrebotes
    DS 1 
CONTADOR:              ; Lleva el control del valor del contador de 1s
    DS 1
DISPLAY:               ; Lleva el control del valor del display
    DS 1
COMP_DYC:              ; Compara DISPLAY y CONTADOR
    DS 1
ALRM_LED:              ; Enciende o apaga el LED de la alarma
    DS 1
    
;*******************************************************************************
;Vector Reset
;*******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0000
    GOTO MAIN

;*******************************************************************************
;Código Principal
;*******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0100

MAIN:
    
;*******************************************************************************
; Configuración del oscilador interno
;*******************************************************************************
    
    banksel OSCCON      ; Selección del banco donde se encuentra OSCCON
  
    ;Se configura el oscilador a 2MHz:
    
    bsf OSCCON, 6       ; IRCF2 en 1
    bcf OSCCON, 5       ; IRCF1 en 0
    bsf OSCCON, 4       ; IRCF0 en 1
    
    bsf OSCCON, 0       ; Se selecciona el Reloj Interno
    
;*******************************************************************************
; Preparación para el circuito
;*******************************************************************************
    
    banksel ANSEL       ; Selección del banco donde se encuentra ANSEL
    clrf ANSEL          
    clrf ANSELH         ; Los pines son todas I/O digitales
    
    banksel TRISA       ; Selección del banco donde se encuentra TRISA
    bsf TRISA, 0        ; Se configura el pin RA0 como un input
    bsf TRISA, 1        ; Se configura el pin RA1 como un input
    clrf TRISB          ; Se configura el puerto TRISB como un output
    clrf TRISC          ; Se configura el puerto TRISC como un output
    clrf TRISD          ; Se configura el puerto TRISD como un output
    clrf TRISE          ; Se configura el puerto TRISE como un output
    
    banksel PORTA       ;Selección del banco donde se encuentra PORTA
    clrf PORTA          ; Se inicia el puerto
    clrf PORTB          ; Se inicia el puerto
    clrf PORTC          ; Se inicia el puerto
    clrf PORTD          ; Se inicia el puerto
    clrf PORTE          ; Se inicia el puerto
    
    ; Configuración de TMR0
    
    banksel OPTION_REG  ; Selección del banco donde se encuentra OPTION_REG
    
    bcf OPTION_REG, 5	; T0CS: selección de FOSC/4 como reloj temporizador
    bcf OPTION_REG, 3	; PSA: asignamos el prescaler al TMR0
    
    bsf OPTION_REG, 2
    bsf OPTION_REG, 1
    bsf OPTION_REG, 0	; PS2-0: Prescaler en 1:256
    
    banksel PORTB       ; Selección del banco donde se encuentra PORTB
    clrf CONTADOR	; Se limpia CONTADOR
    movlw 61            ; Se carga 61 a W
    movwf TMR0		; Se carga el valor de n = 195 para obtener los 100ms
    clrf DISPLAY        ; Se limpia DISPLAY
    clrf COMP_DYC       ; Se limpia COMP_DYC
    bsf COMP_DYC, 0     
    
;*******************************************************************************
; Ejecución del programa principal
;*******************************************************************************
    
LOOP:
    
    ; Display
    
    incf PORTC          ; Se incrementa en 1 el valor de PORTC
    btfsc PORTA, 0      ; Revisa el bit 0 de PORTA; si vale 0, se salta el 
                        ; call de ANTIRREBOTE_0
    call ANTIRREBOTE_0
    btfss PORTA, 0      ; Revisa el bit 0 de PORTA; si vale 1, se salta el 
                        ; call de INCREMENTO_B
    call INCREMENTO
    btfsc PORTA, 1      ; Revisa el bit 1 de PORTA; si vale 0, se salta el 
                        ; call de ANTIRREBOTE_1
    call ANTIRREBOTE_1
    btfss PORTA, 1      ; Revisa el bit 1 de PORTA; si vale 1, se salta el 
                        ; call de DECREMENTO_B
    call DECREMENTO
    
    ; Temporizador
    
    btfss INTCON, 2     ; Revisa si el TOIF está en 1 por overflow; si vale 1, 
                        ; se salta el goto
    goto $-1            ; Si está en 0 vuelve a revisar
    bcf INTCON, 2       ; Si está en 1 se borra la bandera del T0IF
    movlw 61            ; Se carga 61 a W
    movwf TMR0          ; Se carga W a TMR0 para que n = 195 y así tener 100ms
    
    ; Contador de 1s
    
    incf CONTADOR, F    ; Después de 100ms, se incrementa en 1 
                        ; el valor de CONTADOR
    movf CONTADOR, W    ; Se carga el valor de CONTADOR a W
    sublw 10	        ; Se resta el valor de CONTADOR a 10
    BTFSS STATUS, 2     ; Se verifica si el resultado es 10, si vale 1, se
                        ; salta el goto LOOP; si es 0, regresa a LOOP y se
			; se limpia CONTADOR
    goto LOOP	        
    clrf CONTADOR	        
    incf PORTB	        ; Se incrementa en 1 PORTB
    movlw 61	        ; Se carga 61 a W
    movwf TMR0          ; Se carga W a TMR0 para que n = 195 y así tener 100ms
    
    ; Alarma
    
    bcf STATUS, 2       ; Se hace 0 el 2do bit de STATUS
    movf COMP_DYC, W    ; Se carga el valor de COMP_DYC a W
    andlw 0x0F          ; Se hace un AND entre W y 0x0F para asegurar que el
                        ; valor de W es de 4 bits
    movwf COMP_DYC      ; Se carga el valor de W a COMP_DYC
    movf PORTB, W       ; Se carga el valor de PORTB a W
    andlw 0x0F          ; Se hace un AND entre W y 0x0F para asegurar que el
                        ; valor de W es de 4 bits
    subwf COMP_DYC, W   ; Se le resta el valor de W a COMP_DYC
    btfss STATUS, 2     ; Revisa el 2do bit de STATUS; si no es 0, se ejecuta el 
                        ; goto LOOP porque no son iguales; si son iguales, se
			; se salta el goto LOOP	
    goto LOOP
    clrf PORTB          ; Se limpia PORTB (para regresarlo a 0)
    comf ALRM_LED, F    ; Si ALRM_LED es 0, se cambia a 1; y visceversa
    movf ALRM_LED, W    ; Se carga el valor de ALRM_LED a W
    movwf PORTE         ; Se carga el valor de W a PORTE
    goto LOOP
    
;*******************************************************************************
; Subrutinas
;*******************************************************************************

TABLA:
    clrf PCLATH
    bsf PCLATH, 0
    andlw 0x0F         ; Se hace un AND entre W y 0x0F, esto permite que si el
                       ; número a incrementar/decrementar es de más de 4 bits, 
		       ; se incremente a 0 o se decremente a 15
    addwf PCL          ; Suma el valor de W a PCL (Se le indica a PCL a cual
                       ; número apuntar)
    retlw 11000000B    ;0
    retlw 11111001B    ;1
    retlw 10100100B    ;2
    retlw 10110000B    ;3
    retlw 10011001B    ;4
    retlw 10010010B    ;5
    retlw 10000010B    ;6
    retlw 11111000B    ;7
    retlw 10000000B    ;8
    retlw 10010000B    ;9
    retlw 10001000B    ;A
    retlw 10000011B    ;B
    retlw 11000110B    ;C
    retlw 10100001B    ;D
    retlw 10000110B    ;E
    retlw 10001110B    ;F
 
ANTIRREBOTE_0:
    bsf FLAG, 0        ;Si se presiona el pb, se enciende el 1er bit de FLAG
    return             ;Si FLAG es diferente a 1, se regresa a LOOP
    
INCREMENTO:
    btfss FLAG, 0      ;Revisa el 1er bit de FLAG; si vale 1, se salta el 
                       ;return (si el pb está presionado, sigue la instrucción)
    return
    incf DISPLAY, F    ;Se incrementa en 1 el valor de DISPLAY
    movf DISPLAY, W    ;Se mueve el valor de DISPLAY a W
    call TABLA
    movwf PORTD        ;Se mueve el valor W proveniente de la tabla al PORTD
    clrf FLAG          ;Se limpia FLAG
    incf COMP_DYC      ;Se incrementa en uno el valor de COMP_DYC
    return
    
ANTIRREBOTE_1:
    bsf FLAG, 1        ;Si se presiona el pb, se enciende el 2do bit de FLAG
    return             ;Si FLAG es diferente a 1, se regresa a LOOP
    
DECREMENTO:
    btfss FLAG, 1      ;Revisa el 1er bit de FLAG; si vale 1, se salta el 
                       ;return (si el pb está presionado, sigue la instrucción)
    return
    decf DISPLAY, F    ;Se decrementa en 1 el valor de DISPLAY
    movf DISPLAY, W    ;Se mueve el valor de DISPLAY a W
    call TABLA
    movwf PORTD        ;Se mueve el valor W proveniente de la tabla al PORTD
    clrf FLAG          ;Se limpia FLAG
    decf COMP_DYC      ;Se decrementa en 1 el valor de COMP_DYC
    return
        
;*******************************************************************************
; Fin de Código
;*******************************************************************************
END