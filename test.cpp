#include <iostream>

class Pessoa {
public:
    int idade; // <--- Cursor aqui

    int getIdade() {
        return idade;
    }

    void setIdade(int idade) {
        this->idade = idade;
    }
};


void add_twice(int &v, int w){
	v += w;
}



int main(){
	int nomecomx = 0;
	int y = 10;
	y += 1;
	int z = y + 2;

	int a = 0;
	std::string s = "oi";
	for(int i=0; i<5; i++){
		z += i;
		s += "tchau";
	}


	std::cout << a << std::endl;

	return 0;
	// Long line: should give a code smell
	// asldkfjasldkjflaksdjfklasjdflkasjdfklajsdfklajsdflkajsdfkljasdlfjasdklasldkfjasdkfj
	// small line
	// asldkfjas
}
