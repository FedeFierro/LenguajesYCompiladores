%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "y.tab.h"
#include <string.h>
#include "pila.h"
#include <ctype.h>

	int yystopparser=0;
	FILE  *yyin;
	char *yyltext;
	char *yytext;
	FILE *archivoCodigoIntermedio;
	char mensajeDeError[200];
	char conversionItoA[20];
	char bufferaux1[20];
	char bufferaux2[20];
	char constanteAux[20];

	/* --------------- CONSTANTES --------------- */

#define TAM_NOMBRE 32	/* Limite tamaño nombre (sumar 1 para _ ) */
#define CteString "CTE_STRING"
#define CteInt "CTE_INT"
#define CteReal "CTE_REAL"
#define VAR_FILTER "@Filter"
#define TIPO_FILTER "REAL"

	/* --------------- TABLA DE SIMBOLOS --------------- */

	typedef struct
	{
		char nombre[100];
		char tipo  [11];
		char valor [100];
		int longitud;
	} struct_tabla_de_simbolos;

	struct_tabla_de_simbolos tablaDeSimbolos[200];


	/* --------------- PROTOTIPO DE FUNCIONES --------------- */

	void guardarTabla(void);
	void agregarConstante(char*,char*);
	int buscarCte(char* , char*);
	void validarVariableDeclarada(char* nombre);
	void mostrarError(char *mensaje);
	void guardarTipo(char * tipoVariable);
	void guardarEnVectorTablaSimbolos(int opc, char * cad);
	void acomodarPunterosTS();
	void quitarDuplicados();
	void copiarCharEn(char **, char*);
	int crear_terceto(char*, char*, char*);
	void escribe_arch_tercetos();
	char* validaTipo(char* );
	

	int cantidadTokens = 0;
	int i=0; 
	int j=0;
	int cant_elementos=0;
	int min=0;
	int pos_td=0;
	int pos_cv=0;
	int cant_variables=0;
	int cant_tipo_dato=0; 
	int diferencia=0;
	int cant_ctes=0;
	int finBloqueDeclaraciones=0;
	int ladoDerecho=0;
	int ladoIzquierdo=0;
	int aux1=0;
	int aux2=0;
	char tipoVariableActual[20];
	char tipoVariable[10];

	char* operadorAux;
	char idAux[20];

	int yylex();
	int yyerror();
	
	typedef struct{
		char id[35];
		char tipo[10];
	} operacion;
	
	operacion vector_operacion[100];
	int cantOperaciones=0;

	/* --------------- TERCETOS -------------- */

#define DEBUG		0

	typedef struct terceto {
		int nroTerceto;
		char ope[35];
		char te1[30];
		char te2[30];
	}	terceto;

	terceto  vector_tercetos[200]; 		// vector de tercetos
	int indice_terceto = 0;	   			// Cantidad de elementos e indice de tercetos

	int F_ind=0;
	int	T_ind=0;
	int E_ind=0;
	int ASIG_ind=0;
	int aux=0;
	int auxRepeat=0;
	
	Pila pilaExpresion;
	Pila pilaTermino;
	Pila pilaFactor;
	Pila pilaTercetoActual;					// para la parte de IF / REPEAT (?)
	Pila pilaIf;
	Pila pilaRepeat;
	Pila pilaOperacion;
	Pila pilaFilter;

	/* --------------- FILTER -------------- */

	int cont_filter=0;
	int seq_variable_filter=0;
	terceto vector_filter[4];			// vector de tercetos para filter 	
	terceto vector_condicion_filter[2];	// vector de tercetos para condicion de filter
	int condicion_filter_doble=0;	// para saber si es una condicion doble;
	int condicion_filter_or=0;		//para saber si la condicion es con or;
	char tipoCondicion1[10];
	char tipoCondicion2[10];
	
	/* ---- FUNCIONES FILTER -------------*/
	
	void invertir_salto(terceto* vector, int indice);
	void crear_tercetos_filter();
	void agregar_variable_filter_a_tabla();

	/* --------------- ASigMultiple -------------- */
	
	typedef struct asign_multiple {
		
		char valor[10];
		char nombre[35];
		char tipo[35];
		
	}	asign_multiple;

	asign_multiple  vector_asig_multiple[200]; 		// vector de tercetos
	int indice_asign_multiple=0;
	int indice_expresiones_asign_multiple = 0;
	

	%}

%union {
	int int_val;
	double float_val;
	char *str_val;
}

%start start_programa

%token COMENTARIOS 
COMENTARIOS_ANIDADOS 
REPEAT 
UNTIL
OPERACION_SUMA
OPERACION_RESTA
OPERACION_MULTIPLICACION
OPERACION_DIVISION
ID
ENTERO
REAL
PARENTESIS_ABIERTO
PARENTESIS_CERRADO
COMA
OPERADOR_ASIGNACION
CADENA
READ
PRINT
OPERADOR_IF 
OPERADOR_THEN
OPERADOR_ELSE
OPERADOR_ENDIF
OPERADOR_AND
OPERADOR_OR
OPERADOR_NOT
OPERADOR_MAYOR_A
OPERADOR_MENOR_A
OPERADOR_MAYOR_O_IGUAL_A
OPERADOR_MENOR_O_IGUAL_A
OPERADOR_IGUAL_A
OPERADOR_DISTINTO_A
VAR
ENDVAR
DOS_PUNTOS
PUNTO_Y_COMA
TIPO_ENTERO
TIPO_REAL
TIPO_CADENA
CORCHETE_ABIERTO
CORCHETE_CERRADO
FILTER
GUION_BAJO
OPERADOR_ASIG_STRING

%%

start_programa : programa 
{ printf("Compilacion exitosa\n\n"); };

programa : bloque_declaracion  bloque_programa
{ printf("Programa OK\n\n"); };

bloque_declaracion: VAR lista_definiciones ENDVAR 
{ 
	finBloqueDeclaraciones=1;
	quitarDuplicados(); 
	printf("bloque_definiciones OK\n\n");
	cant_ctes=cantidadTokens;	
};

lista_definiciones: lista_definiciones definicion {	printf("lista_definiciones -> lista_definiciones definicion OK\n\n");} 
| definicion {	printf("lista_definiciones -> definicion OK\n\n");}

definicion: CORCHETE_ABIERTO lista_tipo_dato CORCHETE_CERRADO DOS_PUNTOS CORCHETE_ABIERTO lista_ids CORCHETE_CERRADO 
{ acomodarPunterosTS(); printf("definicion OK\n\n");};

