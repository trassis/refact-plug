#include <iostream>
#include <vector>
#include <string>

class Veiculo {
private:
    std::string marca;
    std::string modelo;
    int ano;
    double preco;
    int capacidade;
    std::string cor;
    std::string tipoCombustivel;
    std::string placa;
    std::string dono;
    std::string seguradora;

public:
    std::string getMarca() { return marca; }
    void setMarca(const std::string &m) { marca = m; }

    std::string getModelo() { return modelo; }
    void setModelo(const std::string &m) { modelo = m; }

    int getAno() { return ano; }
    void setAno(int a) { ano = a; }

    double getPreco() { return preco; }
    void setPreco(double p) { preco = p; }

    int getCapacidade() { return capacidade; }
    void setCapacidade(int c) { capacidade = c; }

    std::string getCor() { return cor; }
    void setCor(const std::string &c) { cor = c; }

    std::string getTipoCombustivel() { return tipoCombustivel; }
    void setTipoCombustivel(const std::string &t) { tipoCombustivel = t; }

    std::string getPlaca() { return placa; }
    void setPlaca(const std::string &p) { placa = p; }

    std::string getDono() { return dono; }
    void setDono(const std::string &d) { dono = d; }

    std::string getSeguradora() { return seguradora; }
    void setSeguradora(const std::string &s) { seguradora = s; }

    void atualizarVeiculoCompleto(const std::string &m, const std::string &mod, int a, double p, int c, 
                                  const std::string &cor, const std::string &comb, const std::string &placa,
                                  const std::string &dono, const std::string &seg) 
    {
        marca = m;
        modelo = mod;
        ano = a;
        preco = p;
        capacidade = c;
        this->cor = cor;
        tipoCombustivel = comb;
        this->placa = placa;
        this->dono = dono;
        seguradora = seg;

        for (int i = 0; i < 10; i++) {
            preco += i * 100;
            capacidade += i;
        }

        if (ano > 2020) {
            preco *= 1.05;
        } else {
            preco *= 0.95;
        }

        std::string log = "Atualizando veiculo " + modelo + " de " + marca + " com todos os atributos detalhados incluindo cor, combustivel, placa, dono e seguradora.";
        std::cout << log << std::endl;
    }

        void gerarRelatorioExtenso() {
        std::cout << "Iniciando relatorio extenso do veiculo: " << modelo << " - " << marca << std::endl;
        std::cout << "Ano: " << ano << ", Preco: " << preco << ", Capacidade: " << capacidade << std::endl;
        std::cout << "Cor: " << cor << ", Combustivel: " << tipoCombustivel << std::endl;
        std::cout << "Placa: " << placa << ", Dono: " << dono << ", Seguradora: " << seguradora << std::endl;

        std::vector<std::string> comentarios = {
            "Veiculo em excelente estado",
            "Revisoes completas",
            "Garantia estendida",
            "Opcionais instalados",
            "Nenhum problema mecanico relatado",
            "Historico completo de manutencao",
            "Baixa quilometragem",
            "Documentacao regularizada",
            "Seguro ativo",
            "Inspecao veicular ok"
        };

        for (int i = 0; i < comentarios.size(); i++) {
            std::cout << i+1 << ". " << comentarios[i] << std::endl;
        }

        for (int i = 0; i < 5; i++) {
            std::cout << "Iteracao " << i+1 << " do relatorio detalhado" << std::endl;
            for (int j = 0; j < 4; j++) {
                std::cout << "  Sub-iteração " << j+1 << ": verificando dados..." << std::endl;
                for (int k = 0; k < 3; k++) {
                    double ajuste = (preco + i*1000 + j*100 + k*10) * 0.01;
                    std::cout << "    Ajuste calculado: " << ajuste << std::endl;
                }
            }
        }

        if (ano > 2020) {
            preco *= 1.05;
            std::cout << "Aplicando aumento de 5% para ano recente." << std::endl;
        } else if (ano < 2000) {
            preco *= 0.85;
            std::cout << "Aplicando desconto de 15% para veiculo antigo." << std::endl;
        } else {
            preco *= 0.95;
            std::cout << "Aplicando ajuste padrao de 5%." << std::endl;
        }

        std::vector<std::string> etapas = {
            "Inspecao de motor",
            "Inspecao de freios",
            "Inspecao de pneus",
            "Teste de emissao",
            "Verificacao de sistema eletronico"
        };

        for (auto &etapa : etapas) {
            std::cout << "Etapa: " << etapa << " - concluida." << std::endl;
        }

        std::cout << "Calculando preco estimado para venda..." << std::endl;
        double preco_estimado = preco;
        for (int m = 0; m < 10; m++) {
            preco_estimado += m * 500;
            std::cout << "Preco estimado apos ajuste " << m+1 << ": " << preco_estimado << std::endl;
        }

        std::cout << "Resumo final:" << std::endl;
        std::cout << "Modelo: " << modelo << ", Marca: " << marca << std::endl;
        std::cout << "Preco ajustado: " << preco_estimado << ", Ano: " << ano << std::endl;
        std::cout << "Fim do relatorio extenso do veiculo." << std::endl;
    }
};

void imprimirPreco(Veiculo &v) {
    std::cout << "Preco: " << v.getPreco() << std::endl;
}

void imprimirPreco(Veiculo &v) {
    std::cout << "Preco: " << v.getPreco() << std::endl;
}

int main() {
    Veiculo carro;

    carro.atualizarVeiculoCompleto("Toyota", "Corolla", 2022, 95000.50, 5, 
                                    "Preto", "Gasolina", "ABC-1234", "João", "SeguradoraX");

    std::string anuncio = "Veiculo em excelente estado, com todos os opcionais disponíveis, revisoes completas e garantia estendida";

    std::vector<int> numeros = {1,2,3,4,5,6,7,8,9,10};
    for (int n : numeros) {
        anuncio += " adicionando mais texto longo para forcar uma linha com mais de oitenta caracteres facilmente";
    }

    std::cout << anuncio << std::endl;

    imprimirPreco(carro);

    return 0;
}
