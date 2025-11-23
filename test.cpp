#include <iostream>

class Pessoa {
private:
	int amigo;
	int ok;
public:
	int getAmigo() { return amigo; }
	void setAmigo(int amigo) { this->amigo = amigo; }

	int getOk() { return ok; }
	void setOk(int ok) { this->ok = ok; }



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