lista_tipo_dato: lista_tipo_dato COMA tipo_dato	{ printf("lista_tipo_dato -> lista_tipo_dato , tipo_dato OK\n\n");} 
| tipo_dato {printf("lista_tipo_dato -> tipo_dato OK \n\n");}

tipo_dato: 
TIPO_ENTERO { 
	guardarTipo("ENTERO");
	guardarEnVectorTablaSimbolos(1,tipoVariableActual);
	printf("TIPO_ENTERO en tipo_variable OK\n\n");
}
| TIPO_REAL {
	guardarTipo("REAL");
	guardarEnVectorTablaSimbolos(1,tipoVariableActual);
	printf("TIPO_REAL en tipo_variable OK\n\n");
}
| TIPO_CADENA{
	guardarTipo("CADENA");
	guardarEnVectorTablaSimbolos(1,tipoVariableActual);
	printf("TIPO_CADENA en tipo_variable OK\n\n");
}

lista_ids: 
lista_ids COMA ID {
	printf("%s\n", yylval.str_val);
	guardarEnVectorTablaSimbolos(2,yylval.str_val);
	printf("lista_ids -> lista_ids , ID OK\n\n");
}
| ID {
	printf("%s\n", yylval.str_val);
	guardarEnVectorTablaSimbolos(2,yylval.str_val);
	printf("lista_ids -> ID OK\n\n");
}

bloque_programa : bloque_programa sentencia {printf("bloque_programa -> bloque_programa sentencia OK \n\n");}
| sentencia {printf("bloque_programa -> sentencia OK \n\n");}

sentencia : asignacion 	{printf("sentencia -> asignacion OK \n\n");}
| bloque_condicional	{printf("sentencia -> bloque_condicional OK \n\n");} 
| asignacion_multiple 	{printf("sentencia -> asignacion_multiple OK \n\n");}
| bloque_iteracion 		{printf("sentencia -> bloque_iteracion OK \n\n");}
| entrada_datos			{printf("sentencia -> entrada_datos OK \n\n");}
| salida_datos			{printf("sentencia -> salida_datos OK \n\n");}

entrada_datos: READ ID 	{ 
	strcpy(idAux,yylval.str_val);	 
	if(strcmp(validaTipo(idAux),idAux)!=0)
	{
		crear_terceto("READ",idAux,"_");
		printf("READ ID OK \n\n");
	}
	else{
		sprintf(mensajeDeError, "La Variable: %s No esta definida", idAux);
		mostrarError(mensajeDeError);
	}
}

salida_datos: PRINT CADENA { 
	strcpy(idAux,yylval.str_val);
	if(strcmp(validaTipo(idAux),"CADENA")!=0)
	{sprintf(mensajeDeError, "La Variable: %s No es de tipo CADENA.\n", idAux);
		mostrarError(mensajeDeError);
	}
	else
	{printf("PRINT CADENA OK \n\n");
		agregarConstante(yylval.str_val,CteString);
		crear_terceto("PRINT",idAux,"_");}
}
| PRINT ID  
{
	strcpy(idAux,yylval.str_val);
	if(strcmp(validaTipo(idAux),"ENTERO")==0||strcmp(validaTipo(idAux),"REAL")==0)
	{ printf("PRINT ID OK\n\n");crear_terceto("PRINT",idAux,"_");}
	else {
		sprintf(mensajeDeError, "La Variable: %s No es de tipo numerico.\n", idAux);
		mostrarError(mensajeDeError);
	}
}

bloque_iteracion: REPEAT {apilar(&pilaRepeat,indice_terceto);
	auxRepeat=indice_terceto;}	bloque_programa UNTIL condicion 
{printf("bloque REPEAT-UNTIL OK\n\n");}

asignacion: ID {strcpy(idAux,yylval.str_val);} OPERADOR_ASIGNACION expresion PUNTO_Y_COMA	
{
	printf("asignacion OK\n\n");
	aux=desapilar(&pilaOperacion);
	if(strcmp(vector_operacion[aux].tipo,validaTipo(idAux))==0)
	{E_ind = desapilar(&pilaExpresion);
		itoa(E_ind,conversionItoA,10);
		ASIG_ind = crear_terceto("=",idAux,conversionItoA);
	}
	else
	{
		sprintf(mensajeDeError, "La Variable: %s No es de tipo %s.\n", idAux, vector_operacion[aux].tipo);
		mostrarError(mensajeDeError);
	}
}

| ID {strcpy(idAux,yylval.str_val);
	strcpy(tipoVariable,validaTipo(idAux));
} OPERADOR_ASIG_STRING 
{
	if(strcmp(tipoVariable,"CADENA")!=0)
	{sprintf(mensajeDeError, "La Variable: %s No es de tipo CADENA.\n", idAux);
		mostrarError(mensajeDeError);
	}
} 	CADENA PUNTO_Y_COMA	{printf("asignacion_string -> Cte_String OK \n\n");
	agregarConstante(yylval.str_val,CteString);
	strcpy(constanteAux,"_");
	strcat(constanteAux,yylval.str_val);
	strcpy(constanteAux + strlen(constanteAux), "\0");
	crear_terceto("=",idAux,constanteAux);
}

expresion:  expresion OPERACION_SUMA termino	
{printf("expresion -> exp + term OK \n\n");
	
	aux=desapilar(&pilaOperacion);
	aux1=desapilar(&pilaOperacion);
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaExpresion),bufferaux1,10);
		itoa(desapilar(&pilaTermino),bufferaux2,10);
		E_ind = crear_terceto("+",bufferaux1,bufferaux2 );
		apilar(&pilaExpresion,E_ind);
		apilar(&pilaOperacion,aux);
	}else
	{	sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la suma\n");
		mostrarError(mensajeDeError);
	}

} 
| expresion OPERACION_RESTA termino 	
{
	printf("expresion -> exp - term OK \n\n");
	aux=desapilar(&pilaOperacion);
	aux1=desapilar(&pilaOperacion);	
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaExpresion),bufferaux1,10);
		itoa(desapilar(&pilaTermino),bufferaux2,10);
		E_ind = crear_terceto("-",bufferaux1,bufferaux2 );
		apilar(&pilaExpresion,E_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la resta\n");
		mostrarError(mensajeDeError);
	}
}

