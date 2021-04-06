	T2CON SET 0C8H		;zdefiniowanie symboli
	RCAP2H SET 0CBH
	RCAP2L SET 0CAH
	
	LJMP INIT		;skok do czesci inicjalizujacej
	
	ORG 0023H		
	LJMP IRQUART		;skok do procedury obslugujacej przerwanie od portu szeregowego
	
	ORG 100H
INIT:
	MOV SCON,#01010000B	;konfiguracja portu szeregowego
	MOV T2CON, 00110100B	;konfiguracja licznika T2
	MOV IE,#10010000B	;wlaczenie i konfiguracja kontrolera przerwan
	MOV R0,#40H		;inicjalizacja rejestrow R0 i R1 wartosciami 40H
	mov R1,#40H
	LJMP START		
	
	ORG 150H
START:				
	INC R2			;petla glowna
	LJMP START
	
	ORG 200H
IRQUART:			;procedura obslugujaca przerwanie od portu szeregowego
	JNB RI,NXT		;jesli ustawiony jest znacznik RI to wywolujemy procedure odbiorcza
	CALL REC		;jesli nie to skaczemy do NXT i sprawdzamy znacznik TI
NXT:
	JNB TI,IRQEND		;jesli ustawiony jest znacznik TI to wywolujemy procedure nadawcza
	CALL SEND		;jesli nie to skaczemy do IRQEND i konczymy procedure
IRQEND:
	CLR TI			;na koniec zawsze resetujemy znaczniki TI oraz RI
	CLR RI
	RETI
	
	ORG 250H
REC:				;procedura odbiorcza
	MOV A,SBUF		;przepisujemy kod znaku do akumulatora
	MOV @R0,A		;przepisujemy zawartosc akumulatora do komorki o adresie znajdujacym sie w R0
	INC R0			;inkrementujemy R0 zeby kolejny znak zostal wpisany do nastepnej komorki
	CJNE R0,#50H,ENDREC	;jesli dotarlismy do komorki o adresie 50H to resetujemy R0 do wartosci
	MOV R0,#40H		;poczatkowej (zawijamy wektor) oraz wywolujemy procedure nadawcza 
	CALL SEND		;jesli nie to konczymy procedure odbiorcza
ENDREC:
	RET
	
	ORG 300H
SEND:				;procedura nadawcza
	MOV SBUF,@R1		;wysylamy do terminala znak o kodzie zawartym w komorce o adresie znajdujacym sie w R1
	INC R1			;inkrementujemy R1 zeby kolejny znak wyslany zostal z nastepnej komorki
	CJNE R1,#50H,SEND	;jesli dotarlismy do komorki o adresie 50H to resetujemy R1 do wartosci
	MOV R1,#40H		;poczatkowej (zawijamy wektor) oraz resetujemy znacznik TI
	CLR TI			;jesli nie to skaczemy do SEND i przepisujemy kolejny znak
	RET
	
	END