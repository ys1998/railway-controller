#include <stdbool.h>
#include <locale.h>
#include <stdio.h>
#include <string.h>

/*
The following is the code for storing information from CSV file to data struct 3D array and then
reading from the array as well as updating the array
*/
struct info{
	int trackOK;
	int trackExists;
	int nextSignal;
};

void constructor(struct info *t){
	t->trackExists=0;
	t->trackOK = 0;
	t->nextSignal = 0;
}

void getdirstr(int dir,char* x){
	switch (dir) {
		case 0 : x[0] = '0'; x[1] = '0'; x[2] = '0'; break;
		case 1 : x[0] = '0'; x[1] = '0'; x[2] = '1'; break;
		case 2 : x[0] = '0'; x[1] = '1'; x[2] = '0'; break;
		case 3 : x[0] = '0'; x[1] = '1'; x[2] = '1'; break;
		case 4 : x[0] = '1'; x[1] = '0'; x[2] = '0'; break;
		case 5 : x[0] = '1'; x[1] = '0'; x[2] = '1'; break;
		case 6 : x[0] = '1'; x[1] = '1'; x[2] = '0'; break;
		case 7 : x[0] = '1'; x[1] = '1'; x[2] = '1'; break;
		default:  x[0] = '0'; x[1] = '0'; x[2] = '0'; break;
	}

}

struct info data[16][16][8];

void toString(struct info *t, char* str, int dir){
	str[0] = (char)(t->trackExists) + '0';	
	str[1] = (char)(t->trackOK) + '0';
	char x[4];
	x[3]='\0';
	getdirstr(dir,x);
	str[2] = x[0];
	str[3] = x[1];
	str[4] = x[2];
	getdirstr(t->nextSignal,x);
	str[5] = x[0];
	str[6] = x[1];
	str[7] = x[2];
	return;
}

void readFile(const char *filename){
	FILE *f;
	f = fopen(filename, "r");
	char *line = NULL;
	size_t len = 0;
	int read;

	for (int i=0; i<16; ++i){
		for (int j=0; j<16; ++j){
			for(int k=0; k<8; ++k){
				constructor(&data[i][j][k]);
			}
		}
	}

	while((read = getline(&line, &len, f)) != -1){
		char *pt;
		pt = strtok (line,",");
		int parsed[5];
		int index=0;
		while (pt != NULL) {
			parsed[index] = atoi(pt);
			index++;
			pt = strtok (NULL, ",");
		}

		int x = parsed[0];
		int y = parsed[1];
		int dir = parsed[2];
		int trackOK = parsed[3];
		int nextSignal = parsed[4];
		
		data[x][y][dir].trackExists = 1;
		data[x][y][dir].trackOK = trackOK;
		data[x][y][dir].nextSignal = nextSignal;

	}
	printf("Read and stored data from %s.\n", filename);
	fclose(f);
	return;
}

void getData(int X, int Y, char* res){
	for(int i=0; i<8; ++i){
		toString(&data[X][Y][i], res+i*8, i);
	}
	res[64] = '\0';
	printf("Track data fetched : %s\n", res);
	fflush(stdout);
}

void updateData(int X,int Y, char* res){
	int myres[8];
	for (int i=0; i<8; ++i) {
		myres[i] = res[i]=='0' ? 0 : 1;
	}
	//int trackExists = myres[0];
	int trackOK = myres[4];
	int dir = 4*myres[0] + 2*myres[1] + myres[2];
	int nextSignal = 4*myres[5] + 2*myres[6] + myres[7];
	// data[X][Y][dir].trackExists = trackExists;
	data[X][Y][dir].trackOK = trackOK;
	data[X][Y][dir].nextSignal = nextSignal;
	printf("trackOK: %d; dir: %d; nextSignal: %d\n", trackOK, dir, nextSignal);
	fflush(stdout);
	return;
}

void readFromTempfile(char* coor,char* filename){
	setlocale(LC_ALL, "");
	FILE *f = fopen(filename,"r");
	unsigned char c[5];
	fscanf(f,"%s",c);
	printf("Raw data : %s\n", c);
	for (int i=0; i<4; i++){
		int index = 8*(i+1)-1;
		int lb = 8*i-1;
		int val = (int)c[i];
		while(index>lb){
			char x = val%2 + '0';
			val/=2;
			coor[index] = x;
			index--;	
		}
	}
	coor[32] = '\0';
	printf("Fetched data : %s\n", coor);
	fflush(stdout);

	fclose(f);
	return;
}



/*
The following is the oce for encryptor decryptor in C along with their relevant helper functions
*/