| termino							{printf("expresion -> term OK \n\n");
	E_ind = desapilar(&pilaTermino);
	apilar(&pilaExpresion,E_ind);
}

termino:	termino OPERACION_MULTIPLICACION factor 
{
	printf("term -> term * factor OK \n\n");
	aux=desapilar(&pilaOperacion);
	aux1=desapilar(&pilaOperacion);
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaTermino),bufferaux1,10);
		itoa(desapilar(&pilaFactor),bufferaux2,10);
		T_ind=crear_terceto("*",bufferaux1,bufferaux2);
		apilar(&pilaTermino,T_ind);
		apilar(&pilaOperacion,aux);
	} else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la multiplicacion\n");
		mostrarError(mensajeDeError);
	}
}
| 			termino OPERACION_DIVISION factor 	
{
	printf("term -> term / factor OK \n\n");
	aux=desapilar(&pilaOperacion);
	aux1=desapilar(&pilaOperacion);
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaTermino),bufferaux1,10);
		itoa(desapilar(&pilaFactor),bufferaux2,10);
		T_ind=crear_terceto("/",bufferaux1,bufferaux2);
		apilar(&pilaTermino,T_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la division\n");
		mostrarError(mensajeDeError);
	}
}

| factor			{printf("term -> factor OK \n\n");
	T_ind = desapilar(&pilaFactor);
	apilar(&pilaTermino,T_ind);
}

factor: ID  {
	printf("factor -> ID OK\n\n");
	strcpy(vector_operacion[cantOperaciones].id,yylval.str_val);
	strcpy(vector_operacion[cantOperaciones].tipo,validaTipo(yylval.str_val));
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(yylval.str_val,"_","_");
	apilar(&pilaFactor,F_ind);
}

| ENTERO 	{
	printf("factor -> Cte_entera OK\n\n");agregarConstante(yylval.str_val,CteInt);
	strcpy(constanteAux,"_");
	strcat(constanteAux,yylval.str_val);
	strcpy(constanteAux + strlen(constanteAux), "\0");
	strcpy(vector_operacion[cantOperaciones].id,constanteAux);
	strcpy(vector_operacion[cantOperaciones].tipo,"ENTERO");
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(constanteAux,"_","_");
	apilar(&pilaFactor,F_ind);
}
| REAL		{printf("factor -> Cte_Real OK\n\n");
	agregarConstante(yylval.str_val,CteReal);
	strcpy(constanteAux,"_");
	strcat(constanteAux,yylval.str_val);
	strcpy(constanteAux + strlen(constanteAux), "\0");
	strcpy(vector_operacion[cantOperaciones].id,constanteAux);
	strcpy(vector_operacion[cantOperaciones].tipo,"REAL");
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(constanteAux,"_","_");
	apilar(&pilaFactor,F_ind);
}	

| PARENTESIS_ABIERTO expresion PARENTESIS_CERRADO	{printf("factor -> ( expresion ) OK\n\n");
	F_ind = desapilar(&pilaExpresion);
	apilar(&pilaFactor,F_ind);
}

| filtro {printf("factor -> filtro OK\n\n");
	char nombreFilter[100];
	strcpy(nombreFilter,VAR_FILTER);
	char seqAux[10];
	itoa(seq_variable_filter,seqAux,10);
	strcat(nombreFilter, seqAux);
	F_ind = crear_terceto(nombreFilter,"_","_");
	apilar(&pilaFactor,F_ind);
}

bloque_condicional: bloque_if {printf("bloque_condicional OK\n\n\n");}

bloque_if: OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO bloque_programa OPERADOR_ENDIF	
{
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					
	strcpy(vector_tercetos[aux].te1,bufferaux1);		// desapilo y voy al final
}

| OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux);}	OPERADOR_AND comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO bloque_programa OPERADOR_ENDIF
{
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// desapilo y pongo donde voy en la segunda cond - voy al final
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// desapilo y pongo donde voy en la primer cond - voy al final
	strcpy(vector_tercetos[aux].te1,bufferaux1);
}

|	OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux); apilar(&pilaIf,crear_terceto("JMP","_","_"));} OPERADOR_OR comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO {aux1=indice_terceto;} bloque_programa OPERADOR_ENDIF
{
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					//	desapilo y pongo donde salto con la segunda cond - voy al final
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux=desapilar(&pilaIf);
	itoa(aux1,bufferaux1,10);						// desapilo y pongo donde voy con el JMP
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux=desapilar(&pilaIf);
	itoa(aux+2,bufferaux1,10);							// desapilo y pongo donde voy si la primer condicion es falsa
	strcpy(vector_tercetos[aux].te1,bufferaux1);
}

| OPERADOR_IF OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO OPERADOR_THEN bloque_programa {
	crear_terceto("JMP","_","_");			
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// paso a char[] el valor indice
	strcpy(vector_tercetos[aux].te1,bufferaux1);		// asigno el lugar donde salto
	apilar(&pilaIf,indice_terceto-1);
}	OPERADOR_ELSE bloque_programa OPERADOR_ENDIF 
{
	printf("bloque_if -> IF condicion programa ELSE programa ENDIF\n\n");
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// paso a char[] el valor indice
	strcpy(vector_tercetos[aux].te1,bufferaux1);		// asigno el lugar donde salto
}

|	OPERADOR_IF OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux);} OPERADOR_AND comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO OPERADOR_THEN bloque_programa
{
	aux=crear_terceto("JMP","_","_");			// guardo el numero de terceto donde voy a poner el salto desde el fin del THEN al FINAL
	aux1=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// paso a char[] el valor indice
	strcpy(vector_tercetos[aux1].te1,bufferaux1);		// SALTO AL PRINCIPIO DEL ELSE
	aux1=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// paso a char[] el valor indice
	strcpy(vector_tercetos[aux1].te1,bufferaux1);		// SALTO AL PRINCIPIO DEL ELSE
	apilar(&pilaIf,aux);											// apilo el terceto que salta al final del THEN
}
OPERADOR_ELSE bloque_programa OPERADOR_ENDIF	
{
	printf("bloque_if -> IF CON ELSE\n\n");
	aux=desapilar(&pilaIf);
	itoa(indice_terceto,bufferaux1,10);					// paso a char[] el valor indice
	strcpy(vector_tercetos[aux].te1,bufferaux1);		// SALTO AL FINAL DEL ELSE

}			

