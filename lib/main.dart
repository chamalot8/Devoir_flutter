// Importation des bibliothèques nécessaires
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Définition d'une fonction pour récupérer les albums à partir d'une API distante
Future<List<Album>> fetchAlbums() async {
  // Effectuer une requête HTTP GET vers le point d'API spécifié
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

  // Vérifier si le code de statut de la réponse est 200 (OK)
  if (response.statusCode == 200) {
    // Analyser la réponse JSON en une liste d'objets dynamiques
    final List<dynamic> albumsJson = jsonDecode(response.body);

    // Mapper chaque objet dynamique vers un objet Album en utilisant le constructeur Album.fromJson
    return albumsJson
        .map((albumJson) => Album.fromJson(albumJson as Map<String, dynamic>))
        .toList();
  } else {
    // En cas d'échec, lancer une exception indiquant le problème
    throw Exception('Échec du chargement des albums');
  }
}

// Définition de la classe Album
class Album {
  final int userId;
  final int id;
  final String title;
  final String body;

  const Album({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  // Constructeur de fabrique pour créer un objet Album à partir d'un objet JSON
  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userId': int userId,
        'id': int id,
        'title': String title,
        'body': String body,
      } =>
        Album(
          userId: userId,
          id: id,
          title: title,
          body: body,
        ),
      _ => throw const FormatException('Échec du chargement de lalbum.'),
    };
  }
}

// Fonction principale d'exécution de l'application Flutter
void main() {
  // Lancer l'application en utilisant le widget MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Devoir flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  // Déclaration d'une variable future pour stocker les albums récupérés
  late Future<List<Album>> futureAlbums = fetchAlbums();

  void onAlbumTap(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailsPage(id: id),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
  }

  void refreshPage() {
    setState(() {
      futureAlbums = fetchAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Devoir Flutter'),
          actions: [
            IconButton(onPressed: refreshPage, icon: const Icon(Icons.refresh)),
          ],
        ),
        // Corps du widget Scaffold, centré avec un FutureBuilder pour gérer l'affichage asynchrone
        body: Center(
          child: FutureBuilder<List<Album>>(
            future: futureAlbums,
            builder: (context, snapshot) {
              // Si les données sont disponibles, afficher la liste de donnée
              if (snapshot.connectionState == ConnectionState.waiting) {
                return  const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              } else {
                // Afficher la liste des albums ici
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data![index].title),
                      onTap: () {
                        onAlbumTap(snapshot.data![index].id);
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormPost(onPostAdded: refreshPage),
                  )
                );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class AlbumDetailsPage extends StatelessWidget {
  final int id;

  const AlbumDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post numéro : $id')),
      body: Center(
        child: FutureBuilder<Album>(
          future: fetchAlbumById(id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0), // Utilisation de margin au lieu de padding
                    child: Text(
                      snapshot.data!.title,
                      style: const TextStyle(
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0), // Utilisation de margin au lieu de padding
                    child: Text(
                      snapshot.data!.body,
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  // La méthode fetchAlbumById() reste inchangée
  Future<Album> fetchAlbumById(int id) async {
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'));
    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load album');
    }
  }
}


class FormPost extends StatelessWidget {

  final VoidCallback onPostAdded;

  const FormPost({Key? key, required this.onPostAdded}) : super(key: key);

  Future<void> _submitForm(BuildContext context, String title, String body) async {
    print('Données envoyées au serveur : {\'title\': $title, \'body\': $body}'); // Ajout de cette ligne pour afficher les données envoyées
    final response = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      body: jsonEncode({'title': title, 'body': body}), // Hardcoded userId for example
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      print('Réponse du serveur : ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Le Post est ajouté"),
        backgroundColor: Colors.green,
      ));
      onPostAdded();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Le Post n'est pas envoyé"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController bodyController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un Post")),
      body: Center(
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du Post',
              ),
            ),
            TextFormField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Contenus du Post',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _submitForm(
                  context,
                  titleController.text,
                  bodyController.text,
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
