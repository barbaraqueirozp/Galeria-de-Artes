package controller;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;

public class HomeController implements Initializable {

    @FXML
    private TextField campoPesquisa;

    @FXML
    private Button botaoPreferencias;

    @FXML
    private Button botaoNotificao;

    @FXML
    private Button botaoPinturas;

    @FXML
    private Button botaoEsculturas;

    @FXML
    private HBox boxObrasDestaque;

    @FXML
    private HBox boxPerfisDestaque;

    @Override
    public void initialize(URL url, ResourceBundle resourceBundle) {
        System.out.println("Tela inicial carregada!");

        campoPesquisa.setPromptText(
            "Buscar artistas, obras ou estilos"
        );

        carregarDestaques();
        carregarArtistas();
    }

    @FXML
    private void pesquisar() {
        String pesquisa = campoPesquisa.getText().trim();

        if (pesquisa.isEmpty()) {
            System.out.println("Digite algo para pesquisar.");
            return;
        }

        System.out.println("Pesquisando por: " + pesquisa);

        // Depois este método consultará o banco de dados.
    }

    @FXML
    private void abrirFiltros() {
        System.out.println("Abrindo filtros...");
    }

    @FXML
    private void abrirNotificacoes() {
        System.out.println("Abrindo notificações...");
    }

    @FXML
    private void pesquisarPinturas() {
        campoPesquisa.setText("Pinturas");
        pesquisar();
    }

    @FXML
    private void pesquisarEsculturas() {
        campoPesquisa.setText("Esculturas");
        pesquisar();
    }

    @FXML
    private void verTodosDestaques() {
        System.out.println("Abrindo todas as obras...");
    }

    @FXML
    private void abrirMapa() {
        System.out.println("Abrindo mapa de artistas...");
    }

    private void carregarDestaques() {
        System.out.println("Carregando obras em destaque...");

        // Futuramente:
        // 1. Buscar obras aleatórias no banco.
        // 2. Criar um card para cada obra.
        // 3. Adicionar os cards no containerDestaques.
    }

    private void carregarArtistas() {
        System.out.println("Carregando artistas próximos...");

        // Futuramente:
        // 1. Buscar artistas no banco.
        // 2. Criar os cards dos artistas.
        // 3. Adicionar os cards no containerArtistas.
    }
}