|	OPERADOR_IF OPERADOR_IF PARENTESIS_ABIERTO comparacion {apilar(&pilaIf,aux); apilar(&pilaIf,crear_terceto("JMP","_","_"));} OPERADOR_OR comparacion {apilar(&pilaIf,aux);} PARENTESIS_CERRADO {aux1=indice_terceto;} 
OPERADOR_THEN bloque_programa {apilar(&pilaIf,crear_terceto("JMP","_","_"));} OPERADOR_ELSE bloque_programa OPERADOR_ENDIF
{
	aux=desapilar(&pilaIf);								// cargo el salto al final cuando termina el THEN
	itoa(indice_terceto,bufferaux1,10);
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux2 = aux+1;										// cargo la posicion donde empieza el ELSE
	aux=desapilar(&pilaIf);
	itoa(aux2,bufferaux1,10);					//	desapilo y pongo donde salto con la segunda cond - voy al ELSE
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux=desapilar(&pilaIf);
	itoa(aux1,bufferaux1,10);						// desapilo y pongo donde voy con el JMP - en el aux1 tengo la posicion donde empieza el THEN
	strcpy(vector_tercetos[aux].te1,bufferaux1);
	aux=desapilar(&pilaIf);
	itoa(aux+2,bufferaux1,10);							// desapilo y pongo donde voy si la primer condicion es falsa
	strcpy(vector_tercetos[aux].te1,bufferaux1);
}


condicion:   PARENTESIS_ABIERTO comparacion PARENTESIS_CERRADO 
{
	aux=desapilar(&pilaRepeat);
	itoa(aux,bufferaux1,10);							// desapilo y pongo donde voy si la primer condicion es falsa
	strcpy(vector_tercetos[indice_terceto-1].te1,bufferaux1);
	
}
|	PARENTESIS_ABIERTO comparacion {apilar(&pilaRepeat,aux);} OPERADOR_AND comparacion {apilar(&pilaRepeat,aux);} PARENTESIS_CERRADO 
{
	aux=crear_terceto("JMP","_","_");
	aux2=desapilar(&pilaRepeat);
	itoa(indice_terceto,bufferaux1,10);		
	strcpy(vector_tercetos[aux2].te1,bufferaux1);
	aux2=desapilar(&pilaRepeat);
	itoa(indice_terceto,bufferaux1,10);		
	strcpy(vector_tercetos[aux2].te1,bufferaux1);
	aux2=desapilar(&pilaRepeat);
	itoa(aux2,bufferaux1,10);		
	strcpy(vector_tercetos[aux].te1,bufferaux1);

}

| PARENTESIS_ABIERTO comparacion {
	apilar(&pilaRepeat,aux);
	char posInicial[10];
	itoa(auxRepeat, posInicial,10);
	aux=crear_terceto("JMP",posInicial,"_");
}OPERADOR_OR comparacion {apilar(&pilaRepeat,aux);} PARENTESIS_CERRADO {
	
	char posInicial[10];
	itoa(auxRepeat, posInicial,10);
	aux=crear_terceto("JMP",posInicial,"_");
	
	aux2=desapilar(&pilaRepeat);
	printf("aux2: %d\n",aux);
	itoa(indice_terceto,bufferaux1,10);		
	strcpy(vector_tercetos[aux2].te1,bufferaux1);
	aux2=desapilar(&pilaRepeat);
	itoa(aux2+2,bufferaux1,10);		
	strcpy(vector_tercetos[aux2].te1,bufferaux1);

}
| PARENTESIS_ABIERTO OPERADOR_NOT PARENTESIS_ABIERTO comparacion PARENTESIS_CERRADO PARENTESIS_CERRADO {
	
	invertir_salto(vector_tercetos, aux);
	aux=desapilar(&pilaRepeat);
	itoa(aux,bufferaux1,10);							// desapilo y pongo donde voy si la primer condicion es falsa
	strcpy(vector_tercetos[indice_terceto-1].te1,bufferaux1);
}


comparacion : expresion OPERADOR_MAYOR_A expresion	
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JNA","_","_");							// pongo en aux el numero de terceto donde usaria el salto
}
| expresion OPERADOR_MENOR_A expresion
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JAE","_","_");		
}

| expresion OPERADOR_MAYOR_O_IGUAL_A expresion
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JNAE","_","_");		
}

| expresion OPERADOR_MENOR_O_IGUAL_A expresion
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JA","_","_");		
}

| expresion OPERADOR_IGUAL_A expresion
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JNE","_","_");		
}
| expresion OPERADOR_DISTINTO_A expresion
{
	ladoDerecho = desapilar(&pilaExpresion);
	ladoIzquierdo = desapilar(&pilaExpresion);
	itoa(ladoIzquierdo,bufferaux1,10);
	itoa(ladoDerecho,bufferaux2,10);
	crear_terceto("CMP",bufferaux1,bufferaux2);
	aux = crear_terceto("JE","_","_");		
}

filtro: FILTER {
	condicion_filter_doble=0; 
	condicion_filter_or=0; 
	cont_filter=0;
	agregarConstante("0", CteInt);
	seq_variable_filter++;
} 
PARENTESIS_ABIERTO condicion_filter COMA  CORCHETE_ABIERTO {
	
	
}lista_ids_filter CORCHETE_CERRADO PARENTESIS_CERRADO 
{
	char nombreFilter[100];
	strcpy(nombreFilter,VAR_FILTER);
	char seqAux[10];
	itoa(seq_variable_filter,seqAux,10);
	strcat(nombreFilter, seqAux);
	char tipo[10];
	int auxOpe = desapilar(&pilaOperacion);
	agregar_variable_filter_a_tabla(nombreFilter, tipoCondicion1);
	crear_terceto("=",nombreFilter,"0"); //valor por default si nunguna cumple la condicion sale por este
	int i=0;
	int filter_i;
	itoa(indice_terceto,bufferaux1,10);
	for(i=0; i< cont_filter; i++){
		filter_i=desapilar(&pilaFilter);
		strcpy(vector_tercetos[filter_i].te1,bufferaux1);
	}
	strcpy(vector_operacion[cantOperaciones].id,nombreFilter);
	strcpy(vector_operacion[cantOperaciones].tipo,tipoCondicion1);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	printf("FILTER OK\n\n");
}