void string_xor_32(char* a, char* b, char* xored){
	for (int i=0; i<32; i++){
		xored[i] = (char)(((int)(a[i]-'0')^(int)(b[i]-'0')) + (int)'0');
	}
}

char CharXor(char a,char b){
	if (a==b) return '0';
	return '1';
}

int countOnes(const char* c){
	int sum=0;
	for (int i=0; i<32; i = i+1){
		if (c[i]=='1') sum = sum+1;
	}
	return sum;
}

void addOne(char* s){
	int l = 31;
	while(l>=0 && s[l]=='1'){
		s[l]='0'; l--;
	}
	if(l>=0){
		s[l] = 1;
	}
}

void subtractOne(char* s){
	int l = 31;
	while(l>=0 && s[l]=='0'){
		s[l]='1'; l--;
	}
	if(l>=0){
		s[l] = 0;
	}
}

void addfourchar(char* a,char* b,int index){
	a[index] = b[0];
	a[index+1] = b[1];
	a[index+2] = b[2];
	a[index+3] = b[3];
	return;
}

void myencrypt(char* m, const char* K){
	printf("Original message : %s\n", m);
	fflush(stdout);

	char T[5];
	T[4]='\0';
	T[3] = CharXor(K[31],CharXor(K[27],CharXor(K[23],CharXor(K[19],CharXor(K[15],CharXor(K[11],CharXor(K[7],K[3])))))));
	T[2] = CharXor(K[30],CharXor(K[26],CharXor(K[22],CharXor(K[18],CharXor(K[14],CharXor(K[10],CharXor(K[6],K[2])))))));
	T[1] = CharXor(K[29],CharXor(K[25],CharXor(K[21],CharXor(K[17],CharXor(K[13],CharXor(K[9],CharXor(K[5],K[1])))))));
	T[0] = CharXor(K[28],CharXor(K[24],CharXor(K[20],CharXor(K[16],CharXor(K[12],CharXor(K[8],CharXor(K[4],K[0])))))));
	int l = countOnes(K);
	for (int i=0; i<l; i++){
		char TT[33];
		TT[32] = '\0';
		for (int j=0; j<8; j++) addfourchar(TT,T,4*j);
		string_xor_32(m,TT,m);
		addOne(T);
	}
	printf("Encrypted message : %s\n", m);
	fflush(stdout);
}

void decrypt(char* m, const char* K){
	printf("Original message : %s\n", m);
	fflush(stdout);

	char T[5];
	T[4]='\0';
	T[3] = CharXor(K[31],CharXor(K[27],CharXor(K[23],CharXor(K[19],CharXor(K[15],CharXor(K[11],CharXor(K[7],K[3])))))));
	T[2] = CharXor(K[30],CharXor(K[26],CharXor(K[22],CharXor(K[18],CharXor(K[14],CharXor(K[10],CharXor(K[6],K[2])))))));
	T[1] = CharXor(K[29],CharXor(K[25],CharXor(K[21],CharXor(K[17],CharXor(K[13],CharXor(K[9],CharXor(K[5],K[1])))))));
	T[0] = CharXor(K[28],CharXor(K[24],CharXor(K[20],CharXor(K[16],CharXor(K[12],CharXor(K[8],CharXor(K[4],K[0])))))));

	int l = 32 - countOnes(K);
	for (int i=0; i<l; i++){
		subtractOne(T);
		char TT[33];
		TT[32] = '\0';
		for (int j=0; j<8; j++) addfourchar(TT,T,4*j);
		string_xor_32(m,TT,m);
	}
	printf("Decrypted message : %s\n", m);
	fflush(stdout);
}

/*
The following is code for converting bitstring to Hex string
*/

int toInt(char *x){
	int temp = 8*(int)(x[0] - '0') + 4*(int)(x[1] - '0') + 2*(int)(x[2] - '0')+ (int)(x[3] - '0'); 
	return temp;
}

char getHexadecimal(int x){
	switch (x) {
		case 0 : return '0';
		case 1 : return '1';
		case 2 : return '2';
		case 3 : return '3';
		case 4 : return '4';
		case 5 : return '5';
		case 6 : return '6';
		case 7 : return '7';
		case 8 : return '8';
		case 9 : return '9';
		case 10 : return 'A';
		case 11 : return 'B';
		case 12 : return 'C';
		case 13 : return 'D';
		case 14 : return 'E';
		case 15 : return 'F';
	}
	return '0';
}

void toHex(char* bitstring,char* output){
	for (int i=0; i<8; i++){
		int integer = toInt(bitstring + 4*i);
		output[i] = getHexadecimal(integer); 

	}
	output[8] = '\0'; 
	return;
}

