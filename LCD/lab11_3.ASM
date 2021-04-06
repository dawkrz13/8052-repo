	MAG SET P1		;zdefiniowanie symboli
	RS SET P3.5
	E SET P3.4
	
	LJMP INIT		;skok do czesci inicjalizujacej
	
	ORG 0023H
	LJMP IRQUART		;skok do procedury obslugi przerwania od portu szeregowego
	
	ORG 50H
INIT:
	MOV SCON,#01010000B	;konfiguracja portu szeregowego
	MOV TMOD,#00100000B	;licznik T1 w trybie 2 - 8bitowy z automatycznym przeladowaniem
	MOV TCON,#01000000B	;wlaczenie ukladu licznikowego T1
	MOV IE,#10010000B	;wlaczenie przerwania od portu szeregowego			
	MOV R4,#0H		;inicjacja rejestru R4 - uzywany do zliczania aktualnej liczby znakow
	MOV R2,#2AH		;inicjacja rejestru R2 - uzywany w procedurze opoznienia DELAY1
	MOV DPTR,#4FFH		;inicjacja rejestru DPTR - uzywany w procedurze opoznienia DELAY2
	CALL INIT_LCD		;wywolanie procedury inicjalizujacej wyswietlacz LCD
	LJMP MAIN		;skok do programu glownego
	
	ORG 100H
MAIN:
	INC R2			;program glowny	
	LJMP MAIN
	
	ORG 150H
IRQUART:			;precedura obslugi przerwania od portu szeregowego
	MOV A,SBUF		;przepisanie do akumulatora kodu wprowadzonego znaku
	CJNE A,#03H,STEP1	;jesli wcisniemy CTRL + C (kod ASCII 03H) to wywolujemy CLEAR
	CALL CLEAR		;jesli nie to skaczemy do STEP1
STEP1:				
	CJNE R4,#32D,STEP2	;sprawdzamy czy wyswietlacz zostal zapelniony (32 znaki)
	CALL CLEAR		;jesli tak to wywolujemy CLEAR a jesli nie to do STEP2 
STEP2:
	CJNE R4,#16D,WRITE	;sprawdzamy czy 1 linia zostala zapelniona (czy jest 16 znakow)
	MOV A,#40H		;jesli tak to wpisujemy do akumulatora adres DD RAM 2 linii 1 znaku
	CALL DDSET		;i wywolujemy procedure DDSET z tym argumentem
WRITE:				;jesli pierwsza linia nie jest pelna to od razu przechodzimy do WRITE
	MOV A,SBUF		;a jesli jest pelna to dopiero po wywolaniu DDSET
	MOV SBUF, A		;we WRITE odsylamy wpisany znak do terminala
	CALL DISPLAY		;wywolujemy procedure DISPLAY
	INC R4			;inkrementujemy R4 - pojawil sie kolejny znak
	CLR TI			;zerujemy znacznik przerwania nadajnika
	CLR RI			;zerujemy znacznik przerwania odbiornika
	LJMP ENDIRQ		;skaczemy do konca procedury
ENDIRQ:
	RETI
	
	ORG 300H
INIT_LCD:
	CLR RS			;wybor rejestru instrukcji
	MOV MAG, #00111000B	;komenda function set
	CALL DELAY1		;wywolanie procedury opozniajacej aby instrukcje mialy czas sie wykonac
	MOV MAG, #00001000B	;komenda display off
	CALL DELAY1
	MOV MAG, #00000001B	;komenda display clear
	CALL DELAY2
	MOV MAG, #00000110B	;komenda entry mode set
	CALL DELAY1
	MOV MAG, #00001111B	;komenda display on
	CALL DELAY1
	RET
	
	ORG 350H
DELAY1:				;opoznienie 1 - dla komend o tmax 40us
	DJNZ R2, DELAY1		;pusta petla dekrementujaca R2 do 0
	MOV R2, #2AH		;ponowne ustawienie R2
	RET
	
DELAY2: 			;opoznienie 2 - dla display clear gdzie tmax 1,64us
	DJNZ DPL, DELAY2	;pusta petla dekrementujaca DPTR do 0
DELAY2_1:				
	DJNZ DPH, DELAY2_1
	MOV DPTR, #4FFH		;ponowne ustawienie DPTR		
	RET
	
	ORG 400H
DDSET:				;DD RAM set
	CLR RS			;wybor rejestru instrukcji
	MOV MAG, A		;do magistrali danych (bity DB6 - DB0) wpisujemy adres DD RAM
	SETB P1.7		;ustawiamy bit DB7 w celu wykonania instrukcji DD RAM set
	SETB E			;odblokowanie wyswietlacza zboczem opadajacym na linii E
	CLR E
	CALL DELAY1
	RET
	
	ORG 450H
DISPLAY:			;procedura wypisujaca znaki na wyswietlaczu LCD
	SETB RS			;wybor rejestru danych
	MOV MAG, A		;wpisanie do magistrali danych zawartosci akumulatora (kodu znaku)
	SETB E			;odblokowanie wyswietlacza zboczem opadajacym na linii E
	CLR E
	CALL DELAY1
	RET
	
CLEAR:				;procedura czyszczaca zawartosc wyswietlacza LCD
	MOV R4,#0H		;wpisujemy zero do R4
	MOV A,#0H		;wpisujemy nowy adres DD RAM do akumulatora - 1 linia, 1 znak
	CALL DDSET		;wywolujemy procedure DDSET
	CLR RS			;wybor rejestru instrukcji
	MOV MAG,#00000001B	;komenda Display clear
	SETB E			;odblokowanie wyswietlacza zboczem opadajacym na linii E
	CLR E
	CALL DELAY2
	RET
	
KONIEC: 
	LJMP KONIEC
END
	