condicion_filter: comparacion_filter{ 
	vector_filter[0] = vector_condicion_filter[0];
	vector_filter[1] = vector_condicion_filter[1];
	int aux = desapilar(&pilaOperacion);
	strcpy(tipoCondicion1, vector_operacion[aux].tipo);
	
} OPERADOR_AND comparacion_filter { 
	vector_filter[2] = vector_condicion_filter[0];
	vector_filter[3] = vector_condicion_filter[1]; 
	int aux = desapilar(&pilaOperacion);
	strcpy(tipoCondicion2, vector_operacion[aux].tipo);
	if(strcmp(tipoCondicion1, tipoCondicion2)==0){		
		condicion_filter_doble=1;
	}else{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la comparacion filter\n");
		mostrarError(mensajeDeError);
	}
}

| comparacion_filter { 
	vector_filter[0] = vector_condicion_filter[0];
	invertir_salto(vector_condicion_filter,1);
	int aux = desapilar(&pilaOperacion);
	strcpy(tipoCondicion1, vector_operacion[aux].tipo);
	vector_filter[1] = vector_condicion_filter[1];
	
} OPERADOR_OR comparacion_filter { 
	printf("Aqui\n");
	vector_filter[2] = vector_condicion_filter[0];
	vector_filter[3] = vector_condicion_filter[1];
	int aux = desapilar(&pilaOperacion);
	
	strcpy(tipoCondicion2, vector_operacion[aux].tipo);
	if(strcmp(tipoCondicion1, tipoCondicion2)==0){		
		condicion_filter_doble=1;
		condicion_filter_or=1;
	}
	else{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la comparacion filter\n");
		mostrarError(mensajeDeError);
	}
}

| OPERADOR_NOT PARENTESIS_ABIERTO comparacion_filter PARENTESIS_CERRADO{
	int aux = desapilar(&pilaOperacion);
	strcpy(tipoCondicion1, vector_operacion[aux].tipo);
	vector_filter[0] = vector_condicion_filter[0];
	invertir_salto(vector_condicion_filter, 1);
	vector_filter[1] = vector_condicion_filter[1];

}
| comparacion_filter {
	int aux = desapilar(&pilaOperacion);
	strcpy(tipoCondicion1, vector_operacion[aux].tipo);
	vector_filter[0] = vector_condicion_filter[0];
	vector_filter[1] = vector_condicion_filter[1];
}

comparacion_filter : 
GUION_BAJO OPERADOR_MAYOR_A expresion_numerica {
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JNA");
	vector_condicion_filter[1]= aux;
}	
| GUION_BAJO OPERADOR_MENOR_A expresion_numerica{
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JAE");
	vector_condicion_filter[1]= aux;
}	
| GUION_BAJO OPERADOR_MAYOR_O_IGUAL_A expresion_numerica{
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JNAE");
	vector_condicion_filter[1]= aux;
}	
| GUION_BAJO OPERADOR_MENOR_O_IGUAL_A expresion_numerica{
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JA");
	vector_condicion_filter[1]= aux;
}	
| GUION_BAJO OPERADOR_IGUAL_A expresion_numerica{
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JNE");
	vector_condicion_filter[1]= aux;
}	
| GUION_BAJO OPERADOR_DISTINTO_A expresion_numerica{
	ladoDerecho = desapilar(&pilaExpresion);
	itoa(ladoDerecho,bufferaux1,10);
	terceto aux;
	strcpy(aux.ope,"CMP");
	strcpy(aux.te2,bufferaux1);
	vector_condicion_filter[0]= aux;
	strcpy(aux.ope,"JE");
	vector_condicion_filter[1]= aux;
}	


asignacion_multiple: CORCHETE_ABIERTO lista_ids_asignMultiple CORCHETE_CERRADO OPERADOR_ASIGNACION CORCHETE_ABIERTO lista_expresiones_asignMultiple CORCHETE_CERRADO 
{
	printf("ASIGNACION MULTIPLE OK\n\n");
	indice_asign_multiple=0;
	indice_expresiones_asign_multiple = 0;
}

lista_expresiones : lista_expresiones COMA expresion_numerica
| expresion_numerica


expresion_numerica: 
expresion_numerica OPERACION_SUMA termino_numerico	{
	printf("expresion_numerica -> exp + term OK \n\n");
	aux=desapilar(&pilaOperacion);
	aux1=desapilar(&pilaOperacion);
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaExpresion),bufferaux1,10);
		itoa(desapilar(&pilaTermino),bufferaux2,10);
		E_ind = crear_terceto("+",bufferaux1,bufferaux2 );
		apilar(&pilaExpresion,E_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la suma\n");
		mostrarError(mensajeDeError);
	}
}	 
| expresion_numerica OPERACION_RESTA termino_numerico 	{
	printf("expresion_numerica -> exp - term OK \n\n");
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaExpresion),bufferaux1,10);
		itoa(desapilar(&pilaTermino),bufferaux2,10);
		E_ind = crear_terceto("-",bufferaux1,bufferaux2 );
		apilar(&pilaExpresion,E_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la resta\n");
		mostrarError(mensajeDeError);
	}
	
}
| termino_numerico	{
	printf("expresion_numerica -> term OK \n\n");
	E_ind = desapilar(&pilaTermino);
	apilar(&pilaExpresion,E_ind);
}

termino_numerico: 
termino_numerico OPERACION_MULTIPLICACION factor_numerico {
	printf("term -> term * factor_numerico OK \n\n");
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaTermino),bufferaux1,10);
		itoa(desapilar(&pilaFactor),bufferaux2,10);
		T_ind=crear_terceto("*",bufferaux1,bufferaux2);
		apilar(&pilaTermino,T_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la multiplicacion\n");
		mostrarError(mensajeDeError);
	}
	
} 
| termino_numerico OPERACION_DIVISION factor_numerico 	{
	printf("term -> term / factor_numerico OK \n\n");
	if(strcmp(vector_operacion[aux].tipo,vector_operacion[aux1].tipo)==0)
	{
		itoa(desapilar(&pilaTermino),bufferaux1,10);
		itoa(desapilar(&pilaFactor),bufferaux2,10);
		T_ind=crear_terceto("/",bufferaux1,bufferaux2);
		apilar(&pilaTermino,T_ind);
		apilar(&pilaOperacion,aux);
	}
	else
	{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de variables en la division\n");
		mostrarError(mensajeDeError);
	}
	
}
| factor_numerico{
	printf("term -> factor_numerico OK \n\n");
	T_ind = desapilar(&pilaFactor);
	apilar(&pilaTermino,T_ind);
}

factor_numerico: ID {
	printf("factor numerico -> ID OK\n\n");
	strcpy(vector_operacion[cantOperaciones].id,yylval.str_val);
	strcpy(vector_operacion[cantOperaciones].tipo,validaTipo(yylval.str_val));
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(yylval.str_val,"_","_");
	apilar(&pilaFactor,F_ind);
}
| ENTERO {	
	printf("factor numerico -> Cte_entera OK\n\n");
	strcpy(constanteAux,"_");
	strcat(constanteAux,yylval.str_val);
	strcpy(constanteAux + strlen(constanteAux), "\0");
	strcpy(vector_operacion[cantOperaciones].id,constanteAux);
	strcpy(vector_operacion[cantOperaciones].tipo,"ENTERO");
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(constanteAux,"_","_");
	apilar(&pilaFactor,F_ind);
}
| REAL {
	printf("factor numerico -> Cte_Real OK\n\n");
	agregarConstante(yylval.str_val,CteReal);
	strcpy(constanteAux,"_");
	strcat(constanteAux,yylval.str_val);
	strcpy(constanteAux + strlen(constanteAux), "\0");
	strcpy(vector_operacion[cantOperaciones].id,constanteAux);
	strcpy(vector_operacion[cantOperaciones].tipo,"REAL");
	printf("ID %s\n",vector_operacion[cantOperaciones].id);
	printf("TIPO %s\n",vector_operacion[cantOperaciones].tipo);
	apilar(&pilaOperacion,cantOperaciones);
	cantOperaciones++;
	F_ind = crear_terceto(constanteAux,"_","_");
	apilar(&pilaFactor,F_ind);
}	
| PARENTESIS_ABIERTO expresion_numerica PARENTESIS_CERRADO {
	printf("factor numerico -> (expresion numerica) OK\n\n");
	F_ind = desapilar(&pilaExpresion);
	apilar(&pilaFactor,F_ind);
}

lista_ids_filter: 
lista_ids_filter COMA ID {
	printf("%s\n", yylval.str_val);
	guardarEnVectorTablaSimbolos(2,yylval.str_val);
	printf("lista_ids -> lista_ids , ID OK\n\n");
	crear_tercetos_filter();
}
| ID {
	printf("%s\n", yylval.str_val);
	guardarEnVectorTablaSimbolos(2,yylval.str_val);
	printf("lista_ids -> ID OK\n\n");
	crear_tercetos_filter();
}

// ---------------------- Asignacion Multiple -------------------------//

lista_ids_asignMultiple: 
lista_ids_asignMultiple COMA ID {

	printf("%s\n", yylval.str_val);
	printf("lista_ids_asignMultiple -> lista_ids_asignMultiple , ID OK\n\n");
	if(strcmp(yylval.str_val,validaTipo(yylval.str_val))==0){
		//No existe en tabla de simbolo
		printf("No existe en tabla de simbolo \n\n");
	}else{
		
		strcpy(vector_asig_multiple[indice_asign_multiple].nombre,yylval.str_val);
		strcpy(vector_asig_multiple[indice_asign_multiple].tipo,validaTipo(yylval.str_val));
		indice_asign_multiple++;
		
	}
	
}
| ID {
	printf("%s\n", yylval.str_val);
	printf("lista_ids_asignMultiple -> ID OK\n\n");
	
	if(strcmp(yylval.str_val,validaTipo(yylval.str_val))==0){
		//No existe en tabla de simbolo
		printf("No existe en tabla de simbolo \n\n");
	}else{
		
		strcpy(vector_asig_multiple[indice_asign_multiple].nombre,yylval.str_val);
		strcpy(vector_asig_multiple[indice_asign_multiple].tipo,validaTipo(yylval.str_val));
		indice_asign_multiple++;
		
	}	
}


lista_expresiones_asignMultiple : lista_expresiones_asignMultiple COMA expresion_asignMultiple
| expresion_asignMultiple


expresion_asignMultiple: 
expresion_asignMultiple OPERACION_SUMA termino_asignMultiple	{
	printf("expresion_asignMultiple -> exp + term OK \n\n");
	
} 
| expresion_asignMultiple OPERACION_RESTA termino_asignMultiple 	{
	printf("expresion_asignMultiple -> exp - term OK \n\n");
	
}
| termino_asignMultiple	{
	printf("expresion_asignMultiple -> term OK \n\n");

}

termino_asignMultiple: 
termino_asignMultiple OPERACION_MULTIPLICACION factor_asignMultiple {
	printf("term -> term * factor_asignMultiple OK \n\n");
	
} 
| termino_asignMultiple OPERACION_DIVISION factor_asignMultiple 	{
	printf("term -> term / factor_asignMultiple OK \n\n");
	
}
| factor_asignMultiple{
	printf("term -> factor_asignMultiple OK \n\n");
	
}

factor_asignMultiple: ID 
| ENTERO {	
	printf("factor_asignMultiple -> Cte_entera OK\n\n");
	
	if(indice_expresiones_asign_multiple < indice_asign_multiple)
	{
		
		if(strcmp(vector_asig_multiple[indice_expresiones_asign_multiple].tipo,"ENTERO") == 0)
		{	
			agregarConstante(yylval.str_val,CteInt);
			strcpy(constanteAux,"_");
			strcat(constanteAux,yylval.str_val);
			strcpy(constanteAux + strlen(constanteAux), "\0");
			crear_terceto("=",vector_asig_multiple[indice_expresiones_asign_multiple].nombre,constanteAux);
			indice_expresiones_asign_multiple++;
		}else{
			
			sprintf(mensajeDeError, "La Variable: %s No es de tipo entero.\n", vector_asig_multiple[indice_expresiones_asign_multiple].nombre);
			mostrarError(mensajeDeError);
			
		}
		
	}
	
}
| REAL {
	printf("factor_asignMultiple -> Cte_Real OK\n\n");
	if(indice_expresiones_asign_multiple < indice_asign_multiple)
	{
		
		if(strcmp(vector_asig_multiple[indice_expresiones_asign_multiple].tipo,"REAL") == 0)
		{	
			agregarConstante(yylval.str_val,CteReal);
			strcpy(constanteAux,"_");
			strcat(constanteAux,yylval.str_val);
			strcpy(constanteAux + strlen(constanteAux), "\0");
			crear_terceto("=",vector_asig_multiple[indice_expresiones_asign_multiple].nombre,constanteAux);
			indice_expresiones_asign_multiple++;
		}else{
			
			sprintf(mensajeDeError, "La Variable: %s No es de tipo real.\n", vector_asig_multiple[indice_expresiones_asign_multiple].nombre);
			mostrarError(mensajeDeError);
		}
		
	}
}	
| PARENTESIS_ABIERTO expresion_asignMultiple PARENTESIS_CERRADO {
	printf("factor_asignMultiple -> (expresion_asignMultiple) OK\n\n");
}



%%

int main(int argc,char *argv[]){

	if ((yyin = fopen(argv[1], "rt")) == NULL){
		printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
	}else {

		// inicializo las pilas
		pilaExpresion = crearPila();
		pilaTermino	= crearPila();
		pilaTercetoActual = crearPila();
		pilaFactor = crearPila();
		pilaIf = crearPila();
		pilaRepeat = crearPila();
		pilaOperacion = crearPila();
		pilaFilter = crearPila();

		yyparse();

		guardarTabla();
		escribe_arch_tercetos();
	}
	fclose(yyin);
	return 0;
}

void mostrarError(char *mensaje) {
	printf("%s\n", mensaje);
	yyerror();
}

int yyerror(void){
	printf("ERROR EN COMPILACION.\n");
	system ("Pause");
	exit (1);
}

void guardarEnVectorTablaSimbolos(int opc, char * cad){
	if(finBloqueDeclaraciones==0){
		if(opc==1){
			strcpy(tablaDeSimbolos[pos_td].tipo,cad);
			cant_tipo_dato++;
			pos_td++;
		}else{
			strcpy(tablaDeSimbolos[pos_cv].nombre,cad);
			pos_cv++;
			cant_variables++;
		}
	}
}

void guardarTipo(char * tipoVariable) {
	strcpy(tipoVariableActual, tipoVariable);
}

void acomodarPunterosTS(){
	int indice=0;
	if(cant_tipo_dato!=cant_variables){
		if(pos_td<pos_cv){	
			min=pos_td;
			cant_elementos=min;
			pos_td=pos_cv=min;
			diferencia=(cant_variables-cant_tipo_dato);
			indice=min;
			while(diferencia>0){
				strcpy(tablaDeSimbolos[indice].tipo, "");
				strcpy(tablaDeSimbolos[indice].nombre, "");
				diferencia--;
				indice++;
			}
		}else{
			min=pos_cv;
			cant_elementos=min;
			pos_td=pos_cv=min;
			diferencia=(cant_tipo_dato-cant_variables);
			indice=min;
			while(diferencia>0){
				strcpy(tablaDeSimbolos[indice].tipo, "");
				strcpy(tablaDeSimbolos[indice].nombre, "");
				diferencia--;
				indice++;
			}
		}
	}else{
		cant_elementos=pos_cv;
		cant_tipo_dato=cant_variables=0;
	}
}

void quitarDuplicados(){
	for(i=0;i<cant_elementos;i++){
		if(strcmp(tablaDeSimbolos[i].nombre,"@")!=0){
			cantidadTokens++;
			for(j=i+1;j<cant_elementos;j++){
				if(strcmp(tablaDeSimbolos[i].tipo,tablaDeSimbolos[j].tipo)==0 && strcmp(tablaDeSimbolos[i].nombre,tablaDeSimbolos[j].nombre)==0){		// si los dos son iguales
					strcpy(tablaDeSimbolos[j].tipo, "@");
					strcpy(tablaDeSimbolos[j].nombre, "@");				// doy de baja a todos los proximos que son iguales
				}
			}
		}else{
			j=i+1;
			while(j<cant_elementos && strcmp(tablaDeSimbolos[j].tipo,"@")==0)
			j++;
			if(j<cant_elementos){
				strcpy(tablaDeSimbolos[i].nombre,tablaDeSimbolos[j].nombre);
				strcpy(tablaDeSimbolos[i].tipo,tablaDeSimbolos[j].tipo);
				i--;
			}else{
				i=cant_elementos;
			}

		}
	}
}

/* Guarda la tabla generada en un txt */
void guardarTabla(){

	// Verifico si se cargo algo en la tabla
	if(cantidadTokens == -1)
	yyerror();

	FILE* arch = fopen("ts.txt", "w+");
	if(!arch){
		printf("No pude crear el archivo ts.txt\n");
		return;
	}

	fprintf(arch,"%-30s%-20s%-30s%-5s\n","NOMBRE","TIPO","VALOR", "LONGITUD");
	fprintf(arch, "======================================================================================================\n");
	//lo mismo que guarda en archivo lo imprimo en pantalla
	//printf("%-30s%-20s%-30s%-5s\n","NOMBRE","TIPO","VALOR", "LONGITUD");
	//printf("======================================================================================================\n");
	// Recorro la tabla
	int i = 0;
	while (i < cant_ctes) {

		fprintf(arch, "%-30s%-20s%-30s%-5d\n", &(tablaDeSimbolos[i].nombre), &(tablaDeSimbolos[i].tipo) , &(tablaDeSimbolos[i].valor), tablaDeSimbolos[i].longitud);
		//printf( "%-30s%-20s%-30s%-5d\n", &(tablaDeSimbolos[i].nombre), &(tablaDeSimbolos[i].tipo) , &(tablaDeSimbolos[i].valor), tablaDeSimbolos[i].longitud);
		i++;
	}

	fclose(arch);
}


/* Agregar una constante a la tabla de simbolos */

void agregarConstante(char* nombre,char* tipo) {
	printf("Agregar cte %s: %s .\n\n",nombre, tipo);

	// Formateo la cadena
	int length = strlen(nombre);

	char nombre_nuevo[length];

	strcpy(nombre_nuevo, "_");
	strcat(nombre_nuevo, nombre);

	strcpy(nombre_nuevo + strlen(nombre_nuevo), "\0");

	// Verificamos si ya esta cargada
	if (buscarCte(nombre_nuevo, tipo) == 0) {

		// Agrego nombre a la tabla
		strcpy(tablaDeSimbolos[cant_ctes].nombre, nombre_nuevo);

		// Agrego el tipo (Se utiliza para imprimir tabla)
		strcpy(tablaDeSimbolos[cant_ctes].tipo, tipo);	

		// Agrego valor
		strcpy(tablaDeSimbolos[cant_ctes].valor, nombre_nuevo+1);		// Omito el _

		// Agrego la longitud
		if(strcmp(tipo, CteString)==0){
			tablaDeSimbolos[cant_ctes].longitud = length;
		}
		cant_ctes++;
		printf("AGREGO A LA TABLA: %s\n", nombre_nuevo);
	}
}

int buscarCte(char* nombre, char* tipo){			//return 1 = ya esta, return 0 = no esta , cad1 es nombre a buscar cad2 es el tipo 
	int i = cantidadTokens;
	for( i ; i < cant_ctes ; i++){
		if(strcmp(tablaDeSimbolos[i].nombre, nombre)==0 
				&& strcmp(tablaDeSimbolos[i].tipo,tipo)==0){
			printf("%s DUPLICADA\n\n", tipo);
			return 1;
		}
	}
	return 0;
}

void validarVariableDeclarada(char* nombre){
	int i;
	for(i=0 ; i< cantidadTokens; i++){
		if(strcmp(tablaDeSimbolos[i].nombre,nombre)==0)
		return;

	}
	sprintf(mensajeDeError, "La Variable: %s - No esta declarada.\n", nombre);
	mostrarError(mensajeDeError);	
}

/* Funciones tercetos */ 

// escribe los tercetos en un archivo
void escribe_arch_tercetos()
{
	FILE* arch;
	int i;
	terceto aux;
	arch = fopen("intermedia.txt", "w+");

	for(i = 0; i < indice_terceto; i++)
	{
		aux =  vector_tercetos[i];
		if((strcmp(aux.te1,"_")==0 && strcmp(aux.te2,"_")==0) || (strcmp(aux.ope,"READ")==0 || strcmp(aux.ope,"PRINT")==0))					// si el primer y segundo operando es un guion bajo , grabo como esta
		fprintf(arch, "[%d] (%s,%s,%s)\n", aux.nroTerceto, aux.ope,aux.te1, aux.te2 );
		else
		{	if(strcmp(aux.te2,"_")==0)					// si el segundo operando es un guion bajo, es un terceto JMP
			fprintf(arch, "[%d] (%s,[%s],%s)\n", aux.nroTerceto, aux.ope,aux.te1, aux.te2 );
			else
			{
				if(*aux.te1>='a' && *aux.te1<='z')			// si el primer operando son una letra, puede que sea una asignacion de una cadena, grabo como esta
				fprintf(arch, "[%d] (%s,%s,[%s])\n", aux.nroTerceto, aux.ope,aux.te1, aux.te2 );
				else
				fprintf(arch, "[%d] (%s,[%s],[%s])\n", aux.nroTerceto, aux.ope,aux.te1, aux.te2 );				// sino, los dos operandos son otros tercetos, pongo corchetes a los dos
			}

		}

	}
	fclose(arch);
}

//Crea el terceto con los indices de los tercetos. Si no existen tiene -1
int  crear_terceto(char* p_ope, char* p_te1, char* p_te2)
{
	terceto res;
	res.nroTerceto = indice_terceto;
	strcpy(res.ope, p_ope);
	strcpy(res.te1, p_te1);
	strcpy(res.te2, p_te2);
	vector_tercetos[indice_terceto] = res;
	indice_terceto++;
	return indice_terceto-1;
}

char* validaTipo(char* id)
{
	int i;
	for(i=0;i<cantidadTokens;i++)
	{		
		if(strcmp(id,tablaDeSimbolos[i].nombre)==0)
		{		
			return tablaDeSimbolos[i].tipo;
		}
	}
	
	return id;
}
void invertir_salto(terceto* vector, int indice){
	
	printf("invertir el salto: %s\n", vector[indice].ope);
	if(strcmp(vector[indice].ope,"JE")==0){
		strcpy(vector[indice].ope,"JNE");
		return;
	}
	if(strcmp(vector[indice].ope,"JNE")==0){
		strcpy(vector[indice].ope,"JE");
		return;
	}
	if(strcmp(vector[indice].ope,"JNAE")==0){
		strcpy(vector[indice].ope,"JAE");
		return;
	}
	if(strcmp(vector[indice].ope,"JAE")==0){
		strcpy(vector[indice].ope,"JNAE");
		return;
	}
	if(strcmp(vector[indice].ope,"JA")==0){
		strcpy(vector[indice].ope,"JNA");
		return;
	}
	if(strcmp(vector[indice].ope,"JNA")==0){
		strcpy(vector[indice].ope,"JA");
		return;
	}
}
void crear_tercetos_filter(){
	int i = 0;
	char nombreFilter[100];
	strcpy(nombreFilter,VAR_FILTER);
	char seqAux[10];
	itoa(seq_variable_filter,seqAux,10);
	strcat(nombreFilter, seqAux);
	int lenght = (int) sizeof(vector_filter);
	if(strcmp(tipoCondicion1, validaTipo(yylval.str_val))==0){
		for(i=0; i<lenght; i++){
			terceto aux = vector_filter[i];
			if(i==0 || (condicion_filter_doble ==1 && i==2)){
				crear_terceto(aux.ope,yylval.str_val,aux.te2);
			}
			if(i==1){
				if(condicion_filter_doble==1 && condicion_filter_or ==0){
					itoa(indice_terceto+5, bufferaux1,10);
				}
				else{
					itoa(indice_terceto+3, bufferaux1,10);
				}
				crear_terceto(aux.ope,bufferaux1,"_");
			}
			if(condicion_filter_doble==1 && i==3){
				itoa(indice_terceto+3, bufferaux1,10);
				crear_terceto(aux.ope,bufferaux1,"_");
			}
			
		}
		crear_terceto("=",nombreFilter,yylval.str_val);
		cont_filter++;
		apilar(&pilaFilter,crear_terceto("JMP","","_"));
	}else{
		sprintf(mensajeDeError, "Incompatibilidad de tipos de la variable:%s con la comparacion del filter\n",yylval.str_val );
		mostrarError(mensajeDeError);
		
	}
}

void agregar_variable_filter_a_tabla(char* nombre, char* tipo){
	if (buscarCte(nombre, tipo) == 0) {

		// Agrego nombre a la tabla
		strcpy(tablaDeSimbolos[cant_ctes].nombre, nombre);

		// Agrego el tipo (Se utiliza para imprimir tabla)
		strcpy(tablaDeSimbolos[cant_ctes].tipo, tipo);
		cant_ctes++;
	}
}

